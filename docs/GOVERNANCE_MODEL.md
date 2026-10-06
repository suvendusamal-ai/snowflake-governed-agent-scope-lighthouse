# Governance Model

## Snowflake Governed Agent Scope Lighthouse

## 1. Architectural thesis

The lighthouse is built around one principle:

> **Human authority ≠ Delegated Agent authority**

An enterprise Agent should not automatically inherit every capability available to the surrounding user, role, application, or platform context.

The demonstrated model is:

```text
Effective Agent Authority
    =
RBAC
∩ Restricted Session Scope
∩ Agent-Aware Data Policy
∩ Tool Authorization
```

Each term controls a different dimension of authority.

## 2. Control-plane model

```text
                         USER / APPLICATION
                                │
                                ▼
                         CORTEX AGENT
                                │
                  ┌─────────────┴─────────────┐
                  ▼                           ▼
           Analytical Tool              Action Tool
                  │                           │
                  ▼                           ▼
           Semantic View             EXECUTE AS CALLER
                  │                           │
                  └─────────────┬─────────────┘
                                ▼
                     GOVERNANCE CONTROL PLANE

                 ┌───────────────────────────────┐
                 │ RBAC                          │
                 │ Restricted Session Scope      │
                 │ Agent Identity                │
                 │ Agent-Aware Data Protection   │
                 │ Tool Authorization            │
                 └───────────────────────────────┘
                                │
                                ▼
                     EFFECTIVE AGENT AUTHORITY
                                │
                                ▼
                   GOVERNANCE EVIDENCE LAYER

                    Lineage → Trace → Evaluation
```

## 3. RBAC: base authorization

RBAC establishes the underlying privileges available to a caller.

The RSS test deliberately grants the autonomous role production `UPDATE` capability at the RBAC layer. That makes the negative test meaningful:

```text
RBAC permits UPDATE
        +
RSS excludes UPDATE
        =
effective UPDATE denied
```

Without the underlying RBAC grant, a failed update would not prove RSS was the constraining control.

## 4. Restricted Session Scope: delegated session boundary

Restricted Session Scope narrows what an Agent-active session can do.

The tested contract is:

```text
Production READ     → allowed
Sandbox WRITE       → allowed
Production WRITE    → denied
Elevated role switch → denied
```

The central interpretation is:

```text
Effective Agent Permission = RBAC ∩ Restricted Session Scope
```

RSS is therefore a delegated-authority control rather than merely another role definition.

## 5. Agent identity

The project uses two non-human identity types:

```text
SERVICE
   └── IS_AGENT_ACTIVATED = FALSE

SERVICE_AGENT
   └── IS_AGENT_ACTIVATED = TRUE
```

The runtime signal is:

```sql
SYS_CONTEXT(
    'SNOWFLAKE$CURRENT',
    'IS_AGENT_ACTIVATED'
)::BOOLEAN
```

This signal is used by the data-protection exercise to distinguish ordinary service access from Agent-active access.

## 6. Agent-aware data protection

Authorization to access an object and disclosure of every value in that object are different governance decisions.

The tested masking policy retains access to the governed interface while reducing sensitive disclosure when the session is Agent-active.

Observed model:

```text
SERVICE
    ↓
same protected interface
    ↓
raw email

SERVICE_AGENT
    ↓
same protected interface
    ↓
***AGENT-MASKED***
```

Therefore:

```text
Effective Data Disclosure
    =
Authorized Access
∩ Agent-Aware Data Policy
```

This supports a useful enterprise principle:

> An Agent can remain authorized to query a data interface while sensitive data disclosed to that Agent is reduced according to runtime context.

## 7. Governed tools

The final secure Agent contains:

```text
BANKING_SECURE_AGENT
├── BankingAnalyst
└── ControlledUpdate
```

`BankingAnalyst` accesses structured data through the Semantic View.

`ControlledUpdate` invokes a stored procedure using:

```text
EXECUTE AS CALLER
```

This prevents the procedure from becoming an implicit owner-rights elevation path.

The effective execution model is:

```text
Effective Tool Execution
    =
Agent Tool Configuration
∩ Caller Tool Authorization
∩ Downstream Governance
```

## 8. Instructions are not the security boundary

Agent instructions can guide behavior, but the critical production-write test does not rely on an instruction such as:

```text
Do not modify production.
```

Instead:

```text
Agent selects action
      ↓
procedure attempts production UPDATE
      ↓
Snowflake evaluates effective authority
      ↓
RSS denies UPDATE
      ↓
production state remains unchanged
```

This is stronger than prompt-only enforcement because the authorization boundary exists outside the model's reasoning.

## 9. Graceful capability degradation

The same configured Agent was tested from two caller contexts.

The restricted consumer could successfully use the analytical path after the required data privileges were established.

For the controlled action, the tool remained configured and selectable, but the underlying routine could not execute for that caller.

The Agent surfaced the failure and did not fabricate successful completion.

This demonstrates:

> Loss of one governed capability does not necessarily make the entire Agent unusable.

It does **not** demonstrate that Snowflake dynamically removed the unauthorized tool from the Agent.

## 10. Evidence architecture

### Native lineage

Native Snowflake lineage proved:

```text
DATA.ACCOUNT ──────┐
DATA.CUSTOMER ─────┼──> BANKING_ANALYTICS ──> BANKING_SECURE_AGENT
DATA.TRANSACTION ──┘       SEMANTIC_VIEW          CORTEX_AGENT
```

The Agent upstream query also returned source tables transitively through the Semantic View.

Downstream lineage from the Semantic View identified dependent Cortex Agents, enabling impact-analysis questions such as:

- What data does this Agent depend on?
- Which Agents are affected if this Semantic View changes?

### Configuration evidence

The relationship:

```text
CORTEX_AGENT → ControlledUpdate → RSS_CONTROLLED_UPDATE
```

is supported by Agent configuration.

It is not presented as native procedure lineage because `GET_LINEAGE` with `PROCEDURE` was unsupported in the tested call.

### Runtime evidence

`DATA_AGENT_RUN` results demonstrated:

- routing/tool selection;
- tool input;
- generated analytical SQL;
- tool execution result;
- success/error;
- query ID where returned;
- final Agent response.

Runtime evidence answers a different question from lineage:

```text
Lineage → what depends on what?
Runtime → what happened in this invocation?
```

### Evaluation

The final evaluation contract records four tested governance outcomes:

1. grounded production investigation;
2. authorized sandbox action;
3. production action denied by RSS;
4. restricted consumer action fails without fabricated success.

## 11. Tested boundaries

The project intentionally records boundaries rather than filling them with assumptions.

### Procedure lineage

Observed:

```text
Unsupported domain: PROCEDURE
```

for the tested `GET_LINEAGE` call.

Therefore no native `PROCEDURE → CORTEX_AGENT` lineage claim is made.

### Column-level Semantic View lineage

No column-level rows were observed in the tested Semantic View lineage query.

Therefore no column-level lineage claim is made.

### Event-table telemetry

The configured destination:

```text
snowflake.telemetry.events
```

was queried for recent events and returned no data for the tested window.

Therefore the project does not claim persistent Cortex Agent telemetry in the event table.

## 12. Enterprise interpretation

The lighthouse demonstrates that Agent governance should be layered:

```text
Who is the caller?
        ↓
What does RBAC permit?
        ↓
What is delegated to the Agent session?
        ↓
What data may be disclosed?
        ↓
Which configured tools can actually execute?
        ↓
What evidence proves the behavior?
```

This moves Agent security away from a binary "can invoke Agent / cannot invoke Agent" model toward explicit delegated authority and evidence-backed governance.
