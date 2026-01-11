-- =====================================================
-- RECON SPINE (MINIMAL)
-- Stage-by-stage control totals for comp close sign-off
-- =====================================================

WITH
p AS (
  SELECT comp_period_id, period_start, period_end
  FROM CompPeriod_dim
  WHERE comp_period_id = '2026-01'
),

sfdc_bookings AS (
  SELECT
    'SFDC_CLOSED_WON_RAW' AS stage,
    COUNT(*) AS row_count,
    SUM(amount) AS total_amount
  FROM SF_Opportunity_raw o, p
  WHERE o.is_closed_won = TRUE
    AND o.close_date BETWEEN p.period_start AND p.period_end
),

curated_opp AS (
  SELECT
    'CURATED_OPPORTUNITY_FACT' AS stage,
    COUNT(*) AS row_count,
    SUM(amount) AS total_amount
  FROM Opportunity_fact
  WHERE comp_period_id = '2026-01'
),

credited_split AS (
  -- "Credited" proxy: distribute opp amount by split %
  SELECT
    'CREDITED_SPLIT_PROXY' AS stage,
    COUNT(*) AS row_count,
    SUM(o.amount * (s.split_pct / 100.0)) AS total_amount
  FROM Split_fact s
  JOIN Opportunity_fact o
    ON o.oppty_id = s.oppty_id
   AND o.comp_period_id = s.comp_period_id
  WHERE s.comp_period_id = '2026-01'
),

stages AS (
  SELECT * FROM sfdc_bookings
  UNION ALL SELECT * FROM curated_opp
  UNION ALL SELECT * FROM credited_split
),

with_variance AS (
  SELECT
    stage,
    row_count,
    total_amount,
    total_amount - LAG(total_amount) OVER (ORDER BY
      CASE stage
        WHEN 'SFDC_CLOSED_WON_RAW' THEN 1
        WHEN 'CURATED_OPPORTUNITY_FACT' THEN 2
        WHEN 'CREDITED_SPLIT_PROXY' THEN 3
        ELSE 99
      END
    ) AS variance_to_prev
  FROM stages
)

SELECT *
FROM with_variance
ORDER BY
  CASE stage
    WHEN 'SFDC_CLOSED_WON_RAW' THEN 1
    WHEN 'CURATED_OPPORTUNITY_FACT' THEN 2
    WHEN 'CREDITED_SPLIT_PROXY' THEN 3
    ELSE 99
  END;
