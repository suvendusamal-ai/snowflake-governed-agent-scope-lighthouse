-- ============================================================================
-- File: tests/test_11_agent_aware_masking_service.sql
-- M11-B — Agent-Aware Masking / SERVICE Control
--
-- Objective:
-- Prove that an authorized non-Agent SERVICE execution:
--
--   1. has IS_AGENT_ACTIVATED = FALSE
--   2. can SELECT the protected view
--   3. receives the original EMAIL value
--
-- This establishes the control side of the M11 experiment.
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
-- 2. Protected data access
--
-- RBAC should authorize this query.
-- Because this is a normal SERVICE session rather than an Agent-active
-- session, EMAIL should remain unmasked.
-- ============================================================================

SELECT
    CUSTOMER_ID,
    EMAIL
FROM AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
ORDER BY CUSTOMER_ID;


-- ============================================================================
-- Expected evidence
--
-- IS_AGENT_ACTIVATED = FALSE
--
-- SELECT succeeds.
--
-- EMAIL contains original/raw values.
--
-- There must NOT be:
--
--   ***AGENT-MASKED***
--
-- and there must NOT be an RBAC authorization error.
-- ============================================================================