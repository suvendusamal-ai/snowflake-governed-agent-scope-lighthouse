-- ============================================================================
-- M10-E — RSS ROLE ESCAPE DENIAL
-- File: tests/test_10_rss_role_switch_denied.sql
--
-- Execute using:
--   CoCo_Agent_Autonomous
--
-- Objective:
-- Prove an agent-active session cannot escape its privilege ceiling by
-- switching roles.
--
-- BANKING_AGENT_RSS:
--   blocked_roles:
--     - ACCOUNTADMIN
--     - SECURITYADMIN
--     - SYSADMIN
--
--   allow_role_switching: false
-- ============================================================================


-- ============================================================================
-- 1. PROVE AGENT CONTEXT
-- ============================================================================

SELECT
    CURRENT_USER() AS CURRENT_USER,
    CURRENT_ROLE() AS CURRENT_ROLE,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    )::BOOLEAN AS IS_AGENT_ACTIVATED,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'AGENT_TYPE'
    ) AS AGENT_TYPE;


-- ============================================================================
-- 2. ATTEMPT ROLE ESCAPE
--
-- Expected: DENIED
-- ============================================================================

USE ROLE ACCOUNTADMIN;