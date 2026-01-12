# Drupal за NGINX reverse‑proxy + Jenkins, Docker Registry и Ansible
Проект представляет собой учебную/демо‑инфраструктуру для Drupal, работающего за NGINX reverse‑proxy, с CI/CD на Jenkins, хранением образов в Docker Registry и управлением сервером через Ansible.
​
![Architecture Diagram](src/network-schemapng.png)
## Описание и цели
* Поднять Drupal за NGINX reverse‑proxy с терминацией HTTPS.

* Обеспечить сборку и версионирование Docker‑образов через Jenkins и Docker Registry.

* Реализовать деплой и базовое управление окружением с помощью Ansible (IaC‑подход).

* Продемонстрировать базовые сценарии CI/CD, тесты Drupal API и интеграцию с NGINX.
​
## Tech Stack.
### Задача реализована с помощью:

* Drupal — CMS система.

* MariaDB — База данных для Drupal.

* Nginx
    - Используется для двух целей:

        1. Внутренний сервер для Drupal
            - При запуске не доступен из сети напрямую.

        - Защищён BasicAuth, учётные данные хранятся в подпапке /auth/.httpasswd.

        2. Reverse‑proxy для обработки внешних подключений

        - Базовый HTTPS порт: :443.

    - Обрабатывает собственный root:

        * https://nginx.devops

            - /index.html

            - /static.html

            - /uploads/ → директория для публичных файлов
    - Перенаправляет трафик на Drupal:

        * https://nginx.devops/dp/

    - P.S При первой установке необходимо в docker-compose указать свободный порт для Drupal, чтобы продолжить установку, или с хоста подключиться по адресу контейнера: https://web.devops.
    После этого внутренний Drupal будет доступен в локации nginx /dp/.

### Docker Registry
Используется для контроля версий. При сборке в Jenkins создаётся уникальный номер версии, используемый в дальнейшем.
Защищён BasicAuth, учётные данные хранятся в подпапке /auth/.httpasswd.

### Jenkins
CI‑инструмент. Реализован Jenkinsfile, проверен на установленной версии в WSL.
​

Стадии Pipeline:
* Запуск bash‑скрипта, необходимого для дальнейшей работы проекта nginx+drupal.

* Авторизация в Docker‑Registry.

* Сборка образов для проекта nginx+drupal и загрузка обновлённых версий в Docker‑Registry под ID, равным hash, основанному на заголовке последнего commit в рабочий репозиторий.

* Деплой контейнеров nginx+drupal на машине, на которой был запущен pipeline.

* Тесты Drupal API и доступа к nginx.

* Пример работы Ansible‑скриптов, запущенных на удалённой машине.

### Ansible
IaC‑инструмент. Реализована библиотека из playbooks:

* P.S Добавление удалённого сервера для обработки Ansible выполняется с помощью папки inventories/.
Сюда добавляются дополнительные машины.

#### docker_install:

* Установка Docker и его зависимостей на удалённый сервер (docker.yml).

* Удаление Docker и зависимостей с удалённого сервера (docker_absent.yml).

#### drupal:

* Подъём Drupal на удалённом сервере (drupal.yml).

* Удаление поднятых контейнеров для Drupal и его зависимостей с удалённого сервера (drupal_absent.yml).

* Дополнительный инструмент для добавления/удаления прав на запись в файл settings.php по рекомендации Drupal при установке:

* До установки: playbook drupal_write.yml.

* После установки: playbook drupal_unwrite.yml.

#### User Management:
* Добавление пользователя в систему на удалённом сервере (users.yml).

* Удаление пользователя и его настроек/папок с удалённого сервера (users_absent.yml).

## Security & Secrets
- Все чувствительные данные исключены из репозитория
- Используются .env / Ansible variables
- certs, htpasswd, Jenkins home не хранятся в git

## Структура репозитория
```
├── Ansible
│   ├── inventories             -> хранилище машин для массового выполнения скриптов
│   │   └── server              -> Ubuntu TLS 24.0.3 ( Была использована для тестов )
│   ├── playbooks               -> сценарии автоматизации
│   └── roles                   -> Скрипты.
│       ├── docker_install      -> Установка + Удаление Docker
│       │   ├── defaults        -> стандартные настройки скрипта ( при параметризованном запуске )
│       │   ├── meta            -> информация о скрипте
│       │   └── tasks           -> скрипты
│       ├── drupal_deploy       -> Деплой и Удаление nginx && drupal+MariaDB контейнеров 
│       │   ├── defaults        -> стандартные настройки скрипта ( при параметризованном запуске )
│       │   ├── meta            -> информация о скрипте
│       │   ├── tasks           -> скрипты
│       │   └── templates       -> шаблон для параметризованной генерации docker-compose.yml
│       └── user_manage         -> Создание + Удаление пользователя
│           ├── defaults        -> стандартные настройки скрипта ( при параметризованном запуске )
│           ├── meta            -> информация о скрипте
│           └── tasks           -> скрипты
└── project                     -> директория проекта nginx as reverse proxy for drupal+MariaDB
    ├── Docker-Registry         -> конфигурации для Registry ( используется для контроля версий используемых образов )
    │   ├── auth                -> конфигурация для BasicAuth
    │   └── test-image          -> ToDo: удалить, использована для тестов.
    ├── Jenkins                 -> конфигурации для Jenkins
    │   └── auth                -> конфигурация для BasicAuth
    ├── containers              -> директория сборки проекта
    │   ├── drupal              -> конфигурация drupal
    │   │   └── files           -> ToDo: стереть
    │   │   └── settings.php    -> ToDo: перенести в папку /config; конфигурация drupal
    │   └── nginx               -> конфигурация Nginx 
    │       ├── certs           -> ToDo: убрать из репозитория для безопасности; хранилище сертификатов 
    │       ├── config          -> конфигурация nginx
    │       ├── root            -> корневая директория nginx.
    │       └── upload          -> ToDO: перенести в root. директория для публичных файлов.
    ├── docs                    -> ToDo: перенести в корень проекта. документация проекта
    └── scripts                 -> bash скрипты.
        └── download            -> ToDo: удалить, не часть проекта, побочный продукт скрипта. директория bash скрипта
```
## Запуск и использование (high‑level)
​
### Подготовить окружение:

* Установить Docker и Docker Compose на хост‑машине.

* Настроить DNS/hosts‑записи для доменов nginx.devops и web.devops.

* Запуск инфраструктуры локально:

* Перейти в папку containers/.

* Запустить docker-compose файл для nginx+drupal+db и, при необходимости, для Docker Registry.

### Настройка Jenkins:

* Запустить Jenkins (через Docker или natively).

* Создать pipeline и привязать его к Jenkinsfile из репозитория.

* Добавить креды для Docker Registry и, при необходимости, SSH/Ansible.

### Использование Ansible:

* Заполнить inventories/ информацией о целевых хостах.

* Выполнить соответствующие playbooks (docker.yml, drupal.yml, users.yml и т.д.) для подготовки и управления удалённым сервером.

## Требования
* Хост с установленными Docker и Docker Compose.

* Jenkins (проверено на wsl, но присутствует docker-compose file для использования проекта на виртуальной машине целиком).

* Доступ к Docker Registry (локальный или удалённый), настроенный BasicAuth.

* Установленный Ansible для управления удалёнными хостами.

## Обновления и Откат
* в Jenkinsfile предусмотрен контроль версий. При сборке - используется commit hash, добавляемый в тэг собранного образа.
для отката - изменить тэг образа в разделе Сборки на конкретный, желаемый для отката.

## Healthchecks
* Представлен healthcheck для nginx: curl https://nginx.devops/healthcheck -> 200 OK - с nginx всё в порядке.

## Частые ошибки
1. при запуске в первый раз, с клиента может быть недоступен https://nginx.devops/dp/
    * nginx будет проксировать с ошибкой 404.
    * Решение:
        - 1й вариант: с хост-машины перейти на домен drupal https://web.devops, завершить установку, после чего корент drupal /dp/ будет доступен через Nginx.
        - 2й вариант: вручную предоставить свободный внешний порт для подключения через него и настройку с клиента.
2. при установке drupal, installer.php может запретить установку по причине settings.php is not writable.
    * Решение: запустить Ansible playbook, предоставляющий права на запись. (drupal_write.yml)
3. при попытке перехода на https://nginx.devops не резолвится dns-name
   * Решение: добавить в hosts файле записи 
      - 127.0.0.1 nginx.devops
      - 127.0.0.1 web.devops
      - 127.0.0.1 database.devops ( пока не используется )
      - 127.0.0.1 jenkins.devops

## Quick-start (local)
```
0. add domain-names into hosts file on your system.
1. git clone
2. cd ./project/containers
3. cp .env.example .env
4. docker-compose up -d
5. open https://nginx.devops
```
Для запуска Pipeline необходимо запустить Docker-Registry из ./projects/Docker-Registry, а также указать credentials в самом Jenkins + Добавить credentials для доступа Jenkins к репозиторию.

## Observability
* На данный момент не предоставлены визуальные метрики.
* Логи доступны с помощью docker compose logs из корневой директории запущенного docker-compose.yml

## ToDo / дальнейшее развитие
* containers/drupal: добавить /config папку для лучшей читаемости.

* Расширить документацию по:
    - конкретным docker-compose файлам;

    - примерам запуска Ansible‑playbook’ов;

    - примерам API‑тестов Drupal и healthcheck’ов NGINX.
​
    - Prometheus | Graphana для визуальных метрик производительности
