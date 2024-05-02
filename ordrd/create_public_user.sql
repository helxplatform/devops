-- Create the parent role
CREATE ROLE omop_public_user;

-- Grant privileges to the parent role
GRANT USAGE, CREATE ON SCHEMA public TO omop_public_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO omop_public_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO omop_public_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO omop_public_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO omop_public_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO omop_public_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO omop_public_user;

-- This would be applied: GRANT omop_public_user TO child_role;
