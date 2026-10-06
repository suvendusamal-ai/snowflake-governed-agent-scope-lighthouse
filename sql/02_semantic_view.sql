/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 02_semantic_view.sql
 Purpose : Create the native Snowflake Semantic View that provides governed
           business meaning to Cortex Analyst and, later, Cortex Agent.

 Business model:

   CUSTOMER
      1
      |
      | CUSTOMER_ID
      |
      N
   ACCOUNT
      1
      |
      | ACCOUNT_ID
      |
      N
   TRANSACTION

 IMPORTANT:
   This layer defines analytical semantics.
   Agent security controls such as RSS, masking and agent identity will be
   implemented separately in later milestones.
==============================================================================*/


-- ============================================================================
-- 0. EXECUTION CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA SEMANTIC;


/*==============================================================================
 1. CREATE NATIVE SEMANTIC VIEW
==============================================================================*/

CREATE OR REPLACE SEMANTIC VIEW BANKING_ANALYTICS

TABLES (

    customer AS AGENT_SCOPE_LAB.DATA.CUSTOMER
        PRIMARY KEY (CUSTOMER_ID)
        WITH SYNONYMS ('customers', 'bank customers', 'clients')
        COMMENT = 'Synthetic banking customers',

    account AS AGENT_SCOPE_LAB.DATA.ACCOUNT
        PRIMARY KEY (ACCOUNT_ID)
        WITH SYNONYMS ('accounts', 'bank accounts')
        COMMENT = 'Bank accounts owned by customers',

    txn AS AGENT_SCOPE_LAB.DATA.TRANSACTION
        PRIMARY KEY (TRANSACTION_ID)
        WITH SYNONYMS ('transactions', 'bank transactions', 'payments')
        COMMENT = 'Financial transactions executed against bank accounts'

)


/*==============================================================================
 2. BUSINESS RELATIONSHIPS

 Many accounts may belong to one customer.

 Many transactions may belong to one account.
==============================================================================*/

RELATIONSHIPS (

    account_to_customer AS
        account (CUSTOMER_ID)
        REFERENCES customer (CUSTOMER_ID),

    transaction_to_account AS
        txn (ACCOUNT_ID)
        REFERENCES account (ACCOUNT_ID)

)


/*==============================================================================
 3. FACTS

 Facts represent row-level measurable values.
==============================================================================*/

FACTS (

    txn.transaction_amount
        AS txn.AMOUNT
        COMMENT = 'Monetary value of an individual transaction',

    account.account_balance
        AS account.BALANCE
        COMMENT = 'Current account balance'

)


/*==============================================================================
 4. DIMENSIONS

 Dimensions describe business entities and provide grouping/filtering context.
==============================================================================*/

DIMENSIONS (

    /* CUSTOMER */

    customer.customer_id
        AS customer.CUSTOMER_ID
        COMMENT = 'Unique customer identifier',

    customer.customer_name
        AS customer.CUSTOMER_NAME
        WITH SYNONYMS ('client name')
        COMMENT = 'Customer or organization name',

    customer.customer_type
        AS customer.CUSTOMER_TYPE
        COMMENT = 'Individual or organization',

    customer.customer_segment
        AS customer.CUSTOMER_SEGMENT
        WITH SYNONYMS ('segment')
        COMMENT = 'Commercial customer segment',

    customer.customer_risk_rating
        AS customer.RISK_RATING
        WITH SYNONYMS ('customer risk', 'risk rating')
        COMMENT = 'Customer-level risk classification',

    customer.customer_city
        AS customer.CITY
        COMMENT = 'Customer city',

    customer.customer_country
        AS customer.COUNTRY
        COMMENT = 'Customer country',


    /* ACCOUNT */

    account.account_id
        AS account.ACCOUNT_ID
        COMMENT = 'Unique bank account identifier',

    account.account_type
        AS account.ACCOUNT_TYPE
        WITH SYNONYMS ('type of account')
        COMMENT = 'Savings or current account',

    account.account_status
        AS account.ACCOUNT_STATUS
        COMMENT = 'Operational status of the account',

    account.currency
        AS account.CURRENCY
        COMMENT = 'Account currency',

    account.branch_code
        AS account.BRANCH_CODE
        COMMENT = 'Bank branch code',


    /* TRANSACTION */

    txn.transaction_id
        AS txn.TRANSACTION_ID
        WITH SYNONYMS ('transaction number', 'txn id')
        COMMENT = 'Unique transaction identifier',

    txn.transaction_timestamp
        AS txn.TRANSACTION_TS
        WITH SYNONYMS ('transaction time', 'transaction date')
        COMMENT = 'Timestamp when the transaction occurred',

    txn.transaction_type
        AS txn.TRANSACTION_TYPE
        COMMENT = 'Debit or credit transaction',

    txn.transaction_channel
        AS txn.CHANNEL
        WITH SYNONYMS ('payment channel', 'channel')
        COMMENT = 'Channel through which the transaction was executed',

    txn.transaction_country
        AS txn.COUNTRY
        COMMENT = 'Country associated with the transaction',

    txn.transaction_status
        AS txn.TRANSACTION_STATUS
        COMMENT = 'Processing status of the transaction',

    txn.transaction_risk_flag
        AS txn.RISK_FLAG
        WITH SYNONYMS ('risk flag', 'transaction risk')
        COMMENT = 'Transaction-level risk classification'

)


/*==============================================================================
 5. BUSINESS METRICS
==============================================================================*/

METRICS (

    txn.total_transaction_amount
        AS SUM(txn.transaction_amount)
        WITH SYNONYMS ('transaction value', 'total transaction value')
        COMMENT = 'Total monetary value of transactions',

    txn.transaction_count
        AS COUNT(*)
        WITH SYNONYMS ('number of transactions')
        COMMENT = 'Number of transactions',

    txn.average_transaction_amount
        AS AVG(txn.transaction_amount)
        WITH SYNONYMS ('average transaction value')
        COMMENT = 'Average monetary value per transaction',

    txn.high_risk_transaction_count
        AS COUNT_IF(txn.transaction_risk_flag = 'HIGH_RISK')
        COMMENT = 'Number of transactions classified as HIGH_RISK',

    account.total_account_balance
        AS SUM(account.account_balance)
        COMMENT = 'Total balance across accounts'

)

COMMENT =
'Governed banking semantic layer for the Snowflake Agent Scope Lighthouse'

AI_SQL_GENERATION
'Use customer, account and transaction relationships when answering banking
analytical questions. A transaction belongs to an account and an account
belongs to a customer. HIGH_RISK represents the highest transaction risk
classification. Do not infer facts that are not represented by the semantic
view.';


/*==============================================================================
 6. OBJECT VALIDATION
==============================================================================*/

SHOW SEMANTIC VIEWS
    LIKE 'BANKING_ANALYTICS'
    IN SCHEMA AGENT_SCOPE_LAB.SEMANTIC;


DESCRIBE SEMANTIC VIEW
    AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS;


/*==============================================================================
 7. METRIC VALIDATION

 Question:
 "What is the total transaction value by transaction risk?"
==============================================================================*/

SELECT *
FROM SEMANTIC_VIEW(
    AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

    DIMENSIONS
        txn.transaction_risk_flag

    METRICS
        txn.total_transaction_amount,
        txn.transaction_count
)
ORDER BY total_transaction_amount DESC;


/*==============================================================================
 8. RELATIONSHIP VALIDATION

 Question:
 "Which customers generated the highest transaction value?"

 This validates:

 CUSTOMER
     ↑
 ACCOUNT
     ↑
 TRANSACTION

 before Cortex Analyst is introduced.
==============================================================================*/

SELECT *
FROM SEMANTIC_VIEW(
    AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

    DIMENSIONS
        customer.customer_name,
        customer.customer_segment

    METRICS
        txn.total_transaction_amount,
        txn.transaction_count
)
ORDER BY total_transaction_amount DESC;


/*==============================================================================
 9. GOLDEN TRANSACTION VALIDATION

 We deliberately use TXN-9001 throughout the lighthouse.

 Expected:
     Transaction : TXN-9001
     Customer    : Neha Patel
     Account     : SA1003
     Risk        : HIGH_RISK
==============================================================================*/

SELECT *
FROM SEMANTIC_VIEW(
    AGENT_SCOPE_LAB.SEMANTIC.BANKING_ANALYTICS

    DIMENSIONS
        txn.transaction_id,
        customer.customer_name,
        account.account_id,
        txn.transaction_channel,
        txn.transaction_country,
        txn.transaction_risk_flag

    METRICS
        txn.total_transaction_amount

    WHERE txn.transaction_id = 'TXN-9001'
);


/*==============================================================================
 M3 PASS CRITERIA

 [ ] BANKING_ANALYTICS created successfully
 [ ] DESCRIBE SEMANTIC VIEW succeeds
 [ ] Semantic dimensions visible
 [ ] Semantic metrics visible
 [ ] Risk aggregation succeeds
 [ ] Customer → Account → Transaction relationship traversal succeeds
 [ ] TXN-9001 resolves to Neha Patel
 [ ] TXN-9001 resolves to SA1003
 [ ] TXN-9001 = HIGH_RISK
 [ ] TXN-9001 total transaction amount = 95,000

 Do NOT proceed to Cortex Agent until all tests pass.
==============================================================================*/