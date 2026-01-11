-- Block if Billing invoice natural key duplicates exist (risk of double pay)
SELECT
  invoice_line_id,
  COUNT(*) AS dup_count,
  SUM(amount) AS dup_amount
FROM Billing_Invoice_raw
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY dup_count DESC, invoice_line_id;
