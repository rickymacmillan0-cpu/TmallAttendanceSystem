-- =============================================================================
-- Example SQL for course report / oral defense (MySQL 8+)
-- Run against database: tmall_attendance (adjust USE if needed)
-- =============================================================================

USE `tmall_attendance`;

-- -----------------------------------------------------------------------------
-- Q1 员工列表 + 部门 + 岗位（多表连接，展示 3NF：名称从维度表取）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  d.`dept_name`,
  p.`position_name`,
  e.`work_status`,
  e.`hire_date`
FROM `employee` e
JOIN `department` d ON d.`dept_id` = e.`dept_id`
JOIN `job_position` p ON p.`position_id` = e.`position_id`
ORDER BY d.`dept_code`, e.`emp_no`;

-- -----------------------------------------------------------------------------
-- Q2 指定日期区间：各部门出勤状态分布（聚合 + 连接）
-- -----------------------------------------------------------------------------
SELECT
  d.`dept_name`,
  ad.`attendance_status`,
  COUNT(*) AS `cnt`
FROM `attendance_daily` ad
JOIN `employee` e ON e.`emp_id` = ad.`emp_id`
JOIN `department` d ON d.`dept_id` = e.`dept_id`
WHERE ad.`work_date` BETWEEN '2026-05-05' AND '2026-05-09'
GROUP BY d.`dept_name`, ad.`attendance_status`
ORDER BY d.`dept_name`, ad.`attendance_status`;

-- -----------------------------------------------------------------------------
-- Q3 某日迟到人员明细（过滤 + 连接）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  d.`dept_name`,
  ad.`first_check_in`,
  ad.`remark`
FROM `attendance_daily` ad
JOIN `employee` e ON e.`emp_id` = ad.`emp_id`
JOIN `department` d ON d.`dept_id` = e.`dept_id`
WHERE ad.`work_date` = '2026-05-06'
  AND ad.`attendance_status` = 'LATE'
ORDER BY e.`emp_no`;

-- -----------------------------------------------------------------------------
-- Q4 请假申请：待审批列表（连接员工与请假类型）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  lt.`type_name`,
  la.`start_at`,
  la.`end_at`,
  la.`reason`,
  la.`approval_status`
FROM `leave_application` la
JOIN `employee` e ON e.`emp_id` = la.`emp_id`
JOIN `leave_type` lt ON lt.`leave_type_id` = la.`leave_type_id`
WHERE la.`approval_status` = 'PENDING'
ORDER BY la.`submitted_at` DESC;

-- -----------------------------------------------------------------------------
-- Q5 已批准请假：带审批人姓名（自连接 / 两次 join employee）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no` AS `applicant_no`,
  e.`full_name` AS `applicant_name`,
  lt.`type_name`,
  la.`start_at`,
  la.`end_at`,
  mgr.`emp_no` AS `approver_no`,
  mgr.`full_name` AS `approver_name`,
  la.`approval_remark`
FROM `leave_application` la
JOIN `employee` e ON e.`emp_id` = la.`emp_id`
JOIN `leave_type` lt ON lt.`leave_type_id` = la.`leave_type_id`
LEFT JOIN `employee` mgr ON mgr.`emp_id` = la.`approver_emp_id`
WHERE la.`approval_status` = 'APPROVED'
ORDER BY la.`decided_at` DESC;

-- -----------------------------------------------------------------------------
-- Q6 子查询：在 demo 日期范围内，至少有一天标记为 ABSENT 的员工
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  d.`dept_name`
FROM `employee` e
JOIN `department` d ON d.`dept_id` = e.`dept_id`
WHERE e.`emp_id` IN (
  SELECT DISTINCT ad.`emp_id`
  FROM `attendance_daily` ad
  WHERE ad.`work_date` BETWEEN '2026-05-05' AND '2026-05-09'
    AND ad.`attendance_status` = 'ABSENT'
)
ORDER BY e.`emp_no`;

-- -----------------------------------------------------------------------------
-- Q7 打卡原始记录 + 员工（事实表 + 维度表）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  ap.`punch_at`,
  ap.`punch_type`,
  ap.`source`
FROM `attendance_punch` ap
JOIN `employee` e ON e.`emp_id` = ap.`emp_id`
WHERE DATE(ap.`punch_at`) = '2026-05-05'
ORDER BY e.`emp_no`, ap.`punch_at`;

-- -----------------------------------------------------------------------------
-- Q8 HAVING：统计区间内“迟到次数 >= 1”的员工
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  COUNT(*) AS `late_times`
FROM `attendance_daily` ad
JOIN `employee` e ON e.`emp_id` = ad.`emp_id`
WHERE ad.`work_date` BETWEEN '2026-05-05' AND '2026-05-09'
  AND ad.`attendance_status` = 'LATE'
GROUP BY e.`emp_id`, e.`emp_no`, e.`full_name`
HAVING `late_times` >= 1
ORDER BY `late_times` DESC, e.`emp_no`;

-- -----------------------------------------------------------------------------
-- Q9 窗口函数（MySQL 8）：每位员工在 demo 区间内按日考勤排名（可选加分）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  ad.`work_date`,
  ad.`attendance_status`,
  ROW_NUMBER() OVER (PARTITION BY e.`emp_id` ORDER BY ad.`work_date`) AS `day_seq`
FROM `attendance_daily` ad
JOIN `employee` e ON e.`emp_id` = ad.`emp_id`
WHERE ad.`work_date` BETWEEN '2026-05-05' AND '2026-05-09'
ORDER BY e.`emp_no`, ad.`work_date`;

-- -----------------------------------------------------------------------------
-- Q10 请假按日展开 + 申请人（leave_application_daily 用法）
-- -----------------------------------------------------------------------------
SELECT
  e.`emp_no`,
  e.`full_name`,
  lad.`work_date`,
  lad.`deduct_minutes`,
  la.`approval_status`
FROM `leave_application_daily` lad
JOIN `leave_application` la ON la.`application_id` = lad.`application_id`
JOIN `employee` e ON e.`emp_id` = la.`emp_id`
ORDER BY lad.`work_date`, e.`emp_no`;
