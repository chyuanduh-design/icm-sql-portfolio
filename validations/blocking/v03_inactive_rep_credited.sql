-- Block if any split credits a rep who is inactive in HR for the comp period
WITH period AS (
  SELECT comp_period_id, period_start, period_end
  FROM CompPeriod_dim
),
credited AS (
  SELECT
    s.comp_period_id,
    s.oppty_id,
    s.rep_id,
    r.employee_id,
    r.active_flag,
    r.termination_date
  FROM Split_fact s
  LEFT JOIN Rep_dim r
    ON r.rep_id = s.rep_id
),
violations AS (
  SELECT
    c.*
  FROM credited c
  JOIN period p
    ON p.comp_period_id = c.comp_period_id
  WHERE
    c.employee_id IS NULL                 -- no HR mapping at all
    OR c.active_flag = FALSE              -- inactive
    OR (c.termination_date IS NOT NULL AND c.termination_date < p.period_start) -- terminated before period
)
SELECT *
FROM violations
ORDER BY comp_period_id, oppty_id, rep_id;
