/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 01_synthetic_banking_data.sql
 Purpose : Create deterministic synthetic banking data used to demonstrate
           Cortex Agent lifecycle, governance and runtime security boundaries.

 IMPORTANT:
   All names, emails, accounts and transactions are synthetic.
==============================================================================*/

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AGENT_SCOPE_WH;
USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA DATA;


/*==============================================================================
 1. CUSTOMER
==============================================================================*/

CREATE OR REPLACE TABLE CUSTOMER (
    CUSTOMER_ID       VARCHAR(20)  NOT NULL,
    CUSTOMER_NAME     VARCHAR(100) NOT NULL,
    CUSTOMER_TYPE     VARCHAR(20)  NOT NULL,
    CUSTOMER_SEGMENT  VARCHAR(30),
    EMAIL             VARCHAR(150),
    PHONE             VARCHAR(30),
    CITY              VARCHAR(50),
    COUNTRY           VARCHAR(50),
    RISK_RATING       VARCHAR(20),
    CREATED_DATE      DATE,
    CONSTRAINT PK_CUSTOMER PRIMARY KEY (CUSTOMER_ID)
);

INSERT INTO CUSTOMER VALUES
('C001','Aarav Sharma','INDIVIDUAL','PREMIUM',
 'aarav.sharma@example.com','+91-9000000001',
 'Bengaluru','India','LOW','2024-01-10'),

('C002','Priya Nair','INDIVIDUAL','RETAIL',
 'priya.nair@example.com','+91-9000000002',
 'Kochi','India','LOW','2024-02-15'),

('C003','Rohan Mehta','INDIVIDUAL','PREMIUM',
 'rohan.mehta@example.com','+91-9000000003',
 'Mumbai','India','MEDIUM','2024-03-05'),

('C004','Neha Patel','INDIVIDUAL','RETAIL',
 'neha.patel@example.com','+91-9000000004',
 'Ahmedabad','India','HIGH','2024-04-12'),

('C005','Orion Retail Pvt Ltd','ORGANIZATION','CORPORATE',
 'finance@orion-retail.example.com','+91-8000000005',
 'Bengaluru','India','MEDIUM','2024-05-01');


/*==============================================================================
 2. ACCOUNT
==============================================================================*/

CREATE OR REPLACE TABLE ACCOUNT (
    ACCOUNT_ID       VARCHAR(20)  NOT NULL,
    CUSTOMER_ID      VARCHAR(20)  NOT NULL,
    ACCOUNT_TYPE     VARCHAR(30)  NOT NULL,
    ACCOUNT_STATUS   VARCHAR(20)  NOT NULL,
    BALANCE          NUMBER(18,2),
    CURRENCY         VARCHAR(10),
    BRANCH_CODE      VARCHAR(20),
    OPEN_DATE        DATE,
    CONSTRAINT PK_ACCOUNT PRIMARY KEY (ACCOUNT_ID)
);

INSERT INTO ACCOUNT VALUES
('SA1001','C001','SAVINGS','ACTIVE',125000.00,'INR','BLR001','2024-01-15'),
('SA1002','C002','SAVINGS','ACTIVE', 85000.00,'INR','KOC001','2024-02-20'),
('CA2001','C003','CURRENT','ACTIVE',450000.00,'INR','MUM001','2024-03-10'),
('SA1003','C004','SAVINGS','ACTIVE', 35000.00,'INR','AMD001','2024-04-15'),
('CA2002','C005','CURRENT','ACTIVE',925000.00,'INR','BLR002','2024-05-05');


/*==============================================================================
 3. TRANSACTION
==============================================================================*/

CREATE OR REPLACE TABLE TRANSACTION (
    TRANSACTION_ID    VARCHAR(30) NOT NULL,
    ACCOUNT_ID        VARCHAR(20) NOT NULL,
    TRANSACTION_TS    TIMESTAMP_NTZ,
    TRANSACTION_TYPE  VARCHAR(20),
    AMOUNT            NUMBER(18,2),
    CURRENCY          VARCHAR(10),
    CHANNEL           VARCHAR(30),
    MERCHANT          VARCHAR(100),
    COUNTRY           VARCHAR(50),
    TRANSACTION_STATUS VARCHAR(20),
    RISK_FLAG          VARCHAR(20),
    CONSTRAINT PK_TRANSACTION PRIMARY KEY (TRANSACTION_ID)
);

INSERT INTO TRANSACTION VALUES
('TXN-1001','SA1001','2026-09-01 09:15:00','DEBIT',
 5000,'INR','UPI','Retail Store','India','SUCCESS','NORMAL'),

('TXN-1002','SA1001','2026-09-03 14:20:00','DEBIT',
 12000,'INR','CARD','Electronics Store','India','SUCCESS','NORMAL'),

('TXN-1003','SA1002','2026-09-05 10:10:00','DEBIT',
 2500,'INR','UPI','Grocery Store','India','SUCCESS','NORMAL'),

('TXN-1004','CA2001','2026-09-07 11:30:00','DEBIT',
 75000,'INR','NEFT','Vendor Payment','India','SUCCESS','NORMAL'),

('TXN-1005','SA1003','2026-09-09 23:45:00','DEBIT',
 30000,'INR','CARD','Online Merchant','Singapore','SUCCESS','REVIEW'),

('TXN-1006','CA2002','2026-09-11 12:00:00','DEBIT',
 150000,'INR','RTGS','Supplier Payment','India','SUCCESS','NORMAL'),

('TXN-9001','SA1003','2026-09-15 02:14:00','DEBIT',
 95000,'INR','INTERNATIONAL_TRANSFER',
 'Unknown Beneficiary','Unknown','SUCCESS','HIGH_RISK'),

('TXN-9002','CA2001','2026-09-17 03:25:00','DEBIT',
 180000,'INR','INTERNATIONAL_TRANSFER',
 'Overseas Vendor','Unknown','SUCCESS','REVIEW'),

('TXN-1007','SA1001','2026-09-20 16:30:00','CREDIT',
 50000,'INR','NEFT','Salary Credit','India','SUCCESS','NORMAL'),

('TXN-1008','CA2002','2026-09-22 10:45:00','CREDIT',
 275000,'INR','RTGS','Customer Settlement','India','SUCCESS','NORMAL');


/*==============================================================================
 4. FRAUD INVESTIGATION CASE

 This becomes useful later for:
   - Agent reasoning
   - Restricted writes
   - sandbox investigation
   - high-risk transaction questions
==============================================================================*/

CREATE OR REPLACE TABLE FRAUD_CASE (
    CASE_ID             VARCHAR(30) NOT NULL,
    TRANSACTION_ID      VARCHAR(30) NOT NULL,
    CASE_STATUS         VARCHAR(30),
    PRIORITY            VARCHAR(20),
    ASSIGNED_TEAM       VARCHAR(50),
    INVESTIGATION_NOTE  VARCHAR(500),
    CREATED_TS          TIMESTAMP_NTZ,
    CONSTRAINT PK_FRAUD_CASE PRIMARY KEY (CASE_ID)
);

INSERT INTO FRAUD_CASE VALUES
(
 'CASE-9001',
 'TXN-9001',
 'OPEN',
 'HIGH',
 'FINANCIAL_CRIME',
 'International transfer materially exceeds the account balance profile; manual review required.',
 '2026-09-15 03:00:00'
);


/*==============================================================================
 5. CONTROLLED SANDBOX WRITE TARGET

 IMPORTANT:
 This is intentionally outside DATA.

 Later RSS testing should prove:

       DATA     → READ allowed / WRITE denied
       SANDBOX  → READ allowed / WRITE allowed
==============================================================================*/

CREATE OR REPLACE TABLE AGENT_SCOPE_LAB.SANDBOX.INVESTIGATION_NOTE (
    NOTE_ID         VARCHAR(30),
    TRANSACTION_ID  VARCHAR(30),
    AGENT_NAME      VARCHAR(100),
    NOTE_TEXT       VARCHAR(1000),
    CREATED_BY      VARCHAR(100),
    CREATED_TS      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


/*==============================================================================
 6. VALIDATION
==============================================================================*/

SELECT 'CUSTOMER' AS OBJECT_NAME, COUNT(*) AS ROW_COUNT
FROM CUSTOMER

UNION ALL

SELECT 'ACCOUNT', COUNT(*)
FROM ACCOUNT

UNION ALL

SELECT 'TRANSACTION', COUNT(*)
FROM TRANSACTION

UNION ALL

SELECT 'FRAUD_CASE', COUNT(*)
FROM FRAUD_CASE

UNION ALL

SELECT 'SANDBOX.INVESTIGATION_NOTE', COUNT(*)
FROM AGENT_SCOPE_LAB.SANDBOX.INVESTIGATION_NOTE
;


/*==============================================================================
 7. BUSINESS VALIDATION QUERY

 Expected high-risk transaction:
      TXN-9001
      Neha Patel
      SA1003
      95,000 INR
      HIGH_RISK
==============================================================================*/

SELECT
    T.TRANSACTION_ID,
    C.CUSTOMER_NAME,
    C.CUSTOMER_SEGMENT,
    C.RISK_RATING,
    A.ACCOUNT_ID,
    A.ACCOUNT_TYPE,
    T.AMOUNT,
    T.CHANNEL,
    T.COUNTRY,
    T.RISK_FLAG
FROM TRANSACTION T
JOIN ACCOUNT A
    ON T.ACCOUNT_ID = A.ACCOUNT_ID
JOIN CUSTOMER C
    ON A.CUSTOMER_ID = C.CUSTOMER_ID
WHERE T.RISK_FLAG = 'HIGH_RISK';


/*==============================================================================
 EXPECTED COUNTS

 CUSTOMER                     5
 ACCOUNT                      5
 TRANSACTION                 10
 FRAUD_CASE                   1
 SANDBOX.INVESTIGATION_NOTE   0

 M2 PASS criteria:

 [ ] All four DATA tables created
 [ ] Sandbox investigation table created
 [ ] Row counts match
 [ ] TXN-9001 resolves to Neha Patel
 [ ] TXN-9001 amount = 95,000 INR
 [ ] TXN-9001 risk flag = HIGH_RISK
==============================================================================*/    