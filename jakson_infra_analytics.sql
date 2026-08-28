-- =========================================================
-- JAKSON INFRASTRUCTURE ANALYTICS SQL PLAYBOOK
-- Two Infrastructure Projects (~Rs. 2,000 Cr each)
-- Used for KPI tracking, cost optimization, tender monitoring,
-- contractor benchmarking, and executive dashboards.
-- =========================================================

-- 1. PROJECT HEALTH DASHBOARD
SELECT
    project_name,
    budget_cr,
    actual_cost_cr,
    ROUND(100*(budget_cr-actual_cost_cr)/budget_cr,2) AS cost_savings_pct,
    completion_pct,
    ROUND(100.0*completed_milestones/total_milestones,2) AS milestone_completion_pct
FROM project_master;

-- 2. ON-TIME TENDER EXECUTION (Target: 95%+)
SELECT
    project_name,
    COUNT(*) AS total_tenders,
    SUM(CASE WHEN actual_submission_date<=deadline_date THEN 1 ELSE 0 END) AS on_time_tenders,
    ROUND(100.0*SUM(CASE WHEN actual_submission_date<=deadline_date THEN 1 ELSE 0 END)/COUNT(*),2)
        AS on_time_pct
FROM govt_tenders
GROUP BY project_name;

-- 3. PROJECT DELAY REDUCTION ANALYSIS (20% IMPROVEMENT)
WITH delay_metrics AS (
SELECT project_name,
       AVG(planned_days) AS planned,
       AVG(actual_days) AS actual
FROM project_milestones
GROUP BY project_name)
SELECT *,
ROUND(100*(actual-planned)/planned,2) AS delay_pct
FROM delay_metrics;

-- 4. CONTRACTOR PERFORMANCE SCORECARD
SELECT
    contractor_name,
    COUNT(*) AS packages_executed,
    ROUND(AVG(quality_score),2) AS avg_quality,
    ROUND(AVG(cost_variance_pct),2) AS avg_cost_variance,
    DENSE_RANK() OVER(ORDER BY AVG(quality_score) DESC) AS contractor_rank
FROM contractor_kpis
GROUP BY contractor_name;

-- 5. VALUE ENGINEERING SAVINGS
SELECT
    initiative,
    SUM(original_cost_cr) AS original_cost,
    SUM(revised_cost_cr) AS revised_cost,
    ROUND(100*(SUM(original_cost_cr)-SUM(revised_cost_cr))/SUM(original_cost_cr),2)
        AS savings_pct
FROM value_engineering_log
GROUP BY initiative
ORDER BY savings_pct DESC;

-- 6. MONTH-OVER-MONTH CAPEX UTILIZATION
SELECT
    month,
    project_name,
    capex_spent_cr,
    ROUND(
        100*(capex_spent_cr - LAG(capex_spent_cr)
        OVER(PARTITION BY project_name ORDER BY month))
        /
        LAG(capex_spent_cr)
        OVER(PARTITION BY project_name ORDER BY month),2)
    AS mom_growth_pct
FROM capex_tracker;

-- 7. EXECUTIVE KPI VIEW
CREATE VIEW executive_dashboard AS
SELECT
    p.project_name,
    p.completion_pct,
    t.on_time_pct,
    c.savings_pct
FROM project_status p
JOIN tender_kpis t USING(project_name)
JOIN cost_kpis c USING(project_name);
