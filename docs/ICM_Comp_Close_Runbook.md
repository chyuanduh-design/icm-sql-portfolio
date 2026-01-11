# Incentive Compensation Close Runbook

**Owner:** Incentive Compensation Systems Engineer  
**Last Updated:** 2026-01-07  
**Systems:** Salesforce, HRIS, Billing/Usage, ICM, Payroll  
**Audience:** RevOps, Finance, Accounting, Payroll, Data Engineering

---

## 1. Purpose & Success Criteria

### Purpose

Define the repeatable process for executing an accurate, auditable incentive compensation close while protecting payroll timelines.

### Success Criteria

- Inputs snapshotted at cutoff
- Calculations reproducible
- Reconciliations completed and signed off
- No silent recalculations after lock
- All post-close changes handled via adjustments

---

## 2. Close Calendar (T-7 → T+3)

| Day | Phase      | Key Activities                      | Owner        |
| --- | ---------- | ----------------------------------- | ------------ |
| T-7 | Readiness  | Confirm calendar, freeze plan logic | ICM          |
| T-5 | Validation | Run blocking validations            | ICM / RevOps |
| T-2 | Go / No-Go | Resolve blockers                    | ICM          |
| T-1 | Snapshot   | Lock inputs                         | ICM          |
| T-0 | Calculate  | Run calc + reconcile                | ICM          |
| T+1 | Sign-off   | Finance approval                    | Finance      |
| T+2 | Payroll    | Deliver payout file                 | Payroll      |
| T+3 | Post-close | Open adjustments                    | ICM          |

### 2.1 Go/ No-Go Decision

The ICM Owner makes the final Go / No-Go decision based on:

- All blocking validations passing (§4.1)
- No unresolved material issues (§4.3)
- Finance acknowledgement of known non-blocking items

If criteria are not met, close is delayed and escalated.

---

## 3. Lock Rules (Hard Constraints)

Once inputs are locked:

- ❌ No source reloads
- ❌ No plan logic changes
- ❌ No recalculation of closed periods

Allowed after lock:

- ✅ Explicit adjustment transactions
- ✅ Documented true-ups with approval
- ✅ Auditable overrides

---

## 4. Pre-Close Validations

### 4.1 Blocking Validations (Must Pass)

1. Closed-won opps missing required lines/splits
   Threshold:
   0 Closed/won opportunities missing required lines and splits
   Rationale:
   Incomplete opportunities create irreconcilable credits
   Action:
   Quarantine affected opportunities
   Escalate to RevOps
   Re-snapshot after fix

2. Opportunity Split percentages ≠ 100%
   Threshold:
   Split % total must equal 100.000% ± 0.01% per Opportunity per SplitType
   Rationale:
   Even small drift breaks audit defensibility
   Action:
   Block run
   Require upstream correction
   No rounding fixes inside ICM

3. Overlapping territory or role effective dates
   Threshold:
   0 overlapping effective periods per Rep per payment period
   Rationale:
   Overlaps invalidate credit attribution / may result in double crediting and overpayment
   Action:
   Block close
   Confirm with HR on role effective dates
   HR / RevOps must correct source system

4. Rep missing HRIS EmployeeId
   Threshold:
   100% of credited reps must map to an active HRIS EmployeeId
   Rationale:
   Payroll cannot pay unmapped participants nor apply appropriate comp plan logic
   Action:
   Exclude impacted reps
   Log exception
   Adjust post-close once mapping fixed

---

### 4.2 Non-Blocking (Flag & Log)

1. Late Usage / Billing Data
   Threshold:
   Usage lag ≤ 48 hours
   Estimated missing usage ≤ 1.0% of period earnings
   Rationale:
   Consumption data naturally lags
   Action:
   Proceed with close
   Create adjustment in next cycle

2. Retro HR Changes (Non-Material)
   Threshold:
   Retro impact ≤ $500 per rep AND ≤ 0.5% of rep payout
   Rationale:
   Avoid constant recalculation churn
   Action:
   Adjustment next cycle

---

### 4.3 Materiality Rule

Any issue becomes blocking if:
Total impact >=$10,000 OR
Impact > 2% of total payout, OR
Affects VP+ plan participants

This rule overrides all other rules

---

## 5. Calculation Execution

1. Confirm inputs are locked
2. Execute ICM calculation run
   - Record run ID, timestamp, and model version
3. Validate run completion
4. Freeze calculation outputs
5. Proceed to reconciliation

---

## 6. Reconciliation Spine

The objective of reconciliation is to ensure that compensation results are
**complete, accurate, and explainable** from source transaction through payroll.

Reconciliation is performed **every close**, for the closed compensation period,
using snapshotted inputs.

---

### 6.1 Reconciliation Flow (End-to-End)

Reconcile in strict sequence. Do not skip steps.

| Stage         | Description                                         | Control Total                       | Owner    | Action if Variance                 |
| ------------- | --------------------------------------------------- | ----------------------------------- | -------- | ---------------------------------- |
| SFDC Bookings | Authoritative closed-won bookings for the period    | Sum of Amount (or line-level total) | RevOps   | Investigate source data            |
| Staged Data   | Transactions successfully loaded to staging         | Sum of staged amount                | Data Eng | Re-run pipeline / backfill         |
| Credited      | Amount allocated to reps after splits & eligibility | Sum of credited amount              | ICM      | Validate split & eligibility logic |
| Earned        | Commission calculated per plan rules                | Sum of earnings                     | ICM      | Validate rate tables & plan logic  |
| Paid          | Final payout delivered to Payroll                   | Sum of payout file                  | Payroll  | Validate payout mapping            |

---

### 6.2 Control Rules

- Each stage must reconcile **to the immediately preceding stage**
- Reconciliation is performed at:
  - Aggregate level (total dollars)
  - Optional drill-down (rep / plan / component) when variances exist
- All control totals are recorded and retained per close period
- Reconcilation is performed on snapshotted data only; live source data is not used post-lock

---

### 6.3 Variance Classification

All variances must fall into **one of the categories below**.

#### Acceptable (Documented)

- FX rounding differences within tolerance
- Timing differences due to approved lag (e.g., usage)
- Known plan mechanics (caps, thresholds, floors)

#### Investigate (Before Sign-Off)

- Unexpected drop between staged and credited
- Credit allocated to inactive or excluded reps
- Earnings inconsistent with plan design

#### Blocking

- Unexplainable variance at any stage
- Variance exceeding materiality thresholds (§4.3)
- Mismatch between Earned and Paid totals

---

### 6.4 Materiality Guidance

Unless otherwise approved by Finance:

- Aggregate variance ≤ **0.05% of total payout** may proceed with documentation
- Any variance:
  - > **$10,000**, OR
  - > **2% of total payout**, OR
  - Affecting **VP+ participants**

Becomes **blocking** and requires resolution before sign-off.

---

### 6.5 Sign-Off Requirements

Compensation close is not considered complete until:

- All reconciliation steps are completed
- All variances are explained or resolved
- Finance provides explicit approval of accrual totals

Sign-off is recorded with:

- Close period
- Timestamp
- Approver

---

### 6.6 Audit Principle

> If a number cannot be reconciled, it cannot be paid.

All reconciliation artifacts must allow the close to be:

- Re-run
- Re-explained
- Re-audited

---

## 7. Failure Handling Matrix

| Scenario               | Block? | Action                   | Owner  |
| ---------------------- | ------ | ------------------------ | ------ |
| Split totals ≠ 100%    | Yes    | Fix source & re-snapshot | RevOps |
| HRIS effective overlap | Yes    | Correct HRIS             | HR     |
| Late usage             | No     | Adjustment               | ICM    |
| Retro territory change | No     | Adjustment only          | ICM    |
| Rep dispute            | No     | Investigate & explain    | ICM    |

---

## 8. Adjustment Workflow

All post-close changes must:

- Be logged with reason code
- Receive Finance approval
- Be processed in next cycle
- Retain full audit trail

No exceptions.

---

## 9. Roles & Escalation

| Role             | Responsibility                   |
| ---------------- | -------------------------------- |
| ICM Owner        | Close authority & decisions      |
| RevOps           | Source definitions & correctness |
| Data Engineering | Pipeline execution & monitoring  |
| Finance          | Accrual & audit sign-off         |
| Payroll          | Payout execution                 |

Escalate before payroll risk.

---

## 10. Appendix

### A. Validation Queries (Optional)

- Split total checks
- Effective dating overlap checks

### B. Example Adjustment Log

- Period
- Rep
- Reason
- Amount
- Approval
- Approved by
- Approved date

---
