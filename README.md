# LaboratorySQL

**Цель:** написать функцию `next_val(tbl, col)`, которая возвращает следующее целое число для столбца. Текущие максимумы хранятся в специальной таблице `spec`.

**СУБД:** PostgreSQL, функция на `plpgsql`, без транзакций и переменных.

## Как работает функция

- Если запись для пары (таблица, столбец) есть в `spec`, значение увеличивается на 1.
- Если записи нет, берётся `max(столбец) + 1` (для пустой таблицы 1) и добавляется новая строка. Её `id` получается рекурсивным вызовом `next_val('spec', 'id')`.
- Функция возвращает актуальное значение.

## Ход работы

### Шаг 1. Создание спец. таблицы

```sql
CREATE TABLE spec (
    id          int PRIMARY KEY,
    table_name  VARCHAR(255) NOT NULL,
    column_name VARCHAR(255) NOT NULL,
    max_value   int          NOT NULL
);
```

### Шаг 2. Добавление записи (1, spec, id, 1)

```sql
INSERT INTO spec VALUES (1, 'spec', 'id', 1);
```

### Шаг 3. Создание ХП

```sql
CREATE FUNCTION next_val(tbl VARCHAR(255), col VARCHAR(255)) RETURNS int AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM spec WHERE table_name = tbl AND column_name = col) THEN
        UPDATE spec SET max_value = max_value + 1
         WHERE table_name = tbl AND column_name = col;
    ELSE
        EXECUTE format(
            'INSERT INTO spec
             SELECT next_val(''spec'', ''id''), %L, %L, COALESCE(max(%I), 0) + 1 FROM %I',
            tbl, col, col, tbl);
    END IF;

    RETURN (SELECT max_value FROM spec WHERE table_name = tbl AND column_name = col);
END;
$$ LANGUAGE plpgsql;
```

### Шаг 4. Вызов для ('spec', 'id')

```sql
SELECT next_val('spec', 'id');
```

Ожидаемый результат: **2**.

### Шаг 5. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 2)`.

### Шаг 6. Повторный вызов для ('spec', 'id')

```sql
SELECT next_val('spec', 'id');
```

Ожидаемый результат: **3**.

### Шаг 7. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 3)`.

### Шаг 8. Создание таблицы test

```sql
CREATE TABLE test (id int);
```

### Шаг 9. Добавление записи (10)

```sql
INSERT INTO test VALUES (10);
```

### Шаг 10. Вызов для ('test', 'id')

```sql
SELECT next_val('test', 'id');
```

Ожидаемый результат: **11**. Записи для `test.id` нет, поэтому находится максимум 10 и вставляется 11. Рекурсивный вызов увеличивает `spec.id` до 4, и это становится `id` новой строки.

### Шаг 11. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 4)`, `(4, test, id, 11)`.

### Шаг 12. Повторный вызов для ('test', 'id')

```sql
SELECT next_val('test', 'id');
```

Ожидаемый результат: **12**.

### Шаг 13. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 4)`, `(4, test, id, 12)`.

### Шаг 14. Создание таблицы test2

```sql
CREATE TABLE test2 (num_value1 int, num_value2 int);
```

### Шаг 15. Вызов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1');
```

Ожидаемый результат: **1** (таблица пустая).

### Шаг 16. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 5)`, `(4, test, id, 12)`, `(5, test2, num_value1, 1)`.

### Шаг 17. Повторный вызов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1');
```

Ожидаемый результат: **2**.

### Шаг 18. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 5)`, `(4, test, id, 12)`, `(5, test2, num_value1, 2)`.

### Шаг 19. Добавление записи (2, 13) в test2

```sql
INSERT INTO test2 (num_value1, num_value2) VALUES (2, 13);
```

### Шаг 20. Вызов для ('test2', 'num_value2')

```sql
SELECT next_val('test2', 'num_value2');
```

Ожидаемый результат: **14** (максимум 13, плюс 1).

### Шаг 21. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 6)`, `(4, test, id, 12)`, `(5, test2, num_value1, 2)`, `(6, test2, num_value2, 14)`.

### Шаг 22. Пять вызовов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1') FROM generate_series(1, 5);
```

Ожидаемый результат: 3, 4, 5, 6, 7.

### Шаг 23. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 6)`, `(4, test, id, 12)`, `(5, test2, num_value1, 7)`, `(6, test2, num_value2, 14)`.

### Шаг 24. Удаление ХП

```sql
DROP FUNCTION next_val(VARCHAR, VARCHAR);
```

### Шаг 25. Удаление таблиц

```sql
DROP TABLE test2;
DROP TABLE test;
DROP TABLE spec;
```

## Вывод

Функция `next_val` корректно возвращает следующее число для любого столбца: когда запись уже есть, когда её нет и когда таблица пуста. Идентификатор новой строки в `spec` формируется рекурсивным вызовом той же функции. Результаты всех шагов совпадают с ожидаемыми значениями из задания.
