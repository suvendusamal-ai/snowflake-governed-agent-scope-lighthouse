-- ============================================================================
-- M10-C — RSS PRODUCTION WRITE DENIAL
-- File: tests/test_09_rss_prod_write_denied.sql
--
-- Execute with:
--   CoCo_Agent_Autonomous
--
-- Objective:
-- Prove that production UPDATE is denied by RSS even though the underlying
-- RBAC role explicitly possesses UPDATE on DATA.RSS_PROD_TEST.
--
-- Expected:
--
--   RBAC UPDATE = YES
--   RSS DATA WRITE on DATA schema = NO
--   --------------------------------
--   Effective permission = DENY
-- ============================================================================


-- ============================================================================
-- 1. PROVE AGENT-ACTIVE EXECUTION CONTEXT
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
-- 2. VERIFY PRODUCTION ROW BEFORE UPDATE
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
WHERE RECORD_ID = 1;


-- ============================================================================
-- 3. ATTEMPT PRODUCTION UPDATE
--
-- RBAC explicitly grants UPDATE.
--
-- RSS allows DATA WRITE only in:
--   AGENT_SCOPE_LAB.SANDBOX
--
-- Therefore this statement MUST FAIL.
-- ============================================================================

UPDATE AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
SET
    RECORD_STATUS = 'UPDATED_BY_AGENT',
    UPDATED_BY_TEST = 'THIS_MUST_NOT_SUCCEED'
WHERE RECORD_ID = 1;