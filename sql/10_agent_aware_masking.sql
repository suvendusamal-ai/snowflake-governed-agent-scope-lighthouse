-- ============================================================================
-- File: sql/10_agent_aware_masking.sql
-- Project: snowflake-governed-agent-scope-lighthouse
-- Milestone: M11-A — Agent-Aware Masking Design / Prerequisite Validation
--
-- Objective:
--   Establish a controlled experiment proving that an agent-active execution
--   context can receive a more restrictive data disclosure even when RBAC
--   authorizes both SERVICE and SERVICE_AGENT identities to read the same
--   protected object.
--
-- Expected later runtime behavior:
--
--   SERVICE:
--       IS_AGENT_ACTIVATED = FALSE
--       SELECT allowed
--       EMAIL returned unmasked
--
--   SERVICE_AGENT:
--       IS_AGENT_ACTIVATED = TRUE
--       SELECT allowed
--       EMAIL returned masked
--
-- Important:
--   This file establishes the policy, protected view, and comparable RBAC.
--   Runtime proof is performed separately after this prerequisite succeeds.
-- ============================================================================


-- ============================================================================
-- 1. Administrative execution context
-- ============================================================================

USE ROLE ACCOUNTADMIN;

USE WAREHOUSE AGENT_SCOPE_WH;

USE DATABASE AGENT_SCOPE_LAB;

USE SCHEMA GOVERNANCE;


-- ============================================================================
-- 2. Create agent-aware masking policy
--
-- Snowflake-supported pattern:
--
-- SYS_CONTEXT(
--     'SNOWFLAKE$CURRENT',
--     'IS_AGENT_ACTIVATED'
-- )::BOOLEAN
--
-- If an agent is active:
--     return masked value
--
-- Otherwise:
--     return original value
-- ============================================================================

CREATE OR REPLACE MASKING POLICY
    AGENT_SCOPE_LAB.GOVERNANCE.AGENT_EMAIL_MASK
AS (VAL STRING)
RETURNS STRING ->
    CASE
        WHEN SYS_CONTEXT(
                 'SNOWFLAKE$CURRENT',
                 'IS_AGENT_ACTIVATED'
             )::BOOLEAN = TRUE
        THEN '***AGENT-MASKED***'
        ELSE VAL
    END
COMMENT =
    'M11 lighthouse policy: masks EMAIL whenever execution context is agent-active';


-- ============================================================================
-- 3. Create narrow test view
--
-- Deliberately expose only:
--
--     CUSTOMER_ID
--     EMAIL
--
-- Do NOT grant either experimental role direct access to the broader
-- DATA.CUSTOMER table as part of M11.
-- ============================================================================

CREATE OR REPLACE VIEW
    AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
AS
SELECT
    CUSTOMER_ID,
    EMAIL
FROM AGENT_SCOPE_LAB.DATA.CUSTOMER;


-- ============================================================================
-- 4. Attach agent-aware masking policy to the view EMAIL column
-- ============================================================================

ALTER VIEW
    AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
MODIFY COLUMN EMAIL
SET MASKING POLICY
    AGENT_SCOPE_LAB.GOVERNANCE.AGENT_EMAIL_MASK;


-- ============================================================================
-- 5. Establish equivalent object authorization
--
-- Control:
--     AGENT_SCOPE_CONSUMER_ROLE
--     used by AGENT_SCOPE_TEST_USER / SERVICE
--
-- Treatment:
--     AGENT_SCOPE_AUTONOMOUS_ROLE
--     used by AGENT_SCOPE_AUTONOMOUS_USER / SERVICE_AGENT
--
-- Both receive identical access to the M11 test interface.
-- ============================================================================

GRANT USAGE
ON DATABASE AGENT_SCOPE_LAB
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.GOVERNANCE
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;

GRANT SELECT
ON VIEW AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


GRANT USAGE
ON DATABASE AGENT_SCOPE_LAB
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.GOVERNANCE
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;

GRANT SELECT
ON VIEW AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


-- ============================================================================
-- 6. Administrative prerequisite evidence
-- ============================================================================

SELECT
    CURRENT_USER()      AS EXECUTING_USER,
    CURRENT_ROLE()      AS EXECUTING_ROLE,
    CURRENT_DATABASE()  AS CURRENT_DB,
    CURRENT_SCHEMA()    AS CURRENT_SCHEMA;


-- ============================================================================
-- 7. Confirm masking policy exists
-- ============================================================================

SHOW MASKING POLICIES
LIKE 'AGENT_EMAIL_MASK'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


-- ============================================================================
-- 8. Confirm view exists
-- ============================================================================

SHOW VIEWS
LIKE 'CUSTOMER_EMAIL_AGENT_TEST_V'
IN SCHEMA AGENT_SCOPE_LAB.GOVERNANCE;


-- ============================================================================
-- 9. Confirm masking-policy attachment
-- ============================================================================

SELECT
    POLICY_NAME,
    POLICY_KIND,
    REF_ENTITY_NAME,
    REF_ENTITY_DOMAIN,
    REF_COLUMN_NAME
FROM TABLE(
    AGENT_SCOPE_LAB.INFORMATION_SCHEMA.POLICY_REFERENCES(
        REF_ENTITY_NAME =>
            'AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V',
        REF_ENTITY_DOMAIN => 'VIEW'
    )
)
ORDER BY
    POLICY_NAME,
    REF_COLUMN_NAME;


-- ============================================================================
-- 10. Confirm equivalent grants on protected view
-- ============================================================================

SHOW GRANTS
ON VIEW AGENT_SCOPE_LAB.GOVERNANCE.CUSTOMER_EMAIL_AGENT_TEST_V;


-- ============================================================================
-- M11-A prerequisite complete.
--
-- DO NOT infer M11 PASS from this script.
--
-- Required next evidence:
--
-- SERVICE:
--     IS_AGENT_ACTIVATED = FALSE
--     SELECT succeeds
--     EMAIL = raw
--
-- SERVICE_AGENT:
--     IS_AGENT_ACTIVATED = TRUE
--     SELECT succeeds
--     EMAIL = ***AGENT-MASKED***
--
-- Only runtime evidence can establish M11.
-- ============================================================================