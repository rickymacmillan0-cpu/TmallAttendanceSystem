
-- =============================================================================
-- Demo data for course / report (idempotent where possible)
-- Prerequisite: run init_database.sql, schema.sql, seed.sql (leave_type + work_shift)
-- Optional: run backend/init_data.py first (技术部 / 测试员A) — this script is compatible
-- =============================================================================

SET NAMES utf8mb4;

-- Replace if your database name differs
USE `tmall_attendance`;

-- -----------------------------------------------------------------------------
-- Dictionary / reference rows (safe to re-run)
-- -----------------------------------------------------------------------------
INSERT INTO `job_position` (`position_code`, `position_name`, `job_level`) VALUES
  ('DEMO_OPS', '运营专员', 'P5'),
  ('DEMO_HR', '人力专员', 'P5')
ON DUPLICATE KEY UPDATE `position_name` = VALUES(`position_name`);

INSERT INTO `department` (`dept_code`, `dept_name`, `location`) VALUES
  ('DEPT_OPS', '运营部', '杭州园区A座'),
  ('DEPT_HR', '人力部', '杭州园区B座')
ON DUPLICATE KEY UPDATE `dept_name` = VALUES(`dept_name`), `location` = VALUES(`location`);

-- -----------------------------------------------------------------------------
-- Employees (unique emp_no)
-- -----------------------------------------------------------------------------
INSERT INTO `employee` (`emp_no`, `full_name`, `gender`, `dept_id`, `position_id`, `hire_date`, `work_status`)
SELECT 'EMP_DEMO_01', '张三', 'M', d.`dept_id`, p.`position_id`, '2024-03-01', 'ACTIVE'
FROM `department` d
JOIN `job_position` p ON p.`position_code` = 'DEMO_OPS'
WHERE d.`dept_code` = 'DEPT_OPS'
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`);

INSERT INTO `employee` (`emp_no`, `full_name`, `gender`, `dept_id`, `position_id`, `hire_date`, `work_status`)
SELECT 'EMP_DEMO_02', '李四', 'F', d.`dept_id`, p.`position_id`, '2023-11-15', 'ACTIVE'
FROM `department` d
JOIN `job_position` p ON p.`position_code` = 'DEMO_HR'
WHERE d.`dept_code` = 'DEPT_HR'
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`);

INSERT INTO `employee` (`emp_no`, `full_name`, `gender`, `dept_id`, `position_id`, `hire_date`, `work_status`)
SELECT 'EMP_DEMO_03', '王五', 'M', d.`dept_id`, p.`position_id`, '2025-01-06', 'PROBATION'
FROM `department` d
JOIN `job_position` p ON p.`position_code` = 'DEMO_OPS'
WHERE d.`dept_code` = 'DEPT_OPS'
ON DUPLICATE KEY UPDATE `full_name` = VALUES(`full_name`);

-- -----------------------------------------------------------------------------
-- Attendance daily: multiple statuses (re-run updates same emp+date)
-- Dates are fixed for reproducible screenshots; change if needed
-- -----------------------------------------------------------------------------
INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-05', s.`shift_id`, '2026-05-05 08:58:00', '2026-05-05 18:02:00',
       480, 'PRESENT', NULL
FROM `employee` e
CROSS JOIN `work_shift` s
WHERE e.`emp_no` = 'EMP_DEMO_01' AND s.`shift_code` = 'DAY_STD'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-06', s.`shift_id`, '2026-05-06 09:25:00', '2026-05-06 18:00:00',
       450, 'LATE', '地铁延误'
FROM `employee` e
CROSS JOIN `work_shift` s
WHERE e.`emp_no` = 'EMP_DEMO_01' AND s.`shift_code` = 'DAY_STD'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-07', s.`shift_id`, NULL, NULL,
       NULL, 'ABSENT', '未打卡'
FROM `employee` e
CROSS JOIN `work_shift` s
WHERE e.`emp_no` = 'EMP_DEMO_01' AND s.`shift_code` = 'DAY_STD'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-06', s.`shift_id`, '2026-05-06 09:00:00', '2026-05-06 18:00:00',
       480, 'PRESENT', NULL
FROM `employee` e
CROSS JOIN `work_shift` s
WHERE e.`emp_no` = 'EMP_DEMO_02' AND s.`shift_code` = 'DAY_STD'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-06', NULL, NULL, NULL,
       NULL, 'LEAVE', '已批准事假'
FROM `employee` e
WHERE e.`emp_no` = 'EMP_DEMO_03'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

-- If you ran init_data.py: optional row for 测试员A
INSERT INTO `attendance_daily` (
  `emp_id`, `work_date`, `shift_id`, `first_check_in`, `last_check_out`,
  `work_minutes`, `attendance_status`, `remark`
)
SELECT e.`emp_id`, '2026-05-06', s.`shift_id`, NULL, NULL,
       NULL, 'PENDING', '待系统汇总'
FROM `employee` e
CROSS JOIN `work_shift` s
WHERE e.`emp_no` = 'EMP_TEST_A' AND s.`shift_code` = 'DAY_STD'
ON DUPLICATE KEY UPDATE
  `shift_id` = VALUES(`shift_id`),
  `first_check_in` = VALUES(`first_check_in`),
  `last_check_out` = VALUES(`last_check_out`),
  `work_minutes` = VALUES(`work_minutes`),
  `attendance_status` = VALUES(`attendance_status`),
  `remark` = VALUES(`remark`);

-- -----------------------------------------------------------------------------
-- Punch events (raw facts) for 2026-05-05
-- -----------------------------------------------------------------------------
INSERT INTO `attendance_punch` (`emp_id`, `punch_at`, `punch_type`, `source`)
SELECT e.`emp_id`, '2026-05-05 08:58:00', 'CHECK_IN', 'MOBILE'
FROM `employee` e WHERE e.`emp_no` = 'EMP_DEMO_01';

INSERT INTO `attendance_punch` (`emp_id`, `punch_at`, `punch_type`, `source`)
SELECT e.`emp_id`, '2026-05-05 18:02:00', 'CHECK_OUT', 'MOBILE'
FROM `employee` e WHERE e.`emp_no` = 'EMP_DEMO_01';

-- -----------------------------------------------------------------------------
-- Leave applications (needs leave_type from seed.sql)
-- -----------------------------------------------------------------------------
INSERT INTO `leave_application` (
  `emp_id`, `leave_type_id`, `start_at`, `end_at`, `reason`,
  `approval_status`, `approver_emp_id`, `approval_remark`, `decided_at`
)
SELECT
  ap.`emp_id`,
  lt.`leave_type_id`,
  '2026-05-08 09:00:00',
  '2026-05-08 18:00:00',
  '家中有事需要处理',
  'PENDING',
  NULL,
  NULL,
  NULL
FROM `employee` ap
CROSS JOIN `leave_type` lt
WHERE ap.`emp_no` = 'EMP_DEMO_01' AND lt.`type_code` = 'PL'
LIMIT 1;

INSERT INTO `leave_application` (
  `emp_id`, `leave_type_id`, `start_at`, `end_at`, `reason`,
  `approval_status`, `approver_emp_id`, `approval_remark`, `decided_at`
)
SELECT
  ap.`emp_id`,
  lt.`leave_type_id`,
  '2026-05-06 09:00:00',
  '2026-05-06 18:00:00',
  '年假一天',
  'APPROVED',
  mgr.`emp_id`,
  '同意',
  '2026-05-05 10:00:00'
FROM `employee` ap
CROSS JOIN `leave_type` lt
JOIN `employee` mgr ON mgr.`emp_no` = 'EMP_DEMO_01'
WHERE ap.`emp_no` = 'EMP_DEMO_02' AND lt.`type_code` = 'AL'
LIMIT 1;

-- Expand approved leave to one calendar day (optional, for join demos)
INSERT INTO `leave_application_daily` (`application_id`, `work_date`, `deduct_minutes`)
SELECT la.`application_id`, DATE('2026-05-06'), 480
FROM `leave_application` la
JOIN `employee` e ON e.`emp_id` = la.`emp_id`
WHERE e.`emp_no` = 'EMP_DEMO_02' AND la.`approval_status` = 'APPROVED'
  AND la.`start_at` = '2026-05-06 09:00:00'
ON DUPLICATE KEY UPDATE `deduct_minutes` = VALUES(`deduct_minutes`);
