/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 04_personal_agent.sql
 Purpose : Demonstrate a persistent Cortex Agent in the user's Personal Database.

 Milestone:
   M5 — Personal Database Agent

 Architectural objective:

   M4 — Temporary Agent
       USER + ROLE + SESSION
              |
              v
       TEMP_BANKING_AGENT
              |
       session terminates
              |
              v
          disappears

   M5 — Personal Database Agent
              |
              v
       "USER$SUVENDU".PUBLIC
              |
              v
       BANKING_DEV_AGENT
              |
       session terminates
              |
              v
          persists

 Proof objectives:
   1. Verify Personal Database context.
   2. Create persistent BANKING_DEV_AGENT.
   3. Attach the same BankingAnalyst tool.
   4. Use the same BANKING_ANALYTICS Semantic View.
   5. Use the same AGENT_SCOPE_WH execution environment.
   6. Validate the same deterministic HIGH_RISK query.
   7. Validate TXN-9001.
   8. Confirm Agent remains visible in the creating session.

 Cross-session persistence will be tested separately after this file completes.
==============================================================================*/


-- ============================================================================
-- 0. ADMIN / EXECUTION CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;

USE WAREHOUSE AGENT_SCOPE_WH;


/*==============================================================================
 1. SESSION BASELINE

 Record the session so we can later prove that the Personal Database Agent
 survives after THIS session terminates.
==============================================================================*/

SELECT
    CURRENT_USER()       AS CURRENT_USER,
    CURRENT_ROLE()       AS CURRENT_ROLE,
    CURRENT_WAREHOUSE()  AS CURRENT_WAREHOUSE,
    CURRENT_SESSION()    AS CURRENT_SESSION;


/*==============================================================================
 2. PERSONAL DATABASE DISCOVERY

 Snowflake Personal Databases use:

     USER$<username>

 For user SUVENDU:

     USER$SUVENDU

 The database identifier contains '$', so we explicitly quote it.
==============================================================================*/

SHOW DATABASES LIKE 'USER$SUVENDU';


/*==============================================================================
 3. PERSONAL DATABASE SCHEMA DISCOVERY

 Cortex Agents in Personal Databases are created in PUBLIC.

 Expected target:

     "USER$SUVENDU".PUBLIC
==============================================================================*/

SHOW SCHEMAS IN DATABASE "USER$SUVENDU";


/*==============================================================================
 4. CREATE PERSONAL DATABASE AGENT

 IMPORTANT:

 This is NOT a TEMPORARY Agent.

 Therefore its lifecycle is not tied to CURRENT_SESSION().

 Object:

     "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT

 We intentionally reuse the same semantic and execution resources from M4 so
 that lifecycle/object scope is the primary variable being changed.
==============================================================================*/

CREATE OR REPLACE AGENT
    "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT

COMMENT =
'Persistent personal-development banking Agent for Agent Scope Lighthouse'

FROM SPECIFICATION
$$

models:
  orchestration: auto


tools:

  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "BankingAnalyst"
      description: >
        Answers analytical questions about banking customers,
        accounts and transactions using the governed
        BANKING_ANALYTICS semantic view.


tool_resources:

  BankingAnalyst:

    semantic_view: "AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS"

    execution_environment:
      type: "warehouse"
      warehouse: "AGENT_SCOPE_WH"
      query_timeout: 60


instructions:

  response: >
    You are a governed banking investigation assistant operating as a
    personal-development Cortex Agent.

    Use the BankingAnalyst tool for questions requiring information
    about customers, accounts or transactions.

    Base answers only on information returned from governed tools.

    Do not invent customer, account, transaction, risk, currency or
    monetary information.

    When investigating a transaction, report the transaction ID,
    customer, account, transaction channel, risk classification and
    transaction amount when those attributes are available.

    Do not add a currency symbol unless currency is explicitly returned
    by governed data for the requested result.

    If the available governed data does not support an answer,
    clearly state that the information is unavailable.

$$;


/*==============================================================================
 5. VERIFY PERSONAL AGENT EXISTS

 Expected:

     BANKING_DEV_AGENT

 Database:

     USER$SUVENDU

 Schema:

     PUBLIC
==============================================================================*/

SHOW AGENTS
    LIKE 'BANKING_DEV_AGENT'
    IN SCHEMA "USER$SUVENDU".PUBLIC;


/*==============================================================================
 6. DESCRIBE PERSONAL AGENT

 Validate:

     Object location:
         USER$SUVENDU.PUBLIC

     Tool:
         BankingAnalyst

     Semantic View:
         AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

     Execution environment:
         AGENT_SCOPE_WH
==============================================================================*/

DESCRIBE AGENT
    "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT;


/*==============================================================================
 7. TEST A — HIGH-RISK AGGREGATION

 Same deterministic question used for M4.

 Expected governed facts:

     HIGH_RISK count = 1
     Total value     = 95000.00

 IMPORTANT:
     No currency symbol should be inferred unless currency is returned
     by the governed result.
==============================================================================*/

SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        '"USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT',
        $${
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                  "How many HIGH_RISK transactions are present and what is their total transaction value? Do not infer a currency unless it is returned by governed data."
                }
              ]
            }
          ]
        }$$,
        TRUE
    )
) AS HIGH_RISK_RESPONSE;


/*==============================================================================
 8. TEST B — GOLDEN TRANSACTION

 Deterministic expected values:

     Transaction ID : TXN-9001
     Customer       : Neha Patel
     Account        : SA1003
     Channel        : INTERNATIONAL_TRANSFER
     Risk           : HIGH_RISK
     Amount         : 95000.00

 Again, currency must not be invented.
==============================================================================*/

SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        '"USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT',
        $${
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                  "Investigate transaction TXN-9001. Identify the customer, account, transaction channel, risk classification and transaction amount. Use only governed data available through your tools. Do not infer a currency unless currency is explicitly returned by the governed data."
                }
              ]
            }
          ]
        }$$,
        TRUE
    )
) AS TXN_9001_RESPONSE;


/*==============================================================================
 9. FINAL SAME-SESSION VISIBILITY CHECK

 Because this is a persistent Personal Database Agent, it should exist now.

 The stronger M5 lifecycle proof will happen AFTER this CLI session terminates.
==============================================================================*/

SHOW AGENTS
    LIKE 'BANKING_DEV_AGENT'
    IN SCHEMA "USER$SUVENDU".PUBLIC;


/*==============================================================================
 M5-A PASS CRITERIA
==============================================================================

 [ ] Personal Database USER$SUVENDU exists

 [ ] PUBLIC schema exists

 [ ] BANKING_DEV_AGENT created successfully

 [ ] Agent object resides in:
         "USER$SUVENDU".PUBLIC

 [ ] Agent is NOT temporary

 [ ] BankingAnalyst attached

 [ ] Semantic View:
         AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

 [ ] Execution environment:
         AGENT_SCOPE_WH

 [ ] HIGH_RISK query executes

 [ ] HIGH_RISK count = 1

 [ ] HIGH_RISK value = 95000.00

 [ ] TXN-9001 query executes

 [ ] Customer = Neha Patel

 [ ] Account = SA1003

 [ ] Channel = INTERNATIONAL_TRANSFER

 [ ] Risk = HIGH_RISK

 [ ] Amount = 95000.00

 [ ] Agent remains visible at end of current session


 -------------------------------------------------------------------------------
 M5-B — CROSS-SESSION PERSISTENCE
 -------------------------------------------------------------------------------

 NOT tested by this file.

 After this CLI invocation terminates, a NEW CLI session will execute:

     SHOW AGENTS LIKE 'BANKING_DEV_AGENT'
       IN SCHEMA "USER$SUVENDU".PUBLIC;

 Expected:

     BANKING_DEV_AGENT IS STILL PRESENT

 This is intentionally the opposite of M4:

     TEMP_BANKING_AGENT
         Session B -> No data

     BANKING_DEV_AGENT
         Session B -> Still present

==============================================================================*/