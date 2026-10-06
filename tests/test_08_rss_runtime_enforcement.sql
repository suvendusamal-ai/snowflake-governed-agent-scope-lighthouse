-- ============================================================================
-- M10-B — RSS RUNTIME ENFORCEMENT
-- File: tests/test_08_rss_runtime_enforcement.sql
--
-- Execute with:
--   CoCo_Agent_Autonomous
--
-- Objective:
-- Prove that:
--
--   Effective Agent Permission = RBAC ∩ RSS
--
-- RBAC permits:
--   SELECT DATA.RSS_PROD_TEST
--   UPDATE DATA.RSS_PROD_TEST
--   SELECT/INSERT/UPDATE SANDBOX.RSS_SANDBOX_TEST
--
-- RSS permits:
--   DATA READ account-wide
--   DATA WRITE only in AGENT_SCOPE_LAB.SANDBOX
--
-- Therefore:
--   Production SELECT  -> expected SUCCESS
--   Sandbox UPDATE     -> expected SUCCESS
--
-- Production UPDATE denial will be tested separately after these
-- positive controls so an expected SQL error cannot obscure them.
-- ============================================================================


-- ============================================================================
-- 1. SESSION / AGENT IDENTITY
-- ============================================================================

SELECT
    CURRENT_USER() AS CURRENT_USER,
    CURRENT_ROLE() AS CURRENT_ROLE,
    CURRENT_SECONDARY_ROLES() AS CURRENT_SECONDARY_ROLES,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    )::BOOLEAN AS IS_AGENT_ACTIVATED,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'AGENT_TYPE'
    ) AS AGENT_TYPE;


-- ============================================================================
-- 2. PRODUCTION READ
--
-- RBAC = YES
-- RSS  = YES
-- Expected effective result = SUCCESS
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
WHERE RECORD_ID = 1;


-- ============================================================================
-- 3. SANDBOX READ — BASELINE
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
WHERE RECORD_ID = 1;


-- ============================================================================
-- 4. SANDBOX UPDATE
--
-- RBAC = YES
-- RSS  = YES
-- Expected effective result = SUCCESS
-- ============================================================================

UPDATE AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
SET
    RECORD_STATUS = 'UPDATED_BY_AGENT',
    UPDATED_BY_TEST = 'RSS_ALLOWED'
WHERE RECORD_ID = 1;


-- ============================================================================
-- 5. VERIFY SANDBOX WRITE
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
WHERE RECORD_ID = 1;


-- ============================================================================
-- 6. POSITIVE CONTROL ASSERTION
-- ============================================================================

SELECT
    CASE
        WHEN RECORD_STATUS = 'UPDATED_BY_AGENT'
         AND UPDATED_BY_TEST = 'RSS_ALLOWED'
        THEN 'PASS - SANDBOX WRITE ALLOWED BY RBAC AND RSS'
        ELSE 'FAIL - SANDBOX WRITE DID NOT PRODUCE EXPECTED RESULT'
    END AS M10_SANDBOX_WRITE_TEST
FROM AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
WHERE RECORD_ID = 1;