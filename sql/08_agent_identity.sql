-- ============================================================================
-- M9-A — AGENT IDENTITY BASELINE
-- File: sql/08_agent_identity.sql
--
-- Objective:
-- Establish the non-agent control case before introducing SERVICE_AGENT.
--
-- Expected execution identity:
--   AGENT_SCOPE_TEST_USER
--   TYPE = SERVICE
--   IS_AGENT_ACTIVATED = FALSE
-- ============================================================================


-- ============================================================================
-- 1. CURRENT EXECUTION IDENTITY
-- ============================================================================

SELECT
    CURRENT_USER()            AS CURRENT_USER,
    CURRENT_ROLE()            AS CURRENT_ROLE,
    CURRENT_SECONDARY_ROLES() AS CURRENT_SECONDARY_ROLES,
    CURRENT_WAREHOUSE()       AS CURRENT_WAREHOUSE;


-- ============================================================================
-- 2. AGENT-ACTIVATION CONTROL TEST
-- ============================================================================

SELECT
    CURRENT_USER() AS CURRENT_USER,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    ) AS IS_AGENT_ACTIVATED_RAW,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    )::BOOLEAN AS IS_AGENT_ACTIVATED_BOOLEAN;


-- ============================================================================
-- 3. BOOLEAN ASSERTION
-- ============================================================================

SELECT
    CASE
        WHEN SYS_CONTEXT(
                 'SNOWFLAKE$CURRENT',
                 'IS_AGENT_ACTIVATED'
             )::BOOLEAN = FALSE
        THEN 'PASS - NORMAL SERVICE SESSION IS NOT AGENT ACTIVE'
        ELSE 'FAIL - SESSION IS UNEXPECTEDLY AGENT ACTIVE'
    END AS M9_BASELINE_TEST;