-- Close readiness summary: 0 rows = pass, >0 rows = blocked
WITH checks AS (
  SELECT 'split_totals_100' AS check_name, COUNT(*) AS fail_count
  FROM (
    WITH totals AS (
      SELECT comp_period_id, oppty_id, SUM(split_pct) AS total_split_pct
      FROM Split_fact
      GROUP BY 1,2
    )
    SELECT 1
    FROM totals
    WHERE ABS(total_split_pct - 100.0) > 0.01
  )
  UNION ALL
  SELECT 'inactive_rep_credited' AS check_name, COUNT(*) AS fail_count
  FROM (
    WITH period AS (
      SELECT comp_period_id, period_start, period_end
      FROM CompPeriod_dim
    ),
    credited AS (
      SELECT s.comp_period_id, s.oppty_id, s.rep_id, r.employee_id, r.active_flag, r.termination_date
      FROM Split_fact s
      LEFT JOIN Rep_dim r ON r.rep_id = s.rep_id
    )
    SELECT 1
    FROM credited c
    JOIN period p ON p.comp_period_id = c.comp_period_id
    WHERE c.employee_id IS NULL
       OR c.active_flag = FALSE
       OR (c.termination_date IS NOT NULL AND c.termination_date < p.period_start)
  )
  UNION ALL
  SELECT 'duplicate_invoice_line_id' AS check_name, COUNT(*) AS fail_count
  FROM (
    SELECT invoice_line_id
    FROM Billing_Invoice_raw
    GROUP BY 1
    HAVING COUNT(*) > 1
  )
)
SELECT *
FROM checks
ORDER BY fail_count DESC, check_name;
