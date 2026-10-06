/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : tests/test_04_prepare_consumer_user.sql
 Purpose : Prepare isolated consumer identity for Secure Agent invocation proof.

 Milestone:
   M7-B.4 — Consumer Invocation Preparation
==============================================================================*/

USE ROLE ACCOUNTADMIN;


/*==============================================================================
 1. RESTORE SECURE AGENT COMMENT

 Previous negative test unexpectedly succeeded because ACCOUNTADMIN was active
 through secondary roles. Restore intended production metadata.
==============================================================================*/

ALTER AGENT AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT
SET COMMENT =
'Secure production-style banking Agent for Agent Scope Lighthouse';


/*==============================================================================
 2. CREATE ISOLATED SERVICE USER

 We deliberately use a TYPE=SERVICE identity for automated CLI testing.

 IMPORTANT:
   RSA_PUBLIC_KEY is added separately after generating the key pair.

 DEFAULT_ROLE:
   AGENT_SCOPE_CONSUMER_ROLE

 DEFAULT_SECONDARY_ROLES:
   NONE

 This creates a clean consumer authorization boundary.
==============================================================================*/

CREATE USER IF NOT EXISTS AGENT_SCOPE_TEST_USER
    TYPE = SERVICE
    DEFAULT_ROLE = AGENT_SCOPE_CONSUMER_ROLE
    DEFAULT_WAREHOUSE = AGENT_SCOPE_WH
    DEFAULT_NAMESPACE = 'AGENT_SCOPE_LAB.AGENTS'
    DEFAULT_SECONDARY_ROLES = ()
    COMMENT = 'Isolated consumer identity for Agent Scope Lighthouse';


/*==============================================================================
 3. GRANT ONLY CONSUMER ROLE
==============================================================================*/

GRANT ROLE AGENT_SCOPE_CONSUMER_ROLE
TO USER AGENT_SCOPE_TEST_USER;


/*==============================================================================
 4. VERIFY USER CONFIGURATION
==============================================================================*/

DESCRIBE USER AGENT_SCOPE_TEST_USER;


/*==============================================================================
 5. VERIFY ROLE GRANTS
==============================================================================*/

SHOW GRANTS TO USER AGENT_SCOPE_TEST_USER;


/*==============================================================================
 6. VERIFY SECURE AGENT COMMENT RESTORED
==============================================================================*/

SHOW AGENTS
LIKE 'BANKING_SECURE_AGENT'
IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 PASS CRITERIA

 [ ] AGENT_SCOPE_TEST_USER exists

 [ ] TYPE = SERVICE

 [ ] DEFAULT_ROLE = AGENT_SCOPE_CONSUMER_ROLE

 [ ] DEFAULT_WAREHOUSE = AGENT_SCOPE_WH

 [ ] DEFAULT_NAMESPACE = AGENT_SCOPE_LAB.AGENTS

 [ ] DEFAULT_SECONDARY_ROLES = []

 [ ] Consumer role granted

 [ ] ACCOUNTADMIN is NOT granted to test user

 [ ] Secure Agent production comment restored

==============================================================================*/