-- ============================================================================
-- M10-A — RESTRICTED SESSION SCOPE
-- File: sql/09_restricted_session_scope.sql
--
-- Objective:
-- Establish an admin-managed privilege ceiling for autonomous agent sessions.
--
-- Governance target:
--
--   Effective Agent Permission
--       =
--   User RBAC Privileges
--       INTERSECT
--   Restricted Session Scope
--
-- Scope design:
--   1. Data read        -> account-wide, subject to RBAC
--   2. Program usage    -> account-wide, subject to RBAC
--   3. Data write       -> AGENT_SCOPE_LAB.SANDBOX only
--   4. Privileged roles -> blocked
--   5. Role switching   -> disabled
--
-- IMPORTANT:
-- RSS does NOT grant privileges.
-- It only limits privileges already granted through RBAC.
-- ============================================================================


-- ============================================================================
-- 1. ADMINISTRATIVE CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA GOVERNANCE;
USE WAREHOUSE AGENT_SCOPE_WH;


-- ============================================================================
-- 2. CREATE / UPDATE RESTRICTED SESSION SCOPE
-- ============================================================================

CREATE OR ALTER RESTRICTED SESSION SCOPE
    AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_RSS
COMMENT =
    'Agent privilege ceiling: read governed data, write only to sandbox, block privileged roles'
AS
$$
privilege_scopes:
  allowed_privileges:

    - privileges: [data read, program usage]
      account: [all]

    - privileges: [data write]
      schemas:
        - AGENT_SCOPE_LAB.SANDBOX

role_scopes:
  blocked_roles:
    - ACCOUNTADMIN
    - SECURITYADMIN
    - SYSADMIN

  allow_role_switching: false
$$;


-- ============================================================================
-- 3. VERIFY RSS OBJECT
-- ============================================================================

SHOW RESTRICTED SESSION SCOPES
LIKE 'BANKING_AGENT_RSS'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


DESCRIBE RESTRICTED SESSION SCOPE
    AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_RSS;


-- ============================================================================
-- 4. CREATE ADMIN-MANAGED SESSION POLICY
-- ============================================================================

CREATE OR REPLACE SESSION POLICY
    AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_SESSION_POLICY

    AGENT_RESTRICTED_SESSION_SCOPE =
        'AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_RSS'

    COMMENT =
        'Applies BANKING_AGENT_RSS whenever the covered user is agent-active';


-- ============================================================================
-- 5. VERIFY SESSION POLICY
-- ============================================================================

SHOW SESSION POLICIES
LIKE 'BANKING_AGENT_SESSION_POLICY'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


DESCRIBE SESSION POLICY
    AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_SESSION_POLICY;


-- ============================================================================
-- 6. ATTACH POLICY TO AUTONOMOUS AGENT IDENTITY
--
-- Deliberately attach only to the autonomous test user.
-- Do NOT alter the account-level session policy.
-- Do NOT alter AGENT_SCOPE_TEST_USER.
-- ============================================================================

ALTER USER AGENT_SCOPE_AUTONOMOUS_USER
SET SESSION POLICY
    AGENT_SCOPE_LAB.GOVERNANCE.BANKING_AGENT_SESSION_POLICY;


-- ============================================================================
-- 7. VERIFY USER
-- ============================================================================

SHOW USERS
LIKE 'AGENT_SCOPE_AUTONOMOUS_USER';