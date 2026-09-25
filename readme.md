# Nyx — self-hosted

## Требования

- Linux `x86_64`, Docker с Compose 2.23.1+, Bash и OpenSSL.
- Сервер с публичным IP и домен.
- Минимальные характеристики сервера: 2 ядра CPU, 2 ГБ оперативной памяти и 5 ГБ диска.
- DNS A-записи для основного домена и поддоменов `admin`, `cdn`, `livekit`, `s3`, `minio`, указывающие на сервер.
- Открытые TCP-порты `80`, `443`, `7881` и UDP-порты `443`, `3478`, `50000–50100`.

HTTPS-сертификаты выпускает Caddy автоматически. DNS должен указывать на сервер до запуска.

## Установка

Склонируйте этот репозиторий. Все команды выполняются из каталога с `docker-compose.yml` и `configure.sh`, с доступом к Docker.

Сгенерируйте настройки:

```sh
bash configure.sh
```

Введите домен без протокола, порта и пути, например `example.com`. Скрипт создаст `.env` с паролями и секретами, права — `600`. Существующий `.env` не перезаписывается.

При необходимости измените настройки в `.env` и версии образов в `docker-compose.yml`.

Примените миграции: команда автоматически запускает PostgreSQL и ждёт его готовности. После успешного завершения запустите остальные сервисы:

```sh
docker compose --profile maintenance run --rm migrate
docker compose up -d
docker compose ps
```

Переходите к запуску только после успешных миграций; `no change` не является ошибкой. Бакеты MinIO создаются при запуске сервисов.

## Доступ

Замените `example.com` своим доменом.

| Сервис | Адрес | Учётные данные |
| --- | --- | --- |
| Админка | `https://admin.example.com` | `admin` / `ADMIN_PASSWORD` из `.env` |
| Web-клиент | `https://example.com/app/` | Пользователь, созданный в админке |
| MinIO | `https://minio.example.com` | `nyx-storage` / `S3_SECRET_KEY` из `.env` |

В админке создайте пользователя в разделе «Пользователи».

Windows-клиент: скачайте установщик из [GitHub Releases](https://github.com/ms-dosx86/nyx/releases) и укажите адрес сервера `https://example.com`.

## Обновления Windows-клиента

В автоматически созданный бакет `5231b33b-nyx-desktop-app-dev` загрузите файлы одного Stable-релиза из GitHub Releases: сначала `.exe` и `.blockmap`, затем `latest.yml`. Файлы размещаются в корне бакета.

## Обновление сервера

Перед обновлением желательно сделать резервную копию базы данных PostgreSQL. Обновите версии образов в `docker-compose.yml`, затем выполните команды по очереди:

```sh
docker compose pull
docker compose down
docker compose --profile maintenance run --rm migrate
docker compose up -d
```

При ошибке миграций не переходите к запуску. Сохраните прежние пароли БД и MinIO в `.env`.
