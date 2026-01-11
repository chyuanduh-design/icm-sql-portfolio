-- =====================================================
-- RAW STAGING TABLES (IMMUTABLE)
-- Purpose: Store source-of-truth data exactly as received
-- No updates, no deletes. Reprocess by reload only.
-- =====================================================

CREATE TABLE IF NOT EXISTS SF_Opportunity_raw (
    oppty_id       VARCHAR,
    account_id     VARCHAR,
    stage_name     VARCHAR,
    close_date     DATE,
    amount         DOUBLE,
    currency       VARCHAR,
    is_closed_won  BOOLEAN,
    ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS SF_Split_raw (
    oppty_id       VARCHAR,
    rep_id         VARCHAR,
    split_type     VARCHAR,
    split_pct      DOUBLE,
    ingest_ts      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS HR_Employee_raw (
    employee_id      VARCHAR,
    rep_id           VARCHAR,
    active_flag      BOOLEAN,
    hire_date        DATE,
    termination_date DATE,
    ingest_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Billing_Invoice_raw (
    invoice_line_id       VARCHAR,
    customer_external_id  VARCHAR,
    invoice_date          DATE,
    amount                DOUBLE,
    currency              VARCHAR,
    ingest_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS UsageEvent_raw (
    usage_event_id        VARCHAR,
    customer_external_id  VARCHAR,
    usage_date            DATE,
    usage_amount          DOUBLE,
    ingest_ts             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
