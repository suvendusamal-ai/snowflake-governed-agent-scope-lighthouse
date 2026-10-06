-- ============================================================================
-- File: sql/12_rss_controlled_action_tool.sql
-- Project: snowflake-governed-agent-scope-lighthouse
--
-- Milestone:
-- M12-B1 — Controlled Caller-Rights Action Procedure
--
-- Objective:
-- Create a narrowly constrained action boundary that can later be exposed
-- as a Cortex Agent custom tool.
--
-- Critical governance property:
--
--     EXECUTE AS CALLER
--
-- Therefore the procedure must execute under the invoking identity's
-- effective privileges rather than using an owner's-rights privilege path.
--
-- Allowed targets:
--
--     PROD
--     SANDBOX
--
-- No arbitrary database/schema/table identifiers are accepted.
-- ============================================================================


-- ============================================================================
-- 1. Administrative context
-- ============================================================================

USE ROLE ACCOUNTADMIN;

USE WAREHOUSE AGENT_SCOPE_WH;

USE DATABASE AGENT_SCOPE_LAB;

USE SCHEMA GOVERNANCE;


-- ============================================================================
-- 2. Create controlled action procedure
--
-- IMPORTANT:
-- This is intentionally NOT a generic SQL execution procedure.
--
-- The caller can choose only:
--
--     PROD
--     SANDBOX
--
-- The physical objects are hard-coded.
-- ============================================================================

CREATE OR REPLACE PROCEDURE
    AGENT_SCOPE_LAB.GOVERNANCE.RSS_CONTROLLED_UPDATE(
        TARGET_ENV STRING
    )
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    V_TARGET STRING;
BEGIN

    V_TARGET := UPPER(TRIM(TARGET_ENV));

    IF (V_TARGET = 'PROD') THEN

        UPDATE AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
        SET
            RECORD_STATUS   = 'UPDATED_BY_AGENT',
            UPDATED_BY_TEST = 'M12_AGENT_TOOL'
        WHERE RECORD_ID = 1;

        RETURN 'PROD_UPDATE_SUCCEEDED';

    ELSEIF (V_TARGET = 'SANDBOX') THEN

        UPDATE AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
        SET
            RECORD_STATUS   = 'UPDATED_BY_AGENT',
            UPDATED_BY_TEST = 'M12_AGENT_TOOL'
        WHERE RECORD_ID = 1;

        RETURN 'SANDBOX_UPDATE_SUCCEEDED';

    ELSE

        RETURN 'INVALID_TARGET: allowed values are PROD or SANDBOX';

    END IF;

END;
$$;


-- ============================================================================
-- 3. Grant procedure usage to autonomous Agent role
--
-- Underlying table UPDATE privileges already exist from M10.
--
-- The procedure itself now also needs to be invocable by the role.
-- ============================================================================

GRANT USAGE
ON PROCEDURE
    AGENT_SCOPE_LAB.GOVERNANCE.RSS_CONTROLLED_UPDATE(STRING)
TO ROLE
    AGENT_SCOPE_AUTONOMOUS_ROLE;


-- ============================================================================
-- 4. Describe procedure
--
-- Evidence should show EXECUTE AS CALLER / execute_as = CALLER.
-- ============================================================================

DESCRIBE PROCEDURE
    AGENT_SCOPE_LAB.GOVERNANCE.RSS_CONTROLLED_UPDATE(STRING);


-- ============================================================================
-- 5. Verify procedure grant
-- ============================================================================

SHOW GRANTS
ON PROCEDURE
    AGENT_SCOPE_LAB.GOVERNANCE.RSS_CONTROLLED_UPDATE(STRING);


-- ============================================================================
-- 6. Confirm source rows have NOT been changed merely by procedure creation
-- ============================================================================

SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
WHERE RECORD_ID = 1;


SELECT
    RECORD_ID,
    RECORD_STATUS,
    UPDATED_BY_TEST
FROM AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
WHERE RECORD_ID = 1;


-- ============================================================================
-- M12-B1 completion criteria
--
-- Procedure exists.
--
-- Procedure executes AS CALLER.
--
-- AGENT_SCOPE_AUTONOMOUS_ROLE has USAGE on the procedure.
--
-- Production remains:
--
--     ORIGINAL / SETUP
--
-- No procedure execution has occurred yet.
--
-- DO NOT call M12 PASS from this script.
-- ============================================================================