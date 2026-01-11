-- =====================================================
-- CURATED TABLES
-- Purpose: Business-ready, validated, comp-aware tables
-- =====================================================

-- Compensation Periods
CREATE TABLE IF NOT EXISTS CompPeriod_dim (
    comp_period_id   VARCHAR,
    period_start     DATE,
    period_end       DATE,
    lock_ts          TIMESTAMP
);

-- Sales Reps (joined from SF + HR)
CREATE TABLE IF NOT EXISTS Rep_dim (
    rep_id           VARCHAR,
    employee_id      VARCHAR,
    active_flag      BOOLEAN,
    hire_date        DATE,
    termination_date DATE
);

-- Opportunities (curated)
CREATE TABLE IF NOT EXISTS Opportunity_fact (
    oppty_id         VARCHAR,
    account_id       VARCHAR,
    close_date       DATE,
    amount           DOUBLE,
    currency         VARCHAR,
    comp_period_id   VARCHAR
);

-- Opportunity Splits (credited view)
CREATE TABLE IF NOT EXISTS Split_fact (
    oppty_id         VARCHAR,
    rep_id           VARCHAR,
    split_type       VARCHAR,
    split_pct        DOUBLE,
    comp_period_id   VARCHAR
);
