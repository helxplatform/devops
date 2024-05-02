#!/usr/bin/env python

import argparse

def generate_sql(user):
    """
    Generates SQL statements to create a role and schema for the specified user,
    and grants the necessary permissions.

    Args:
        user (str): The username for which the SQL statements will be generated.

    Returns:
        str: A string containing the generated SQL statements.
    """
    sql_statements = f"""
CREATE ROLE {user}_owner;
CREATE SCHEMA {user} AUTHORIZATION {user}_owner;
GRANT {user}_owner TO {user};
GRANT {user}_owner TO ordrd_admin;
"""
    return sql_statements

def write_sql_to_file(user, sql_statements):
    """
    Writes the generated SQL statements to a file.

    Args:
        user (str): The username which will be part of the filename.
        sql_statements (str): The SQL statements to write to the file.
    """
    filename = f"create_{user}_schema.sql"
    with open(filename, 'w') as file:
        file.write(sql_statements)
    print(f"SQL script written to {filename}")

def main():
    """
    Main function that parses command line arguments, generates the SQL statements,
    and writes them to a file named create_<user>_schema.sql.

    The script expects a single argument, 'user', which is used to generate the SQL statements.
    """
    parser = argparse.ArgumentParser(description='Generate SQL for creating a user schema and permissions.')
    parser.add_argument('user', type=str, help='The user name for which to generate the SQL')
    
    args = parser.parse_args()
    
    sql_output = generate_sql(args.user)
    write_sql_to_file(args.user, sql_output)

if __name__ == "__main__":
    main()
