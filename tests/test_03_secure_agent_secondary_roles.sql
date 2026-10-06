/*==============================================================================
 M7-B — Secure Agent Consumer Isolation
 Purpose:
   Remove secondary roles from the CURRENT SESSION and repeat the Secure Agent
   metadata test.

 Expected:
   ACCOUNTADMIN no longer activated.
   Consumer retains only AGENT_SCOPE_CONSUMER_ROLE authority.
==============================================================================*/


USE ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*----------------------------------------------------------------------------
 1. Disable secondary roles for THIS SESSION
----------------------------------------------------------------------------*/

USE SECONDARY ROLES NONE;


/*----------------------------------------------------------------------------
 2. Prove session authorization context
----------------------------------------------------------------------------*/

SELECT
    CURRENT_USER()              AS CURRENT_USER,
    CURRENT_ROLE()              AS CURRENT_ROLE,
    CURRENT_SECONDARY_ROLES()   AS CURRENT_SECONDARY_ROLES,
    IS_ROLE_IN_SESSION('ACCOUNTADMIN')
                                AS ACCOUNTADMIN_ACTIVATED;


/*----------------------------------------------------------------------------
 Expected:

 CURRENT_USER              SUVENDU

 CURRENT_ROLE              AGENT_SCOPE_CONSUMER_ROLE

 CURRENT_SECONDARY_ROLES   []

 ACCOUNTADMIN_ACTIVATED    FALSE
----------------------------------------------------------------------------*/


USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA AGENTS;


/*----------------------------------------------------------------------------
 3. Secure Agent remains discoverable
----------------------------------------------------------------------------*/

SHOW AGENTS
LIKE 'BANKING_SECURE_AGENT'
IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*----------------------------------------------------------------------------
 4. CRITICAL SECURE-AGENT TEST

 Expected:

 DESCRIBE succeeds because consumer has USAGE.

 BUT:

 agent_spec = NULL
----------------------------------------------------------------------------*/

DESCRIBE AGENT
AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT;


/*----------------------------------------------------------------------------
 5. GET_DDL redaction test

 Expected:

 Agent DDL metadata may be returned.

 Specification must NOT be exposed.
----------------------------------------------------------------------------*/

SELECT GET_DDL(
    'CORTEX_AGENT',
    'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT'
) AS CONSUMER_AGENT_DDL;


/*----------------------------------------------------------------------------
 6. DO NOT run ALTER AGENT yet.

 First establish whether specification redaction now works cleanly.
----------------------------------------------------------------------------*/


/*==============================================================================
 PASS CRITERIA

 [ ] CURRENT_ROLE = AGENT_SCOPE_CONSUMER_ROLE

 [ ] CURRENT_SECONDARY_ROLES contains no privileged role

 [ ] IS_ROLE_IN_SESSION('ACCOUNTADMIN') = FALSE

 [ ] SHOW AGENTS sees BANKING_SECURE_AGENT

 [ ] IS_SECURE = true

 [ ] DESCRIBE succeeds

 [ ] agent_spec = NULL

 [ ] GET_DDL does not expose:
       instructions
       BankingAnalyst
       semantic_view
       execution_environment

==============================================================================*/