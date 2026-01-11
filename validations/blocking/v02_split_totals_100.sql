-- Split totals must equal 100% per opportunity per comp period (±0.01)
WITH totals AS (
  SELECT
    comp_period_id,
    oppty_id,
    SUM(split_pct) AS total_split_pct
  FROM Split_fact
  GROUP BY 1,2
)
SELECT *
FROM totals
WHERE ABS(total_split_pct - 100.0) > 0.01
ORDER BY comp_period_id, oppty_id;
