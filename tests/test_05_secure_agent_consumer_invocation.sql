/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : tests/test_05_secure_agent_consumer_invocation.sql

 Milestone:
   M7-B.4 — Secure Agent Consumer Invocation

 Purpose:
   Prove an isolated non-owner consumer can:

       discover Secure Agent       YES
       inspect Agent specification NO
       invoke Secure Agent         YES

 Expected architectural proof:

       USE WITHOUT INSPECT
==============================================================================*/


/*==============================================================================
 1. PROVE IDENTITY AND AUTHORIZATION BOUNDARY
==============================================================================*/

SELECT
    CURRENT_USER()              AS CURRENT_USER,
    CURRENT_ROLE()              AS CURRENT_ROLE,
    CURRENT_SECONDARY_ROLES()   AS CURRENT_SECONDARY_ROLES,
    CURRENT_WAREHOUSE()         AS CURRENT_WAREHOUSE,
    CURRENT_DATABASE()          AS CURRENT_DATABASE,
    CURRENT_SCHEMA()            AS CURRENT_SCHEMA,
    IS_ROLE_IN_SESSION('ACCOUNTADMIN')
                                AS ACCOUNTADMIN_ACTIVATED;


/*==============================================================================
 Expected:

 CURRENT_USER:
     AGENT_SCOPE_TEST_USER

 CURRENT_ROLE:
     AGENT_SCOPE_CONSUMER_ROLE

 ACCOUNTADMIN_ACTIVATED:
     FALSE
==============================================================================*/


/*==============================================================================
 2. DISCOVERY TEST

 Consumer has USAGE on the Agent.

 Expected:
     Agent visible
     is_secure = true
==============================================================================*/

SHOW AGENTS
LIKE 'BANKING_SECURE_AGENT'
IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 3. SPECIFICATION VISIBILITY TEST

 Expected:
     DESCRIBE succeeds
     agent_spec = NULL
==============================================================================*/

DESCRIBE AGENT
AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT;


/*==============================================================================
 4. DDL VISIBILITY TEST

 Expected:
     specification remains hidden

 It must NOT expose:
     instructions
     BankingAnalyst configuration
     semantic_view binding
     execution_environment
==============================================================================*/

SELECT GET_DDL(
    'CORTEX_AGENT',
    'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT'
) AS CONSUMER_AGENT_DDL;


/*==============================================================================
 5. GOLDEN CONSUMER INVOCATION

 This is the decisive test.

 The consumer cannot inspect the Secure Agent specification,
 but should still be able to invoke it.
==============================================================================*/

SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT',
    $${
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text":
                        "Investigate transaction TXN-9001. Report the transaction ID, customer name, customer ID, account ID, transaction channel, risk classification, transaction amount and currency. Clearly separate retrieved facts from interpretation."
                    }
                ]
            }
        ]
    }$$
) AS AGENT_RESPONSE;


/*==============================================================================
 EXPECTED GOVERNED FACTS

 Transaction ID:
     TXN-9001

 Customer:
     Neha Patel

 Customer ID:
     C004

 Account:
     SA1003

 Channel:
     INTERNATIONAL_TRANSFER

 Risk:
     HIGH_RISK

 Amount:
     95000.00

 Currency:
     INR
==============================================================================*/


/*==============================================================================
 M7 FINAL PASS CRITERIA

 IDENTITY
 -------------------------------------------------------------------------------
 [ ] CURRENT_USER = AGENT_SCOPE_TEST_USER

 [ ] CURRENT_ROLE = AGENT_SCOPE_CONSUMER_ROLE

 [ ] ACCOUNTADMIN_ACTIVATED = FALSE


 OBJECT ACCESS
 -------------------------------------------------------------------------------
 [ ] BANKING_SECURE_AGENT visible

 [ ] is_secure = true


 SPECIFICATION GOVERNANCE
 -------------------------------------------------------------------------------
 [ ] DESCRIBE succeeds

 [ ] agent_spec = NULL

 [ ] GET_DDL specification hidden


 EXECUTION
 -------------------------------------------------------------------------------
 [ ] DATA_AGENT_RUN succeeds

 [ ] BankingAnalyst executes

 [ ] Semantic View executes

 [ ] TXN-9001 returned

 [ ] Neha Patel returned

 [ ] C004 returned

 [ ] SA1003 returned

 [ ] INTERNATIONAL_TRANSFER returned

 [ ] HIGH_RISK returned

 [ ] 95000.00 returned

 [ ] INR returned


 GOVERNANCE CLAIM
 -------------------------------------------------------------------------------

               SECURE AGENT
                    │
        ┌───────────┴────────────┐
        │                        │
     INSPECT                  INVOKE
        │                        │
        X                        ✓

   Consumer cannot          Consumer can use
   inspect Agent            governed capability
   implementation.

==============================================================================*/