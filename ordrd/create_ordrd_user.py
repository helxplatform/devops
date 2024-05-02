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

def main():
    """
    Main function that parses command line arguments and outputs the generated SQL statements.

    The script expects a single argument, 'user', which is used to generate the SQL statements.
    """
    # Create an argument parser
    parser = argparse.ArgumentParser(description='Generate SQL for creating a user schema and permissions.')
    
    # Add argument for the user for which the SQL should be generated
    parser.add_argument('user', type=str, help='The user name for which to generate the SQL')
    
    # Parse the command line arguments
    args = parser.parse_args()
    
    # Generate the SQL statements using the provided user
    sql_output = generate_sql(args.user)
    
    # Print the generated SQL statements
    print(sql_output)

# Entry point of the script
if __name__ == "__main__":
    main()
