# Infographic App Server

Серверная часть веб-приложения для генерации инфографики по учебной статистике.

## Назначение

Сервер обеспечивает обработку запросов клиентского приложения, авторизацию, разграничение доступа, выполнение бизнес-логики, работу с PostgreSQL и передачу данных для визуализации.

## Используемые технологии

- Dart;
- shelf;
- shelf_router;
- PostgreSQL;
- postgres package;
- JWT;
- dotenv;
- bcrypt-хэширование через `pgcrypto` на уровне PostgreSQL.

## Структура сервера

```text
server/
├── bin/
│   └── server.dart              # Точка входа
├── lib/src/
│   ├── config/                  # Конфигурация окружения
│   ├── db/                      # Подключение к базе данных
│   ├── handlers/                # Обработчики API-запросов
│   ├── middleware/              # JWT и role middleware
│   ├── models/                  # Модели данных
│   ├── router/                  # Маршрутизация
│   └── utils/                   # Общие утилиты
├── test/                        # Тесты
├── .env.example                 # Пример настроек окружения
└── pubspec.yaml
```

## Настройка окружения

Создайте файл `.env` в папке `server` на основе `.env.example`:

```bash
copy .env.example .env
```

Для PowerShell:

```powershell
Copy-Item .env.example .env
```

Пример содержимого `.env`:

```env
SERVER_HOST=localhost
SERVER_PORT=8080

DB_HOST=localhost
DB_PORT=5432
DB_NAME=InfographicAppDB
DB_USER=postgres
DB_PASSWORD=your_password

JWT_SECRET=change_me_to_long_random_secret
JWT_EXPIRES_HOURS=24

BACKUP_DIRECTORY=backups
PG_DUMP_PATH=pg_dump
PSQL_PATH=psql
```

## Переменные окружения

| Переменная | Назначение |
|---|---|
| `SERVER_HOST` | Хост запуска сервера |
| `SERVER_PORT` | Порт запуска сервера |
| `DB_HOST` | Хост PostgreSQL |
| `DB_PORT` | Порт PostgreSQL |
| `DB_NAME` | Имя базы данных |
| `DB_USER` | Пользователь PostgreSQL |
| `DB_PASSWORD` | Пароль пользователя PostgreSQL |
| `JWT_SECRET` | Секрет для подписи JWT |
| `JWT_EXPIRES_HOURS` | Время жизни токена в часах |
| `BACKUP_DIRECTORY` | Папка для резервных копий |
| `PG_DUMP_PATH` | Путь к `pg_dump` |
| `PSQL_PATH` | Путь к `psql` |

## Запуск сервера

```bash
dart pub get
dart run bin/server.dart
```

После запуска сервер доступен по адресу:

```text
http://localhost:8080
```

## Основные API-разделы

| Раздел | Назначение |
|---|---|
| `/api/auth` | Авторизация, регистрация, профиль, смена пароля |
| `/api/educational-data` | Учебные группы, студенты, дисциплины, периоды, оценки, посещаемость |
| `/api/statistics` | Получение статистических показателей |
| `/api/infographics` | Шаблоны, сохранение и получение инфографик |
| `/api/import` | Импорт CSV-данных |
| `/api/admin` | Администрирование, пользователи, аудит, шаблоны, backup/restore |

## Проверка сервера

```bash
dart analyze
dart test
```

## Резервное копирование

Администратор может создать резервную копию через интерфейс приложения. Сервер использует `pg_dump`.

Если `pg_dump` не находится автоматически, укажите полный путь в `.env`:

```env
PG_DUMP_PATH=C:\Program Files\PostgreSQL\17\bin\pg_dump.exe
```

## Восстановление базы данных

Восстановление выполняется через `psql`. Для корректной работы укажите путь:

```env
PSQL_PATH=C:\Program Files\PostgreSQL\17\bin\psql.exe
```

Перед восстановлением рекомендуется создать новую резервную копию текущего состояния базы.

## Безопасность

- Пароли не хранятся в открытом виде.
- Для авторизации используется JWT.
- Доступ к административным маршрутам ограничен ролью администратора.
- Заблокированный пользователь не может выполнять операции.
- Изменения важных таблиц фиксируются в журнале аудита.
- Настоящий `.env` не должен попадать в Git.
