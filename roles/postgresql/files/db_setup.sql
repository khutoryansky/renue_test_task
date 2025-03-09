-- db_setup.sql
-- ==================================================================
-- Этот скрипт настраивает PostgreSQL:
-- 1. Создаются базы данных: app, custom.
-- 2. Создаются пользователи: app, custom, service.
-- 3. Настраиваются права подключения к базам:
--    - В базе app: только пользователи app и service могут подключаться.
--    - В базе custom: только пользователи custom и service могут подключаться.
-- 4. В каждой базе создаётся отдельная схема (app_schema или custom_schema)
--    с отозванными правами для PUBLIC. Владелец схемы получает полный доступ,
--    а пользователю service выдаётся только USAGE и для будущих таблиц только SELECT.
-- ==================================================================

-- 1. Создание баз данных
CREATE DATABASE app;
CREATE DATABASE custom;

-- 2. Создание пользователей
CREATE USER app WITH PASSWORD 'app';
CREATE USER custom WITH PASSWORD 'custom';
CREATE USER service WITH PASSWORD 'service';

---------------------------------------------------------------------
-- 3. Настройка базы данных app
---------------------------------------------------------------------
\connect app

-- Ограничить возможность подключения: отозвать CONNECT у PUBLIC,
-- разрешить подключение только для app и service, запретить для custom.
REVOKE CONNECT ON DATABASE app FROM PUBLIC;
GRANT CONNECT ON DATABASE app TO app, service;
REVOKE CONNECT ON DATABASE app FROM custom;

-- Создание схемы app_schema с владельцем app
CREATE SCHEMA IF NOT EXISTS app_schema AUTHORIZATION app;

-- Отозвать все привилегии на схему app_schema для группы PUBLIC
REVOKE ALL ON SCHEMA app_schema FROM PUBLIC;

-- Выдать полный доступ владельцу схемы (app)
GRANT ALL ON SCHEMA app_schema TO app;

-- Выдать пользователю service право USAGE и SELECT на схему app_schema
GRANT USAGE ON SCHEMA app_schema TO service;
GRANT SELECT ON ALL TABLES IN SCHEMA app_schema TO service;

-- Настроить дефолтные привилегии для будущих таблиц в схеме app_schema:
ALTER DEFAULT PRIVILEGES IN SCHEMA app_schema REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA app_schema GRANT SELECT ON TABLES TO service;

---------------------------------------------------------------------
-- 4. Настройка базы данных custom
---------------------------------------------------------------------
\connect custom

-- Ограничить возможность подключения: отозвать CONNECT у PUBLIC,
-- разрешить подключение только для custom и service, запретить для app.
REVOKE CONNECT ON DATABASE custom FROM PUBLIC;
GRANT CONNECT ON DATABASE custom TO custom, service;
REVOKE CONNECT ON DATABASE custom FROM app;

-- Создание схемы custom_schema с владельцем custom
CREATE SCHEMA IF NOT EXISTS custom_schema AUTHORIZATION custom;

-- Отозвать все привилегии на схему custom_schema для группы PUBLIC
REVOKE ALL ON SCHEMA custom_schema FROM PUBLIC;

-- Выдать полный доступ владельцу схемы (custom)
GRANT ALL ON SCHEMA custom_schema TO custom;

-- Выдать пользователю service право USAGE и SELECT на схему custom_schema
GRANT USAGE ON SCHEMA custom_schema TO service;
GRANT SELECT ON ALL TABLES IN SCHEMA app_custom TO service;

-- Настроить дефолтные привилегии для будущих таблиц в схеме custom_schema:
ALTER DEFAULT PRIVILEGES IN SCHEMA custom_schema REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA custom_schema GRANT SELECT ON TABLES TO service;