-- ============================================================================
-- M14 — Cortex Agent Native Lineage Evidence
-- File: sql/18_agent_lineage.sql
--
-- Purpose:
--   Demonstrate Snowflake native lineage across:
--
--     Source Tables
--         -> Semantic View
--         -> Cortex Agent
--
--   Also demonstrate downstream impact analysis from the Semantic View.
--
-- Important:
--   Procedure-backed Agent tools are intentionally NOT represented here.
--   GET_LINEAGE with domain PROCEDURE was tested separately and was
--   unsupported in this environment.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- M14-A
-- Native upstream lineage of the banking Semantic View.
--
-- Expected:
--   DATA.ACCOUNT
--   DATA.CUSTOMER
--   DATA.TRANSACTION
--
--   -> SEMANTIC.BANKING_ANALYTICS
-- ---------------------------------------------------------------------------

SELECT *
FROM TABLE(
    SNOWFLAKE.CORE.GET_LINEAGE(
        'AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS',
        'SEMANTIC_VIEW',
        'UPSTREAM'
    )
)
ORDER BY DISTANCE, SOURCE_OBJECT_SCHEMA, SOURCE_OBJECT_NAME;


-- ---------------------------------------------------------------------------
-- M14-B
-- Native upstream lineage of the governed Cortex Agent.
--
-- Expected:
--
--   Distance 1:
--     SEMANTIC.BANKING_ANALYTICS
--       -> AGENTS.BANKING_SECURE_AGENT
--
--   Distance 2:
--     DATA.ACCOUNT
--     DATA.CUSTOMER
--     DATA.TRANSACTION
--       -> SEMANTIC.BANKING_ANALYTICS
-- ---------------------------------------------------------------------------

SELECT *
FROM TABLE(
    SNOWFLAKE.CORE.GET_LINEAGE(
        'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT',
        'CORTEX_AGENT',
        'UPSTREAM'
    )
)
ORDER BY DISTANCE, SOURCE_OBJECT_SCHEMA, SOURCE_OBJECT_NAME;


-- ---------------------------------------------------------------------------
-- M14-E
-- Native downstream impact analysis from the Semantic View.
--
-- Demonstrates which Cortex Agents depend on BANKING_ANALYTICS.
-- ---------------------------------------------------------------------------

SELECT *
FROM TABLE(
    SNOWFLAKE.CORE.GET_LINEAGE(
        'AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS',
        'SEMANTIC_VIEW',
        'DOWNSTREAM'
    )
)
ORDER BY DISTANCE, TARGET_OBJECT_DATABASE, TARGET_OBJECT_SCHEMA,
         TARGET_OBJECT_NAME;