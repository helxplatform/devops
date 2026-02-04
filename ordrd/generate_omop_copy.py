#!/usr/bin/env python3
"""
Generate plain-text PostgreSQL COPY statements for every table in schema `omop_load`.

This script connects to Postgres, runs a generator query, and outputs *only* the COPY statements
(no psql headers/footers/ASCII tables).

Requirements:
- Python 3.8+
- One of: psycopg (v3) OR psycopg2
- Connection info via PG env vars (recommended):
    PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
  Or pass a libpq connection string via --dsn.

Examples:
  export PGHOST=localhost PGPORT=5432 PGDATABASE=mydb PGUSER=myuser PGPASSWORD=secret
  python3 generate_omop_copy.py > omop_load_copy_commands.sql

  python3 generate_omop_copy.py --dsn "host=localhost port=5432 dbname=mydb user=myuser password=secret" \
    --out omop_load_copy_commands.sql
"""
import argparse
import sys

GENERATOR_SQL = r"""
WITH tables AS (
  SELECT table_schema, table_name
  FROM information_schema.tables
  WHERE table_schema = %s
    AND table_type = 'BASE TABLE'
),
nullable_cols AS (
  SELECT
    table_schema,
    table_name,
    string_agg(format('%I', column_name), ', ' ORDER BY ordinal_position) AS col_list
  FROM information_schema.columns
  WHERE table_schema = %s
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
    %s || '/' || t.table_name || '.csv',
    CASE
      WHEN n.col_list IS NULL THEN ''
      ELSE format(',\n  FORCE_NULL (%s)', n.col_list)
    END
  ) AS copy_sql
FROM tables t
LEFT JOIN nullable_cols n USING (table_schema, table_name)
ORDER BY t.table_name;
"""

def get_connection(dsn):
    # Try psycopg (v3) first, then psycopg2.
    try:
        import psycopg  # type: ignore
        return psycopg.connect(dsn or "")
    except Exception as e_psycopg:
        try:
            import psycopg2  # type: ignore
            return psycopg2.connect(dsn or "")
        except Exception as e_psycopg2:
            raise RuntimeError(
                "Could not import/connect with psycopg (v3) or psycopg2.\n"
                f"psycopg error: {e_psycopg}\n"
                f"psycopg2 error: {e_psycopg2}\n"
                "Install one:\n"
                "  pip install psycopg[binary]\n"
                "or\n"
                "  pip install psycopg2-binary\n"
            )

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dsn", default=None, help="libpq connection string. If omitted, uses PG* env vars.")
    p.add_argument("--schema", default="omop_load", help="Schema to iterate (default: omop_load)")
    p.add_argument("--dir", default="/pgdata/pg15/tmp_refresh", help="Server-side CSV dir (default: /pgdata/pg15/tmp_refresh)")
    p.add_argument("--out", default="-", help="Output file, or '-' for stdout (default: -)")
    args = p.parse_args()

    conn = get_connection(args.dsn)
    try:
        cur = conn.cursor()
        cur.execute(GENERATOR_SQL, (args.schema, args.schema, args.dir))
        rows = cur.fetchall()

        # rows are one-column tuples containing the generated statement text
        text = "\n".join(r[0].rstrip() for r in rows).rstrip() + "\n"

        if args.out == "-" or args.out == "":
            sys.stdout.write(text)
        else:
            with open(args.out, "w", encoding="utf-8") as f:
                f.write(text)
            print(f"Wrote {len(rows)} COPY statements to {args.out}", file=sys.stderr)
    finally:
        try:
            conn.close()
        except Exception:
            pass

if __name__ == "__main__":
    main()
