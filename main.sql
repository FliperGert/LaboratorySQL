CREATE TABLE spec (
    id          int PRIMARY KEY,
    table_name  VARCHAR(255) NOT NULL,
    column_name VARCHAR(255) NOT NULL,
    max_value   int          NOT NULL
);

INSERT INTO spec VALUES (1, 'spec', 'id', 1);

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

SELECT next_val('spec', 'id');
SELECT * FROM spec ORDER BY id;

SELECT next_val('spec', 'id');
SELECT * FROM spec ORDER BY id;

CREATE TABLE test (id int);
INSERT INTO test VALUES (10);

SELECT next_val('test', 'id');
SELECT * FROM spec ORDER BY id;

SELECT next_val('test', 'id');
SELECT * FROM spec ORDER BY id;

CREATE TABLE test2 (num_value1 int, num_value2 int);

SELECT next_val('test2', 'num_value1');
SELECT * FROM spec ORDER BY id;

SELECT next_val('test2', 'num_value1');
SELECT * FROM spec ORDER BY id;

INSERT INTO test2 (num_value1, num_value2) VALUES (2, 13);

SELECT next_val('test2', 'num_value2');
SELECT * FROM spec ORDER BY id;

SELECT next_val('test2', 'num_value1') FROM generate_series(1, 5);
SELECT * FROM spec ORDER BY id;

DROP FUNCTION next_val(VARCHAR, VARCHAR);

DROP TABLE test2;
DROP TABLE test;
DROP TABLE spec;