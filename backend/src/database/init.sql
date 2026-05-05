-- MedCare CRM — PostgreSQL 15 ініціалізація
-- TypeORM synchronize=true автоматично створює таблиці при старті NestJS

-- Розширення для повнотекстового пошуку (pg_trgm) по діагнозах та іменах
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- UUID генерація (для PK)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Розширення для планувальника (pg_cron) для оновлення матеріалізованих вʼюх
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Коментар: після старту NestJS виконати TypeORM міграції:
-- npm run migration:run (всередині nestjs-api контейнера)
-- або seed: npm run seed
