#!/usr/bin/env bash
# arg1 := output.txt file | arg2 := link to the file 

set -euo pipefail
IFS=$'\n\t'

# <!-- TODO create logs.txt if not provided -->
LOG_FILE="logs.txt" 

# Функция для логирования простых сообщений с одним timestamp
log() {
    local msg="$1"
    {
        echo "$(date +'%Y-%m-%d %H:%M:%S') $msg"
        echo
    } >> "$LOG_FILE"
}

# Функция для логирования блоков с многострочным выводом
log_block() {
    local title="$1"
    shift
    {
        echo "$(date +'%Y-%m-%d %H:%M:%S') $title {"
        "$@"
        echo "}"
        echo
    } >> "$LOG_FILE"
}

if [[ $# -lt 2 ]]; then
  log "Ошибка: не переданы аргументы"
  exit 1
fi
log "Аргументы переданы корректно"

TASK_URL="https://www.litres.ru/gettrial/?art=49592199&format=txt&lfrom=159481197" 
OUTPUT_FILE="output.txt"
DOWNLOAD_DIR="download"
TEMP_ZIP_NAME="archieve.zip"

# Создание директории для загрузок, если не существует.
if [ -d "$DOWNLOAD_DIR" ]; then
    log "Папка $DOWNLOAD_DIR уже существует"
else
    mkdir -p "$DOWNLOAD_DIR"
    log "Папка $DOWNLOAD_DIR создана"
fi

# Загрузка файла с сервера
curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o "$DOWNLOAD_DIR/$TEMP_ZIP_NAME" "$TASK_URL"

# проверка на наличие архиватора в системе.
if ! command -v unzip &>/dev/null; then
  log "Не установлен unzip, для продолжения выполните 'sudo apt install -y unzip'"
  exit 1
else
  log "unzip обнаружен.."
fi

# распаковка файла
unzip -p -X -DD "$DOWNLOAD_DIR/archieve.zip" > "$DOWNLOAD_DIR/text.txt"
log "Файл извлечён и сохранён как text.txt."

# адаптация кодирвоки с литрес для парса текста из файла
iconv -f cp1251 -t utf-8 "$DOWNLOAD_DIR/text.txt" -o "$DOWNLOAD_DIR/text_utf8.txt"

# парс text.txt и составление статистики
# Берём топ-5 слов с количеством
mapfile -t TOP_WORDS_WITH_COUNT < <(
  grep -oP '[а-яА-Я]{6,}' "$DOWNLOAD_DIR/text_utf8.txt" | \
  awk '{print tolower($0)}' | \
  sort | uniq -c | sort -nr | head -n 5
)

log "TOP 5 Слов:"
# Получаем топ-1 слово + частоту
if (( ${#TOP_WORDS_WITH_COUNT[@]} > 0 )); then
    TOP_WORD="${TOP_WORDS_WITH_COUNT[0]}"
else
    TOP_WORD="Нет данных"
fi

# Генерируем HTML
cat > "../containers/nginx/root/static.html" <<EOF

<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>static.html</title>
</head>
<body>
    <h1><a href="/dp/">Перейти в Drupal</a></h1>
    <h1><a href="index.html">Перейти в index.html</a></h1>

    <h1>Самое популярное слово</h1>
    <p>$TOP_WORD</p>

    <h1>etc/os-release</h1>
    <pre>$(cat /etc/os-release)</pre>
</body>
</html>
EOF

cat > "../containers/nginx/root/index.html" <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>index.html</title>
</head>
<body>
    <h1><a href="static.html">Перейти в static.html</a></h1>
    <h1><a href="/dp/">Перейти в Drupal</a></h1>
    <h1>Информация о системе</h1>
    <pre>$(printenv)</pre>

</body>
</html>
EOF

USED_WORD_FLAG=false # переменная для проверки наличия слова "говорил"

test_word="говорил"
for word in "${TOP_WORDS[@]}"; do
# - Если слово «князь» присутствует в списке:
  if [[ "$word" == "сказал"  ]]; then
    # - Сделать запрос `curl` к ya.ru 
    # и вывести в формате JSON всю статистику curl по этому запросу (`-w`)
    log_block "CURL к ya.ru для слова $word" curl -s -o /dev/null -w '{
    "http_code": "%{http_code}",
    "time_total": "%{time_total}",
    "time_namelookup": "%{time_namelookup}",
    "time_connect": "%{time_connect}",
    "time_starttransfer": "%{time_starttransfer}"
    }' "https://ya.ru/search/?text=$word"

  elif [[ "$word" == "$test_word"  ]]; then 
    # Проверка для флага наличия указанного слова в ТОП-5.
    USED_WORD_FLAG=true
  fi 
done

#  - Если слова «говорил» нет в списке:
if ! $USED_WORD_FLAG; then
  log "слово <<$test_word>> не обнаружено"
  {
  log_block "CURL к google.coom" curl -s -o /dev/null -w '{
"http_code": "%{http_code}",
"time_total": "%{time_total}",
"time_namelookup": "%{time_namelookup}",
"time_connect": "%{time_connect}",
"time_starttransfer": "%{time_starttransfer}"
}' "https://google.coom/search/?text=$test_word"
  } || log "Не удалось выполнить curl к google.coom. Выполнение скрипта продолжается." 
fi



# - В качестве второго аргумента передать URL файла, 
# который нужно скачать в подпапку `download` 

SOURCE_URL=$1 # Первый аргумент: ссылка на сайт.
FILE_PATH=$2 # Второй аргумент: URL файла на сайте.

# Загрузка файла с сайта
TARGET_FILE="$DOWNLOAD_DIR/$(basename "$FILE_PATH")"
echo $TARGET_FILE
HTTP_STATUS=$(curl -w "%{http_code}" -k -s -o "$TARGET_FILE" "$SOURCE_URL/$FILE_PATH" || true)

# вывод инфы о файле. 
if [[ "$HTTP_STATUS" -ne 200 ]]; then
    log "Не удалось скачать файл по адресу $SOURCE_URL/$TARGET_FILE, сервер вернул HTTP $HTTP_STATUS"
    rm -f "$TARGET_FILE"   # удалить пустой/ошибочный файл
else
    log "Файл $TARGET_FILE успешно скачан"
    FILE_STATS=$(ls -lh "$TARGET_FILE")
    FULL_PATH=$(realpath "$TARGET_FILE")
    log "Статистика файла: $FILE_STATS"
    log "Полный путь: $FULL_PATH"
fi
