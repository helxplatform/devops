-- omop_load COPY statement generator
-- Produces one COPY statement per table in schema omop_load.
-- FORCE_NULL is included only for columns that are nullable; if a table has no nullable columns,
-- the FORCE_NULL clause is omitted.
--
-- Usage (psql example):
--   psql -d <db> -f omop_load_copy_generator.sql -At > omop_load_copy_commands.sql
-- Or interactively:
--   \o omop_load_copy_commands.sql
--   \pset tuples_only on
--   \pset format unaligned
--   <run the query below>
--   \o

WITH tables AS (
  SELECT table_schema, table_name
  FROM information_schema.tables
  WHERE table_schema = 'omop_load'
    AND table_type = 'BASE TABLE'
),
nullable_cols AS (
  SELECT
    table_schema,
    table_name,
    string_agg(format('%I', column_name), ', ' ORDER BY ordinal_position) AS col_list
  FROM information_schema.columns
  WHERE table_schema = 'omop_load'
    AND is_nullable = 'YES'
  GROUP BY table_schema, table_name
)
SELECT
  format(
$SQL$
COPY %I.%I
FROM %L
WITH (
  FORMAT csv,
  HEADER true%s
);
$SQL$,
    t.table_schema,
    t.table_name,
    '/pgdata/pg15/tmp_refresh/' || t.table_name || '.csv',
    CASE
      WHEN n.col_list IS NULL THEN ''
      ELSE format(',\n  FORCE_NULL (%s)', n.col_list)
    END
  ) AS copy_sql
FROM tables t
LEFT JOIN nullable_cols n USING (table_schema, table_name)
ORDER BY t.table_name;
