-- ============================================================================
-- M9-B — SERVICE_AGENT IDENTITY SETUP
-- File: tests/setup_01_service_agent_identity.sql
--
-- Objective:
-- Create an autonomous AI identity whose Snowflake sessions are
-- automatically recognized as agent-active.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. CREATE AUTONOMOUS AGENT ROLE
-- ============================================================================

CREATE ROLE IF NOT EXISTS AGENT_SCOPE_AUTONOMOUS_ROLE
    COMMENT = 'Autonomous SERVICE_AGENT role for Agent Scope Lighthouse';


-- Minimal environment privileges for identity testing.

GRANT USAGE ON WAREHOUSE AGENT_SCOPE_WH
    TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;

GRANT USAGE ON DATABASE AGENT_SCOPE_LAB
    TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;

GRANT USAGE ON SCHEMA AGENT_SCOPE_LAB.AGENTS
    TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


-- ============================================================================
-- 2. CREATE SERVICE_AGENT IDENTITY
--
-- Replace <PUBLIC_KEY_BODY> with the public key generated locally.
-- Do NOT paste the private key.
-- ============================================================================

CREATE OR REPLACE USER AGENT_SCOPE_AUTONOMOUS_USER
    TYPE = SERVICE_AGENT
    DEFAULT_ROLE = AGENT_SCOPE_AUTONOMOUS_ROLE
    DEFAULT_WAREHOUSE = AGENT_SCOPE_WH
    DEFAULT_NAMESPACE = 'AGENT_SCOPE_LAB.AGENTS'
    DEFAULT_SECONDARY_ROLES = ()
    RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzO1lYVBlWpoTJXV/ZdjhWTY0Is+mpb2pw5+n6yEEcJ05Y0ofooRfN4SuADZz78wkecd6cM2ct7krvub51EXp2RiYQ62gxrqZ5kKzs5kouebYLeXs70p0TAhQRSIfV8zXds53TzOSTYPFD2yK0fzygE2QOzJq8Taswv1JTbQemQndtrL772FBKiSKzEH7IDooCR00wERCi2O7hzTq+1lQnmO/wajJ9R1j7J7k8fx/ZSff0JOBS+LrVnPOyRyJbZJY759qMGo+4J1DLve20uccyWR6EPoZk0U5sPLtojQ3pN3HPCAn9M7j8xSO+SJEBteHnk5SFR62FC5Qd/Cs0+JBzQIDAQAB'
    COMMENT = 'Autonomous SERVICE_AGENT identity for Agent Scope Lighthouse';


-- ============================================================================
-- 3. GRANT ROLE
-- ============================================================================

GRANT ROLE AGENT_SCOPE_AUTONOMOUS_ROLE
    TO USER AGENT_SCOPE_AUTONOMOUS_USER;


-- ============================================================================
-- 4. VERIFY IDENTITY METADATA
-- ============================================================================

SHOW USERS
LIKE 'AGENT_SCOPE_AUTONOMOUS_USER';