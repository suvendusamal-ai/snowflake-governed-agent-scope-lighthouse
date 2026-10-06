# Implementation Guide

## Snowflake Governed Agent Scope Lighthouse

This guide complements the root `README.md`. It focuses on reproducibility: environment preparation, non-human identity setup, connection separation, execution order, and the governance reason for each stage.

## 1. Execution identities

The lighthouse intentionally separates three execution contexts:

| Logical connection | Identity purpose |
|---|---|
| `CoCo_Oct` | administrative deployment and evidence collection |
| `CoCo_Agent_Consumer` | non-human `SERVICE` consumer |
| `CoCo_Agent_Autonomous` | autonomous `SERVICE_AGENT` |

Use equivalent names in your own environment.

Do not collapse these into one connection. Several tests depend on caller identity and effective authorization being different.

## 2. SERVICE versus SERVICE_AGENT

The exercise compares a normal non-human service identity with an Agent identity.

Representative pattern:

```sql
CREATE USER AGENT_SCOPE_TEST_USER
    TYPE = SERVICE
    DEFAULT_ROLE = AGENT_SCOPE_CONSUMER_ROLE
    RSA_PUBLIC_KEY = '<PUBLIC_KEY>';

GRANT ROLE AGENT_SCOPE_CONSUMER_ROLE
    TO USER AGENT_SCOPE_TEST_USER;

CREATE USER AGENT_SCOPE_AUTONOMOUS_USER
    TYPE = SERVICE_AGENT
    DEFAULT_ROLE = AGENT_SCOPE_AUTONOMOUS_ROLE
    RSA_PUBLIC_KEY = '<PUBLIC_KEY>';

GRANT ROLE AGENT_SCOPE_AUTONOMOUS_ROLE
    TO USER AGENT_SCOPE_AUTONOMOUS_USER;
```

Use `sql/08_agent_identity.sql` and `tests/setup_01_service_agent_identity.sql` as the repository source of truth for the lab's actual object setup.

The runtime distinction tested by the project is:

```sql
SELECT
    CURRENT_USER(),
    CURRENT_ROLE(),
    SYS_CONTEXT(
        'SNOWFLAKE$CURRENT',
        'IS_AGENT_ACTIVATED'
    )::BOOLEAN AS IS_AGENT_ACTIVATED;
```

Expected behavior established by the exercise:

```text
SERVICE       → IS_AGENT_ACTIVATED = FALSE
SERVICE_AGENT → IS_AGENT_ACTIVATED = TRUE
```

## 3. Key-pair authentication

The non-human identities should use key-pair authentication rather than embedding passwords in repository files.

High-level flow:

```text
Generate RSA key pair
        ↓
Protect private key locally
        ↓
Assign public key to Snowflake user
        ↓
Configure Snowflake CLI connection
        ↓
Validate identity
```

A representative OpenSSL pattern is:

```powershell
openssl genrsa -out agent_scope_private_key.pem 2048
openssl rsa -in agent_scope_private_key.pem -pubout -out agent_scope_public_key.pem
```

Convert the public key into the format required by your Snowflake user definition/configuration before assigning it.

> The exact local key-generation tooling is environment-specific. Never commit the private key.

## 4. Secret handling

The local lab uses:

```text
.secrets/
```

for key material.

At minimum:

```gitignore
.secrets/
*.pem
*.key
```

Before publishing:

```powershell
git status
git ls-files .secrets
```

The second command should return no tracked files.

If a secret was ever committed, adding it to `.gitignore` later is not sufficient; remove it from tracking/history and rotate exposed credentials as appropriate.

## 5. Configure Snowflake CLI connections

Configure three logical connections corresponding to the identities above.

Conceptually:

```text
CoCo_Oct
    └── administrative identity

CoCo_Agent_Consumer
    └── AGENT_SCOPE_TEST_USER
        TYPE = SERVICE
        ROLE = AGENT_SCOPE_CONSUMER_ROLE

CoCo_Agent_Autonomous
    └── AGENT_SCOPE_AUTONOMOUS_USER
        TYPE = SERVICE_AGENT
        ROLE = AGENT_SCOPE_AUTONOMOUS_ROLE
```

Keep account-specific connection configuration and private-key paths outside the Git repository.

Validate each connection before running governance tests.

## 6. Build sequence

### Foundation

```powershell
snow sql -c CoCo_Oct -f .\sql\00_setup.sql
snow sql -c CoCo_Oct -f .\sql\01_synthetic_banking_data.sql
snow sql -c CoCo_Oct -f .\sql\02_semantic_view.sql
```

### Agent lifecycle

```powershell
snow sql -c CoCo_Oct -f .\sql\03_temporary_agent.sql
snow sql -c CoCo_Oct -f .\sql\04_personal_agent.sql
snow sql -c CoCo_Oct -f .\tests\test_01_personal_agent_persistence.sql
snow sql -c CoCo_Oct -f .\sql\05_permanent_agent.sql
snow sql -c CoCo_Oct -f .\sql\06_secure_agent.sql
snow sql -c CoCo_Oct -f .\tests\test_02_secure_agent_consumer.sql
snow sql -c CoCo_Oct -f .\tests\test_03_secure_agent_secondary_roles.sql
snow sql -c CoCo_Oct -f .\tests\test_04_prepare_consumer_user.sql
snow sql -c CoCo_Agent_Consumer -f .\tests\test_05_secure_agent_consumer_invocation.sql
```

### COPY GRANTS

```powershell
snow sql -c CoCo_Oct -f .\sql\07_copy_grants.sql
snow sql -c CoCo_Oct -f .\tests\test_06_copy_grants_syntax.sql
```

### Identity

```powershell
snow sql -c CoCo_Oct -f .\sql\08_agent_identity.sql
snow sql -c CoCo_Oct -f .\tests\setup_01_service_agent_identity.sql
snow sql -c CoCo_Agent_Autonomous -f .\tests\test_07_service_agent_identity.sql
```

### Restricted Session Scope

```powershell
snow sql -c CoCo_Oct -f .\sql\09_restricted_session_scope.sql
snow sql -c CoCo_Oct -f .\tests\setup_02_rss_runtime_test.sql
snow sql -c CoCo_Agent_Autonomous -f .\tests\test_08_rss_runtime_enforcement.sql
snow sql -c CoCo_Agent_Autonomous -f .\tests\test_09_rss_prod_write_denied.sql
snow sql -c CoCo_Agent_Autonomous -f .\tests\test_10_rss_role_switch_denied.sql
```

### Agent-aware masking

```powershell
snow sql -c CoCo_Oct -f .\sql\10_agent_aware_masking.sql
snow sql -c CoCo_Agent_Consumer -f .\tests\test_11_agent_aware_masking_service.sql
snow sql -c CoCo_Agent_Autonomous -f .\tests\test_12_agent_aware_masking_service_agent.sql
```

### Governed custom action

```powershell
snow sql -c CoCo_Oct -f .\sql\11_agent_prod_read_sandbox_write.sql
snow sql -c CoCo_Oct -f .\sql\12_rss_controlled_action_tool.sql
snow sql -c CoCo_Oct -f .\sql\13_agent_controlled_action_tool.sql
```

### Runtime behavior

```powershell
snow sql -c CoCo_Agent_Autonomous -f .\sql\14_test_agent_sandbox.sql
snow sql -c CoCo_Agent_Autonomous -f .\sql\15_test_agent_prod.sql
snow sql -c CoCo_Agent_Autonomous -f .\sql\16_test_agent_prod_read.sql
```

### Graceful degradation comparison

```powershell
snow sql -c CoCo_Agent_Consumer -f .\sql\17_test_consumer_controlled_action.sql
snow sql -c CoCo_Agent_Autonomous -f .\sql\17_test_consumer_controlled_action.sql
```

### Lineage

```powershell
snow sql -c CoCo_Oct -f .\sql\18_agent_lineage.sql
```

### Evaluation summary

```powershell
snow sql -c CoCo_Oct -f .\sql\19_governance_evaluation.sql
```

## 7. Why the caller-rights procedure matters

The custom procedure uses:

```text
EXECUTE AS CALLER
```

This is an architectural control, not just an implementation choice.

It means the Agent tool does not silently bypass the caller's effective authorization by executing with owner authority.

The resulting model is:

```text
Agent Tool Configuration
       ∩
Caller Authorization
       ∩
Restricted Session Scope / downstream governance
       =
Effective Tool Execution
```

## 8. Controlled runtime scenarios

### Production read

Expected:

```text
BANKING_SECURE_AGENT
      ↓
BankingAnalyst
      ↓
BANKING_ANALYTICS
      ↓
production banking data
```

### Sandbox write

Expected:

```text
BANKING_SECURE_AGENT
      ↓
ControlledUpdate
      ↓
RSS_CONTROLLED_UPDATE
      ↓
SANDBOX
      ↓
success
```

### Production write

Expected:

```text
BANKING_SECURE_AGENT
      ↓
ControlledUpdate
      ↓
RSS_CONTROLLED_UPDATE
      ↓
PROD UPDATE
      ↓
RSS
      ↓
DENIED
```

The denial is meaningful because underlying RBAC was deliberately configured with production `UPDATE`; RSS narrows the effective session authority.

## 9. Graceful degradation

The consumer caller can still use the Agent's analytical capability after the baseline data privileges are present, but does not have equivalent authorization for the controlled procedure.

Observed controlled-action behavior:

```text
tool configured
      ↓
tool selected
      ↓
execution unavailable to caller
      ↓
tool error
      ↓
Agent reports failure
      ↓
no fabricated success
```

Do not describe this as dynamic tool removal or filtering. The tested tool remained visible/selectable.

## 10. Lineage evidence

Run:

```powershell
snow sql -c CoCo_Oct -f .\sql\18_agent_lineage.sql
```

The tested native object lineage includes:

```text
TABLE → SEMANTIC_VIEW → CORTEX_AGENT
```

and downstream impact analysis from the Semantic View to dependent Cortex Agents.

Boundaries observed during testing:

- `PROCEDURE` was not a supported `GET_LINEAGE` domain in the tested call.
- column-level Semantic View lineage rows were not observed.

Therefore procedure-backed tool dependencies are documented using configuration and runtime evidence rather than being labeled native lineage.

## 11. Runtime evidence versus persistent telemetry

The `DATA_AGENT_RUN` responses captured useful execution evidence such as:

- tool selection;
- tool input;
- generated SQL;
- tool result;
- success/error;
- query identifier where available;
- final response.

The account event destination was also inspected:

```text
snowflake.telemetry.events
```

No Agent records were observed during the tested time window. Do not claim persistent event-table telemetry for this exercise.

## 12. Completion criteria

The lighthouse is complete when all of the following are reproducibly demonstrated:

- governed semantic production read;
- `SERVICE` versus `SERVICE_AGENT` runtime distinction;
- RSS sandbox-write/production-write boundary;
- Agent-aware masking;
- caller-rights controlled action;
- safe failure under reduced tool authorization;
- native `TABLE → SEMANTIC_VIEW → CORTEX_AGENT` lineage;
- deterministic governance evaluation;
- repository contains no secrets.
