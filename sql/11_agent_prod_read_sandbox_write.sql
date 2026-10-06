-- ============================================================================
-- File: sql/11_agent_prod_read_sandbox_write.sql
-- Project: snowflake-governed-agent-scope-lighthouse
--
-- Milestone:
-- M12-A — Production-Read / Sandbox-Write Prerequisite Validation
--
-- Objective:
-- Revalidate the governance foundation required before exercising the
-- production-read / sandbox-write pattern through the governed Agent.
--
-- This script DOES NOT perform production writes.
-- It establishes evidence only.
-- ============================================================================


-- ============================================================================
-- 1. Administrative context
-- ============================================================================

USE ROLE ACCOUNTADMIN;

USE WAREHOUSE AGENT_SCOPE_WH;

USE DATABASE AGENT_SCOPE_LAB;


-- ============================================================================
-- 2. Verify production test object
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
ORDER BY RECORD_ID;


-- ============================================================================
-- 3. Verify sandbox test object
-- ============================================================================

SELECT *
FROM AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
ORDER BY 1;


-- ============================================================================
-- 4. Verify autonomous-role grants on production object
--
-- We specifically need evidence that UPDATE exists at RBAC level.
-- Otherwise a later production-write denial could simply be RBAC.
-- ============================================================================

SHOW GRANTS
ON TABLE AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST;


-- ============================================================================
-- 5. Verify autonomous-role grants on sandbox object
--
-- We need evidence that sandbox write capability exists at RBAC level.
-- ============================================================================

SHOW GRANTS
ON TABLE AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST;


-- ============================================================================
-- 6. Verify RSS still exists
-- ============================================================================

SHOW RESTRICTED SESSION POLICIES
LIKE 'BANKING_AGENT_RSS'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


-- ============================================================================
-- 7. Verify session policy still exists
-- ============================================================================

SHOW SESSION POLICIES
LIKE 'BANKING_AGENT_SESSION_POLICY'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


-- ============================================================================
-- 8. Verify SERVICE_AGENT identity
-- ============================================================================

SHOW USERS
LIKE 'AGENT_SCOPE_AUTONOMOUS_USER';


-- ============================================================================
-- M12-A completion criteria
--
-- Production object exists.
-- Sandbox object exists.
--
-- AGENT_SCOPE_AUTONOMOUS_ROLE retains:
--
--   Production:
--       SELECT
--       UPDATE
--
--   Sandbox:
--       SELECT
--       INSERT
--       UPDATE
--
-- BANKING_AGENT_RSS exists.
-- BANKING_AGENT_SESSION_POLICY exists.
-- AGENT_SCOPE_AUTONOMOUS_USER remains SERVICE_AGENT.
--
-- No M12 PASS is claimed from this script.
-- ============================================================================