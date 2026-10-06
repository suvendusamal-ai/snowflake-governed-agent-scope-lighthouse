/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : tests/test_02_secure_agent_consumer.sql
 Purpose : Prove Secure Agent "USE WITHOUT INSPECT" behavior.

 Milestone:
   M7-B — Secure Agent Consumer Boundary

 Expected governance result:

   ACCOUNTADMIN
      Agent USAGE       = YES
      Agent spec        = VISIBLE
      Invocation        = YES

   AGENT_SCOPE_CONSUMER_ROLE
      Agent USAGE       = YES
      Agent spec        = HIDDEN
      Invocation        = YES

 IMPORTANT:
   DATA_AGENT_RUN derives Agent permissions from the querying user's
   DEFAULT ROLE.

   Therefore this file first validates metadata redaction under the
   consumer role.

   We also inspect the user's default role before deciding whether
   DATA_AGENT_RUN can be used as a valid consumer-role invocation proof.
==============================================================================*/


-- ============================================================================
-- 1. ADMIN — CREATE CLEAN CONSUMER ROLE
-- ============================================================================

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 2. GRANT CORTEX AGENT API ACCESS
==============================================================================*/

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 3. GRANT MINIMUM CONTAINER ACCESS
==============================================================================*/

GRANT USAGE
ON DATABASE AGENT_SCOPE_LAB
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.AGENTS
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;

GRANT USAGE
ON SCHEMA AGENT_SCOPE_LAB.SEMANTIC
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 4. GRANT AGENT INVOCATION — NOT OWNERSHIP / NOT MODIFY

 This is the central M7-B privilege.

 We intentionally DO NOT grant:
   OWNERSHIP
   MODIFY
   MONITOR
==============================================================================*/

GRANT USAGE
ON AGENT AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 5. GRANT SEMANTIC VIEW ACCESS

 Cortex Agent + Cortex Analyst requires access to the semantic resource.

 REFERENCES:
   permits the semantic view to be referenced by Cortex Agent.

 SELECT:
   permits querying through the semantic view.
==============================================================================*/

GRANT REFERENCES, SELECT
ON SEMANTIC VIEW AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 6. GRANT EXECUTION WAREHOUSE
==============================================================================*/

GRANT USAGE
ON WAREHOUSE AGENT_SCOPE_WH
TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 7. MAKE ROLE AVAILABLE TO SUVENDU

 This does NOT change SUVENDU's default role.
==============================================================================*/

GRANT ROLE AGENT_SCOPE_CONSUMER_ROLE
TO USER SUVENDU;


/*==============================================================================
 8. ADMIN — REVIEW EXACT GRANTS
==============================================================================*/

SHOW GRANTS TO ROLE AGENT_SCOPE_CONSUMER_ROLE;


/*==============================================================================
 9. CAPTURE SUVENDU DEFAULT ROLE

 Critical Snowflake Cortex Agent behavior:

 DATA_AGENT_RUN uses the querying user's DEFAULT ROLE for Agent permissions.

 We therefore capture it before invocation testing.
==============================================================================*/

DESCRIBE USER SUVENDU;


/*==============================================================================
 10. SWITCH CURRENT SQL ROLE TO CONSUMER

 This is sufficient for the metadata visibility test.

 It does NOT by itself prove DATA_AGENT_RUN is executing under this role.
==============================================================================*/

USE ROLE AGENT_SCOPE_CONSUMER_ROLE;
USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA AGENTS;


SELECT
    CURRENT_USER()       AS CURRENT_USER,
    CURRENT_ROLE()       AS CURRENT_ROLE,
    CURRENT_DATABASE()   AS CURRENT_DATABASE,
    CURRENT_SCHEMA()     AS CURRENT_SCHEMA,
    CURRENT_WAREHOUSE()  AS CURRENT_WAREHOUSE,
    CURRENT_SESSION()    AS CURRENT_SESSION;


/*==============================================================================
 11. CONSUMER CAN SEE AGENT OBJECT

 Expected:

   BANKING_SECURE_AGENT exists
   is_secure = true
==============================================================================*/

SHOW AGENTS
LIKE 'BANKING_SECURE_AGENT'
IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 12. DECISIVE SECURE-AGENT TEST #1

 Expected:

   DESCRIBE succeeds.

 BUT:

   agent_spec = NULL

 Why?

 Consumer has USAGE but does not have activated owner role.
==============================================================================*/

DESCRIBE AGENT
AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT;


/*==============================================================================
 13. DECISIVE SECURE-AGENT TEST #2

 Expected:

   GET_DDL succeeds,
   BUT specification is omitted/redacted.

 It must NOT expose:
   - system instructions
   - BankingAnalyst definition
   - semantic_view binding
   - execution_environment
==============================================================================*/

SELECT GET_DDL(
    'CORTEX_AGENT',
    'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT'
) AS CONSUMER_AGENT_DDL;


/*==============================================================================
 14. NEGATIVE AUTHORIZATION TEST

 Consumer was NOT granted MODIFY or OWNERSHIP.

 Therefore consumer should NOT be able to modify the Agent.

 Expected:
   FAIL with insufficient privilege.

 IMPORTANT:
   This failure is EXPECTED and counts as governance PASS evidence.
==============================================================================*/

ALTER AGENT
AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT
SET COMMENT = 'THIS CHANGE MUST NOT SUCCEED';


/*==============================================================================
 M7-B — PHASE 1 PASS CRITERIA

 [ ] AGENT_SCOPE_CONSUMER_ROLE created

 [ ] CORTEX_AGENT_USER granted

 [ ] Database USAGE granted

 [ ] AGENTS schema USAGE granted

 [ ] SEMANTIC schema USAGE granted

 [ ] Secure Agent USAGE granted

 [ ] Semantic View REFERENCES granted

 [ ] Semantic View SELECT granted

 [ ] Warehouse USAGE granted

 [ ] Role granted to SUVENDU

 [ ] CURRENT_ROLE = AGENT_SCOPE_CONSUMER_ROLE

 [ ] SHOW AGENTS sees BANKING_SECURE_AGENT

 [ ] IS_SECURE = true

 [ ] DESCRIBE AGENT succeeds

 [ ] DESCRIBE.agent_spec = NULL

 [ ] GET_DDL does NOT expose specification

 [ ] ALTER AGENT fails because consumer lacks MODIFY/OWNERSHIP

==============================================================================*/