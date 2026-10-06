/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 03_temporary_agent.sql
 Purpose : Demonstrate a session-scoped Temporary Cortex Agent using the
           BANKING_ANALYTICS native Semantic View.

 Milestone:
   M4 — Temporary Cortex Agent

 Proof objectives:
   1. Create TEMPORARY AGENT.
   2. Attach Cortex Analyst to BANKING_ANALYTICS.
   3. Explicitly define the Analyst execution warehouse.
   4. Verify the Agent exists in THIS session.
   5. Invoke the Agent against the semantic layer.
   6. Validate deterministic HIGH_RISK results.
   7. Validate TXN-9001 grounding.
   8. Leave lifecycle-disappearance proof for a NEW session.

 Architecture:

   TEMP_BANKING_AGENT
           |
           v
     BankingAnalyst
        /       \
       v         v
 Semantic View   Execution Environment
 BANKING_        AGENT_SCOPE_WH
 ANALYTICS
       |
       v
 CUSTOMER -> ACCOUNT -> TRANSACTION

 IMPORTANT:
   Temporary Agent lifecycle is bound to:
       User + Role + Session

   When this Snowflake session terminates, the Temporary Agent should
   automatically disappear.
==============================================================================*/


-- ============================================================================
-- 0. EXECUTION CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;

USE WAREHOUSE AGENT_SCOPE_WH;

USE DATABASE AGENT_SCOPE_LAB;

USE SCHEMA AGENTS;


/*==============================================================================
 1. SESSION IDENTITY BASELINE

 Capture the execution context because Temporary Agent scope is associated
 with the current:

     - user
     - role
     - session

 We will use this information later when proving lifecycle isolation.
==============================================================================*/

SELECT
    CURRENT_USER()       AS CURRENT_USER,
    CURRENT_ROLE()       AS CURRENT_ROLE,
    CURRENT_DATABASE()   AS CURRENT_DATABASE,
    CURRENT_SCHEMA()     AS CURRENT_SCHEMA,
    CURRENT_WAREHOUSE()  AS CURRENT_WAREHOUSE,
    CURRENT_SESSION()    AS CURRENT_SESSION;


/*==============================================================================
 2. CREATE TEMPORARY CORTEX AGENT

 The Agent contains one governed tool:

     BankingAnalyst

 BankingAnalyst uses:

     Semantic resource:
         AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

     Execution resource:
         AGENT_SCOPE_WH

 IMPORTANT ARCHITECTURAL POINT:

 USE WAREHOUSE establishes the warehouse for the SQL session.

 The Cortex Analyst tool is a server-executed Agent tool and therefore needs
 an execution environment of its own, unless an appropriate default warehouse
 is available for the user.

 We configure the execution environment explicitly to make the Agent
 specification deterministic and portable.
==============================================================================*/

CREATE TEMPORARY AGENT TEMP_BANKING_AGENT

COMMENT =
'Session-scoped banking Cortex Agent for Agent Scope Lighthouse'

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
    You are a governed banking investigation assistant.

    Use the BankingAnalyst tool for questions requiring information
    about customers, accounts or transactions.

    Base answers only on information returned from governed tools.

    Do not invent customer, account, transaction, risk or monetary
    information.

    When investigating a transaction, report the transaction ID,
    customer, account, transaction channel, risk classification and
    transaction amount when those attributes are available.

    If the available governed data does not support an answer,
    clearly state that the information is unavailable.

$$;


/*==============================================================================
 3. SAME-SESSION OBJECT VALIDATION

 Expected:

     TEMP_BANKING_AGENT

 should be visible because we are still inside the same Snowflake session
 in which it was created.

 This proves object creation and same-session visibility.

 It does NOT yet prove lifecycle cleanup.
==============================================================================*/

SHOW AGENTS
    LIKE 'TEMP_BANKING_AGENT'
    IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 4. DESCRIBE TEMPORARY AGENT

 Validate that the specification contains:

     BankingAnalyst

     semantic_view:
       AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

     execution_environment:
       warehouse = AGENT_SCOPE_WH
==============================================================================*/

DESCRIBE AGENT
    AGENT_SCOPE_LAB.AGENTS.TEMP_BANKING_AGENT;


/*==============================================================================
 5. TEST A — HIGH-RISK AGGREGATION

 Business question:

   "How many HIGH_RISK transactions are present and what is their
    total transaction value?"

 This tests the complete path:

       Natural-language question
                 |
                 v
       TEMP_BANKING_AGENT
                 |
                 v
          BankingAnalyst
                 |
                 v
         BANKING_ANALYTICS
                 |
                 v
       Generated / executed SQL
                 |
                 v
          Governed result


 Deterministic expected evidence from M3:

     HIGH_RISK transaction count = 1
     Total transaction value     = 95,000 INR

 Exact natural-language wording may vary.
 The FACTS must not vary.
==============================================================================*/

SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        'AGENT_SCOPE_LAB.AGENTS.TEMP_BANKING_AGENT',
        $${
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                  "How many HIGH_RISK transactions are present and what is their total transaction value?"
                }
              ]
            }
          ]
        }$$,
        TRUE
    )
) AS HIGH_RISK_RESPONSE;


/*==============================================================================
 6. TEST B — GOLDEN TRANSACTION INVESTIGATION

 TXN-9001 is the deterministic golden transaction used throughout this
 lighthouse.

 Question:

     Investigate transaction TXN-9001.

 Expected governed facts:

     Transaction ID : TXN-9001
     Customer       : Neha Patel
     Account        : SA1003
     Channel        : INTERNATIONAL_TRANSFER
     Risk           : HIGH_RISK
     Amount         : 95,000 INR

 These values were already independently proven during M2 and M3.

 Therefore, this test evaluates whether the Agent can correctly consume
 the governed Semantic View rather than whether the source data is correct.
==============================================================================*/

SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        'AGENT_SCOPE_LAB.AGENTS.TEMP_BANKING_AGENT',
        $${
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                  "Investigate transaction TXN-9001. Identify the customer, account, transaction channel, risk classification and transaction amount. Use only governed data available through your tools."
                }
              ]
            }
          ]
        }$$,
        TRUE
    )
) AS TXN_9001_RESPONSE;


/*==============================================================================
 7. FINAL SAME-SESSION CHECK

 The Temporary Agent should still exist because this SQL file is executing
 inside the same Snowflake session.

 Expected:

     TEMP_BANKING_AGENT visible
==============================================================================*/

SHOW AGENTS
    LIKE 'TEMP_BANKING_AGENT'
    IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 M4-A PASS CRITERIA
==============================================================================

 [ ] CURRENT_SESSION captured

 [ ] TEMP_BANKING_AGENT created successfully

 [ ] SHOW AGENTS sees TEMP_BANKING_AGENT

 [ ] DESCRIBE AGENT succeeds

 [ ] BankingAnalyst tool exists

 [ ] Semantic View resource:
         AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

 [ ] Execution environment:
         AGENT_SCOPE_WH

 [ ] HIGH_RISK analytical question executes successfully

 [ ] HIGH_RISK transaction count = 1

 [ ] HIGH_RISK total transaction value = 95,000 INR

 [ ] TXN-9001 investigation executes successfully

 [ ] TXN-9001 customer = Neha Patel

 [ ] TXN-9001 account = SA1003

 [ ] TXN-9001 channel = INTERNATIONAL_TRANSFER

 [ ] TXN-9001 risk = HIGH_RISK

 [ ] TXN-9001 amount = 95,000 INR

 [ ] TEMP_BANKING_AGENT remains visible at end of this session


 -------------------------------------------------------------------------------
 M4-B — NOT TESTED BY THIS FILE
 -------------------------------------------------------------------------------

 The next test will start a NEW Snowflake CLI session.

 Expected:

     Session A
         |
         | CREATE TEMPORARY AGENT
         v
     TEMP_BANKING_AGENT
         |
         | Session A terminates
         v
       AUTO DROP


     Session B
         |
         | SHOW AGENTS
         v
     TEMP_BANKING_AGENT absent


 The ABSENCE of TEMP_BANKING_AGENT in Session B will be considered:

     M4-B PASS

==============================================================================*/