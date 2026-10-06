-- ============================================================================
-- M9-C — SERVICE_AGENT RUNTIME IDENTITY TEST
-- File: tests/test_07_service_agent_identity.sql
--
-- Objective:
-- Prove that a session opened by a SERVICE_AGENT identity is automatically
-- recognized by Snowflake as agent-active.
-- ============================================================================


-- ============================================================================
-- 1. SESSION IDENTITY
-- ============================================================================

SELECT
    CURRENT_USER()            AS CURRENT_USER,
    CURRENT_ROLE()            AS CURRENT_ROLE,
    CURRENT_SECONDARY_ROLES() AS CURRENT_SECONDARY_ROLES,
    CURRENT_WAREHOUSE()       AS CURRENT_WAREHOUSE,
    CURRENT_DATABASE()        AS CURRENT_DATABASE,
    CURRENT_SCHEMA()          AS CURRENT_SCHEMA;


-- ============================================================================
-- 2. AGENT EXECUTION CONTEXT
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
    )::BOOLEAN AS IS_AGENT_ACTIVATED_BOOLEAN,

    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'AGENT_TYPE'
    ) AS AGENT_TYPE;


-- ============================================================================
-- 3. DETERMINISTIC ASSERTION
-- ============================================================================

SELECT
    CASE
        WHEN SYS_CONTEXT(
                 'SNOWFLAKE$CURRENT',
                 'IS_AGENT_ACTIVATED'
             )::BOOLEAN = TRUE
        THEN 'PASS - SERVICE_AGENT SESSION IS AGENT ACTIVE'
        ELSE 'FAIL - SERVICE_AGENT SESSION IS NOT AGENT ACTIVE'
    END AS M9_SERVICE_AGENT_TEST;