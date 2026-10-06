/*==============================================================================
 Project : Snowflake Governed Agent Scope Lighthouse
 File    : 00_setup.sql
 Purpose : Establish the base Snowflake environment for demonstrating
           governed Cortex Agent lifecycle and runtime scope.

 Architecture capabilities eventually demonstrated:
   1. Temporary Cortex Agent
   2. Personal Database Agent
   3. Permanent Cortex Agent
   4. Secure Cortex Agent
   5. COPY GRANTS
   6. Agent Identity
   7. Agent-aware governance policies
   8. Restricted Session Scope (RSS)
   9. Graceful tool-access degradation
  10. Cortex Agent lineage
  11. AI Observability

 NOTE:
   ACCOUNTADMIN is used only for bootstrap activities.
   Agent runtime will NOT use ACCOUNTADMIN.
==============================================================================*/


-- ============================================================================
-- 0. BOOTSTRAP CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;


-- ============================================================================
-- 1. COMPUTE
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS AGENT_SCOPE_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute warehouse for Governed Agent Scope Lighthouse';

USE WAREHOUSE AGENT_SCOPE_WH;


-- ============================================================================
-- 2. DATABASE
-- ============================================================================

CREATE DATABASE IF NOT EXISTS AGENT_SCOPE_LAB
    COMMENT = 'Governed Snowflake Cortex Agent Scope Lighthouse';

USE DATABASE AGENT_SCOPE_LAB;


-- ============================================================================
-- 3. SCHEMA LAYERS
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS DATA
    COMMENT = 'Synthetic production-style banking data';

CREATE SCHEMA IF NOT EXISTS SEMANTIC
    COMMENT = 'Semantic views and analytical definitions';

CREATE SCHEMA IF NOT EXISTS AGENTS
    COMMENT = 'Shared and production Cortex Agents';

CREATE SCHEMA IF NOT EXISTS SANDBOX
    COMMENT = 'Controlled write area for agent experiments';

CREATE SCHEMA IF NOT EXISTS GOVERNANCE
    COMMENT = 'Agent governance policies and security controls';

CREATE SCHEMA IF NOT EXISTS OBSERVABILITY
    COMMENT = 'Evidence and observability artifacts';


-- ============================================================================
-- 4. DEFAULT DEVELOPMENT CONTEXT
-- ============================================================================

USE DATABASE AGENT_SCOPE_LAB;
USE SCHEMA DATA;


-- ============================================================================
-- 5. VALIDATION
-- ============================================================================

SELECT
    CURRENT_ACCOUNT()   AS ACCOUNT_NAME,
    CURRENT_USER()      AS CURRENT_USER,
    CURRENT_ROLE()      AS CURRENT_ROLE,
    CURRENT_DATABASE()  AS CURRENT_DATABASE,
    CURRENT_SCHEMA()    AS CURRENT_SCHEMA,
    CURRENT_WAREHOUSE() AS CURRENT_WAREHOUSE;


SHOW SCHEMAS IN DATABASE AGENT_SCOPE_LAB;

SHOW WAREHOUSES LIKE 'AGENT_SCOPE_WH';


-- ============================================================================
-- EXPECTED RESULT
-- ============================================================================
--
-- Current context:
--
--   ROLE       : ACCOUNTADMIN
--   DATABASE   : AGENT_SCOPE_LAB
--   SCHEMA     : DATA
--   WAREHOUSE  : AGENT_SCOPE_WH
--
-- Expected application schemas:
--
--   DATA
--   SEMANTIC
--   AGENTS
--   SANDBOX
--   GOVERNANCE
--   OBSERVABILITY
--
-- INFORMATION_SCHEMA will also exist automatically.
--
-- IMPORTANT:
-- ACCOUNTADMIN is intentionally being used only during bootstrap.
-- Later files will establish separate development/runtime roles and demonstrate
-- that agent authority can be narrower than the human user's authority.
-- ============================================================================