-- =====================================================
-- SEED DATA (INTENTIONALLY INCLUDES FAILURES)
-- Goal: validations should catch real-world break cases
-- =====================================================

-- Clean slate for repeatable runs
DELETE FROM SF_Opportunity_raw;
DELETE FROM SF_Split_raw;
DELETE FROM HR_Employee_raw;
DELETE FROM Billing_Invoice_raw;
DELETE FROM UsageEvent_raw;

DELETE FROM CompPeriod_dim;
DELETE FROM Rep_dim;
DELETE FROM Opportunity_fact;
DELETE FROM Split_fact;

-- Comp periods (example: Jan 2026)
INSERT INTO CompPeriod_dim (comp_period_id, period_start, period_end, lock_ts)
VALUES
  ('2026-01', DATE '2026-01-01', DATE '2026-01-31', NULL);

-- HR employees
INSERT INTO HR_Employee_raw (employee_id, rep_id, active_flag, hire_date, termination_date)
VALUES
  ('E001', 'R001', TRUE,  DATE '2024-01-15', NULL),
  ('E002', 'R002', FALSE, DATE '2023-06-01', DATE '2025-12-15');  -- inactive rep

-- SF opportunities (2 closed won)
INSERT INTO SF_Opportunity_raw (oppty_id, account_id, stage_name, close_date, amount, currency, is_closed_won)
VALUES
  ('O100', 'A10', 'Closed Won', DATE '2026-01-10', 100000, 'USD', TRUE),
  ('O200', 'A20', 'Closed Won', DATE '2026-01-20', 200000, 'USD', TRUE);

-- SF splits
-- O100: good splits = 100%
-- O200: bad splits = 90% (should be caught)
INSERT INTO SF_Split_raw (oppty_id, rep_id, split_type, split_pct)
VALUES
  ('O100', 'R001', 'Revenue', 60.0),
  ('O100', 'R002', 'Revenue', 40.0),
  ('O200', 'R001', 'Revenue', 50.0),
  ('O200', 'R002', 'Revenue', 40.0);

-- Billing invoices
-- duplicate natural key (invoice_line_id) should be caught
INSERT INTO Billing_Invoice_raw (invoice_line_id, customer_external_id, invoice_date, amount, currency)
VALUES
  ('INV-L1', 'CUST-001', DATE '2026-01-05', 5000, 'USD'),
  ('INV-L1', 'CUST-001', DATE '2026-01-05', 5000, 'USD'); -- duplicate

-- Usage events
-- unmapped customer_external_id example (should be caught once you add Account mapping later)
INSERT INTO UsageEvent_raw (usage_event_id, customer_external_id, usage_date, usage_amount)
VALUES
  ('U1', 'CUST-999', DATE '2026-01-12', 123.45);

-- -----------------------------------------------------
-- Curate minimal dims/facts (simple example transforms)
-- -----------------------------------------------------

-- Rep_dim from HR (in real life you'd also join SF user mapping)
INSERT INTO Rep_dim (rep_id, employee_id, active_flag, hire_date, termination_date)
SELECT rep_id, employee_id, active_flag, hire_date, termination_date
FROM HR_Employee_raw;

-- Opportunity_fact scoped to comp period by close_date
INSERT INTO Opportunity_fact (oppty_id, account_id, close_date, amount, currency, comp_period_id)
SELECT
  o.oppty_id,
  o.account_id,
  o.close_date,
  o.amount,
  o.currency,
  '2026-01' AS comp_period_id
FROM SF_Opportunity_raw o
WHERE o.is_closed_won = TRUE
  AND o.close_date BETWEEN DATE '2026-01-01' AND DATE '2026-01-31';

-- Split_fact scoped to same comp period (join to closed-won opps)
INSERT INTO Split_fact (oppty_id, rep_id, split_type, split_pct, comp_period_id)
SELECT
  s.oppty_id,
  s.rep_id,
  s.split_type,
  s.split_pct,
  '2026-01' AS comp_period_id
FROM SF_Split_raw s
JOIN Opportunity_fact o
  ON o.oppty_id = s.oppty_id;
