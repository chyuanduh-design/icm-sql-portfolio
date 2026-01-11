-- Trace a single opportunity end-to-end for dispute troubleshooting
-- Change the oppty_id filter at the bottom.
WITH base AS (
  SELECT
    o.comp_period_id,
    o.oppty_id,
    o.account_id,
    o.close_date,
    o.amount AS oppty_amount
  FROM Opportunity_fact o
  WHERE o.comp_period_id = '2026-01'
),
splits AS (
  SELECT
    s.comp_period_id,
    s.oppty_id,
    s.rep_id,
    s.split_type,
    s.split_pct,
    (b.oppty_amount * (s.split_pct / 100.0)) AS credited_amount_proxy
  FROM Split_fact s
  JOIN base b
    ON b.oppty_id = s.oppty_id
   AND b.comp_period_id = s.comp_period_id
),
rep AS (
  SELECT rep_id, employee_id, active_flag, termination_date
  FROM Rep_dim
)
SELECT
  b.comp_period_id,
  b.oppty_id,
  b.account_id,
  b.close_date,
  b.oppty_amount,
  sp.rep_id,
  r.employee_id,
  r.active_flag,
  r.termination_date,
  sp.split_type,
  sp.split_pct,
  sp.credited_amount_proxy
FROM base b
JOIN splits sp
  ON sp.oppty_id = b.oppty_id
LEFT JOIN rep r
  ON r.rep_id = sp.rep_id
WHERE b.oppty_id = 'O200'
ORDER BY sp.rep_id;
