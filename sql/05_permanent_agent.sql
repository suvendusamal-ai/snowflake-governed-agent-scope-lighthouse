/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 05_permanent_agent.sql
 Purpose : Promote the banking Cortex Agent from the developer's Personal
           Database into the enterprise project database/schema.

 Milestone:
   M6 — Permanent Enterprise-Namespace Cortex Agent

 Architecture:

   PERSONAL DEVELOPMENT
   "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT
                       |
                       | promote configuration
                       v
   ENTERPRISE NAMESPACE
   AGENT_SCOPE_LAB.AGENTS.BANKING_SHARED_AGENT

 Proof objectives:
   1. Create a permanent Agent in enterprise database/schema.
   2. Confirm Agent is outside USER$SUVENDU.
   3. Confirm it is persistent and versioned.
   4. Confirm it is NOT yet SECURE.
   5. Retain the governed BankingAnalyst tool.
   6. Retain BANKING_ANALYTICS Semantic View.
   7. Retain AGENT_SCOPE_WH execution environment.
   8. Validate deterministic TXN-9001 grounding.

 Deliberately NOT tested here:
   - Secure specification redaction
   - COPY GRANTS
   - Restricted Session Scope
   - Agent-aware masking
   - Tool degradation
==============================================================================*/


-- ============================================================================
-- 0. ENTERPRISE ADMIN CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA AGENTS;


/*==============================================================================
 1. CAPTURE CREATION SESSION
==============================================================================*/

SELECT
    CURRENT_USER()       AS CURRENT_USER,
    CURRENT_ROLE()       AS CURRENT_ROLE,
    CURRENT_DATABASE()   AS CURRENT_DATABASE,
    CURRENT_SCHEMA()     AS CURRENT_SCHEMA,
    CURRENT_WAREHOUSE()  AS CURRENT_WAREHOUSE,
    CURRENT_SESSION()    AS CURRENT_SESSION;


/*==============================================================================
 2. SHOW PERSONAL DEVELOPMENT AGENT

 This is our M5 source/development Agent.

 We are NOT moving the Snowflake object itself.

 We are promoting the tested Agent configuration into an enterprise namespace.
==============================================================================*/

SHOW AGENTS
    LIKE 'BANKING_DEV_AGENT'
    IN SCHEMA "USER$SUVENDU".PUBLIC;


/*==============================================================================
 3. CREATE PERMANENT ENTERPRISE AGENT

 Important:

   - No TEMPORARY modifier
   - No SECURE modifier yet
   - Object lives in AGENT_SCOPE_LAB.AGENTS
==============================================================================*/

CREATE OR REPLACE AGENT
    AGENT_SCOPE_LAB.AGENTS.BANKING_SHARED_AGENT

COMMENT =
'Permanent enterprise banking Agent for Agent Scope Lighthouse'

FROM SPECIFICATION
$$

models:
  orchestration: auto


tools:

  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "BankingAnalyst"
      description: >
        Answers governed analytical questions about banking customers,
        accounts and transactions using the BANKING_ANALYTICS
        semantic view.


tool_resources:

  BankingAnalyst:

    semantic_view: "AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS"

    execution_environment:
      type: "warehouse"
      warehouse: "AGENT_SCOPE_WH"
      query_timeout: 60


instructions:

  response: >
    You are a governed enterprise banking investigation assistant.

    Use the BankingAnalyst tool for questions requiring information
    about customers, accounts or transactions.

    Base factual answers only on information returned from governed tools.

    Do not invent customer, account, transaction, risk, currency or
    monetary information.

    When investigating a transaction, report the transaction ID,
    customer, account, transaction channel, risk classification,
    transaction amount and currency when those attributes are available
    from governed data.

    Clearly distinguish retrieved facts from interpretation.

    If governed data does not support an answer, state that the
    information is unavailable.

$$;


/*==============================================================================
 4. VERIFY ENTERPRISE OBJECT LOCATION

 Expected:

   NAME          = BANKING_SHARED_AGENT
   DATABASE_NAME = AGENT_SCOPE_LAB
   SCHEMA_NAME   = AGENTS
   IS_SECURE     = false
==============================================================================*/

SHOW AGENTS
    LIKE 'BANKING_SHARED_AGENT'
    IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 5. DESCRIBE ENTERPRISE AGENT

 Verify:

   permanent/versioned Agent
   BankingAnalyst
   BANKING_ANALYTICS
   AGENT_SCOPE_WH
==============================================================================*/

DESCRIBE AGENT
    AGENT_SCOPE_LAB.AGENTS.BANKING_SHARED_AGENT;


/*==============================================================================
 6. GOLDEN ENTITY-GROUNDING TEST

 Expected deterministic result:

   Transaction : TXN-9001
   Customer    : Neha Patel
   Customer ID : C004
   Account     : SA1003
   Channel     : INTERNATIONAL_TRANSFER
   Risk        : HIGH_RISK
   Amount      : 95000.00
   Currency    : INR

 This deliberately reuses the golden transaction.

 If promotion changes only lifecycle/object scope, business behavior
 should remain stable.
==============================================================================*/

SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        'AGENT_SCOPE_LAB.AGENTS.BANKING_SHARED_AGENT',
        $${
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                  "Investigate transaction TXN-9001. Return the customer, customer ID, account, transaction channel, risk classification, transaction amount and currency. Use only governed data available through your tools. Clearly distinguish retrieved facts from any interpretation."
                }
              ]
            }
          ]
        }$$,
        TRUE
    )
) AS TXN_9001_RESPONSE;


/*==============================================================================
 7. COMPARE PERSONAL AND ENTERPRISE AGENTS

 Both should now coexist.

 This is important:

 Personal Agent:
   "USER$SUVENDU".PUBLIC.BANKING_DEV_AGENT

 Enterprise Agent:
   AGENT_SCOPE_LAB.AGENTS.BANKING_SHARED_AGENT

 Promotion did NOT require deleting the development Agent.
==============================================================================*/

SHOW AGENTS
    LIKE 'BANKING_DEV_AGENT'
    IN SCHEMA "USER$SUVENDU".PUBLIC;

SHOW AGENTS
    LIKE 'BANKING_SHARED_AGENT'
    IN SCHEMA AGENT_SCOPE_LAB.AGENTS;


/*==============================================================================
 M6 PASS CRITERIA

 [ ] BANKING_DEV_AGENT still exists in USER$SUVENDU.PUBLIC

 [ ] BANKING_SHARED_AGENT successfully created

 [ ] Enterprise Agent location:
       AGENT_SCOPE_LAB.AGENTS

 [ ] Enterprise Agent is permanent

 [ ] Enterprise Agent is versioned

 [ ] IS_SECURE = false

 [ ] BankingAnalyst attached

 [ ] Semantic View =
       AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

 [ ] Execution warehouse =
       AGENT_SCOPE_WH

 [ ] TXN-9001 executes successfully

 [ ] Customer = Neha Patel

 [ ] Customer ID = C004

 [ ] Account = SA1003

 [ ] Channel = INTERNATIONAL_TRANSFER

 [ ] Risk = HIGH_RISK

 [ ] Amount = 95000.00

 [ ] Currency = INR

 [ ] Personal and Enterprise Agents coexist

==============================================================================*/