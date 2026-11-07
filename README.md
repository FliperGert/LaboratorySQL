# LaboratorySQL

**Цель:** написать функцию `next_val(tbl, col)`, которая возвращает следующее целое число для столбца. Текущие максимумы хранятся в специальной таблице `spec`.

**СУБД:** PostgreSQL
## Как работает функция

- Если запись для пары (таблица, столбец) есть в `spec`, значение увеличивается на 1.
- Если записи нет, берётся `max(столбец) + 1` (для пустой таблицы 1) и добавляется новая строка. Её `id` получается рекурсивным вызовом `next_val('spec', 'id')`.
- Функция возвращает актуальное значение.


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
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d370e401-fde0-484a-9978-e80a76f036b8" />


### Шаг 5. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 2)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/8ccf2060-bde5-45e6-9797-4e2bc4e5ad6e" />

### Шаг 6. Повторный вызов для ('spec', 'id')

```sql
SELECT next_val('spec', 'id');
```

Ожидаемый результат: **3**.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2e11e0cd-49c6-4fe4-b7c0-cb664de3105a" />

### Шаг 7. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 3)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/a6df4a1a-d7a9-4b7f-8b9b-1db2e4fc2839" />

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

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/a9ee8eae-61d7-4cb1-a1dd-fb95b1c2d8d7" />

### Шаг 11. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 4)`, `(4, test, id, 11)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/1bc08435-b90f-48b6-8b76-e46a6a7ea5e1" />


### Шаг 12. Повторный вызов для ('test', 'id')

```sql
SELECT next_val('test', 'id');
```

Ожидаемый результат: **12**.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/65be78cd-7739-4ec4-80e3-0afe7aa2e13e" />


### Шаг 13. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 4)`, `(4, test, id, 12)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bc76f4c5-bd21-4139-b96f-753d0cdf70db" />


### Шаг 14. Создание таблицы test2

```sql
CREATE TABLE test2 (num_value1 int, num_value2 int);
```

### Шаг 15. Вызов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1');
```

Ожидаемый результат: **1** (таблица пустая).
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b402b62a-aef6-4927-852e-0903f640d8bb" />

### Шаг 16. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 5)`, `(4, test, id, 12)`, `(5, test2, num_value1, 1)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d9be402e-1ce9-446c-baa9-7b003fa95d66" />

### Шаг 17. Повторный вызов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1');
```

Ожидаемый результат: **2**.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/26556d84-36e7-4ced-837e-4a624868f2d0" />


### Шаг 18. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 5)`, `(4, test, id, 12)`, `(5, test2, num_value1, 2)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/48e11889-a999-48eb-bac7-a82a17ced98c" />


### Шаг 19. Добавление записи (2, 13) в test2

```sql
INSERT INTO test2 (num_value1, num_value2) VALUES (2, 13);
```

### Шаг 20. Вызов для ('test2', 'num_value2')

```sql
SELECT next_val('test2', 'num_value2');
```

Ожидаемый результат: **14** (максимум 13, плюс 1).
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d6ab8fc8-67a4-433e-bd5c-b81fa2258539" />

### Шаг 21. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 6)`, `(4, test, id, 12)`, `(5, test2, num_value1, 2)`, `(6, test2, num_value2, 14)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/75d4aeb2-31b8-4eba-ba8b-66b5cc83ede5" />

### Шаг 22. Пять вызовов для ('test2', 'num_value1')

```sql
SELECT next_val('test2', 'num_value1') FROM generate_series(1, 5);
```

Ожидаемый результат: 3, 4, 5, 6, 7.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/9af4b565-cc2b-49cb-ba3c-cc599a9ca76b" />


### Шаг 23. Содержимое спец. таблицы

```sql
SELECT * FROM spec ORDER BY id;
```

Ожидаемый результат: `(1, spec, id, 6)`, `(4, test, id, 12)`, `(5, test2, num_value1, 7)`, `(6, test2, num_value2, 14)`.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/028da159-def3-473e-8dad-db2fe4d130a8" />


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
