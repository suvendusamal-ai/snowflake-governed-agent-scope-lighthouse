-- ============================================================================
-- M10-B SETUP — RSS RUNTIME ENFORCEMENT TEST
-- File: tests/setup_02_rss_runtime_test.sql
--
-- Objective:
-- Give AGENT_SCOPE_AUTONOMOUS_ROLE sufficient RBAC authority to modify
-- controlled objects in BOTH DATA and SANDBOX.
--
-- This is intentional:
--   RBAC must allow both writes so that the later production-write denial
--   can be attributed to RSS rather than missing RBAC privileges.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;


-- ============================================================================
-- 1. CONTROLLED "PRODUCTION" TEST OBJECT
-- ============================================================================

CREATE OR REPLACE TABLE DATA.RSS_PROD_TEST
(
    RECORD_ID       NUMBER,
    RECORD_STATUS   VARCHAR,
    UPDATED_BY_TEST VARCHAR
);

INSERT INTO DATA.RSS_PROD_TEST
VALUES
    (1, 'ORIGINAL', 'SETUP');


-- ============================================================================
-- 2. CONTROLLED SANDBOX TEST OBJECT
-- ============================================================================

CREATE OR REPLACE TABLE SANDBOX.RSS_SANDBOX_TEST
(
    RECORD_ID       NUMBER,
    RECORD_STATUS   VARCHAR,
    UPDATED_BY_TEST VARCHAR
);

INSERT INTO SANDBOX.RSS_SANDBOX_TEST
VALUES
    (1, 'ORIGINAL', 'SETUP');


-- ============================================================================
-- 3. RBAC — GIVE AUTONOMOUS ROLE ACCESS TO BOTH SCHEMAS
--
-- IMPORTANT:
-- We deliberately grant equivalent object privileges on BOTH tables.
-- Therefore, later differences in runtime behavior can be attributed
-- to RSS rather than ordinary RBAC.
-- ============================================================================

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.DATA
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.SANDBOX
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


GRANT SELECT, UPDATE
ON TABLE AGENT_SCOPE_LAB.DATA.RSS_PROD_TEST
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


GRANT SELECT, INSERT, UPDATE
ON TABLE AGENT_SCOPE_LAB.SANDBOX.RSS_SANDBOX_TEST
TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


-- ============================================================================
-- 4. VERIFY UNDERLYING RBAC
-- ============================================================================

SHOW GRANTS TO ROLE AGENT_SCOPE_AUTONOMOUS_ROLE;


-- ============================================================================
-- 5. VERIFY BASELINE DATA
-- ============================================================================

SELECT *
FROM DATA.RSS_PROD_TEST
ORDER BY RECORD_ID;


SELECT *
FROM SANDBOX.RSS_SANDBOX_TEST
ORDER BY RECORD_ID;