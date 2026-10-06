/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 Test    : M5-B — Personal Database Agent Cross-Session Persistence

 Expected:
   BANKING_DEV_AGENT must still exist even though the session that created
   the Agent has terminated.

 Contrast:
   TEMP_BANKING_AGENT  -> disappears after session
   BANKING_DEV_AGENT   -> persists after session
==============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AGENT_SCOPE_WH;

SELECT
    CURRENT_USER()      AS CURRENT_USER,
    CURRENT_ROLE()      AS CURRENT_ROLE,
    CURRENT_SESSION()   AS NEW_SESSION_ID;

SHOW AGENTS
    LIKE 'BANKING_DEV_AGENT'
    IN SCHEMA "USER$SUVENDU".PUBLIC;

DESCRIBE AGENT
    "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT;