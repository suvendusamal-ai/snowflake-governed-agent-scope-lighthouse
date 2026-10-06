-- ============================================================================
-- File: tests/test_12_agent_aware_masking_service_agent.sql
-- M11-C — Agent-Aware Masking / SERVICE_AGENT Treatment
--
-- Objective:
-- Prove that an authorized Agent-active SERVICE_AGENT execution:
--
--   1. has IS_AGENT_ACTIVATED = TRUE
--   2. can SELECT the same protected view
--   3. receives masked EMAIL values
--
-- RBAC must NOT be responsible for preventing access.
-- ============================================================================


-- ============================================================================
-- 1. Runtime identity/context
-- ============================================================================

SELECT
    CURRENT_USER() AS CURRENT_USER,
    CURRENT_ROLE() AS CURRENT_ROLE,
    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    )::BOOLEAN AS IS_AGENT_ACTIVATED;


-- ============================================================================
-- 2. Same protected data interface used by SERVICE control
-- ============================================================================

SELECT
    CUSTOMER_ID,
    EMAIL
FROM AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
ORDER BY CUSTOMER_ID;


-- ============================================================================
-- Expected evidence
--
-- IS_AGENT_ACTIVATED = TRUE
--
-- SELECT succeeds.
--
-- Every EMAIL value is:
--
--     ***AGENT-MASKED***
--
-- There must NOT be an RBAC authorization error.
-- ============================================================================