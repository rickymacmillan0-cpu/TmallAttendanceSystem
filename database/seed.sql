USE `tmall_attendance`;
-- 可选：初始化字典与示例班次（按需执行）
SET NAMES utf8mb4;

INSERT INTO `leave_type` (`type_code`, `type_name`, `paid`, `max_days_per_year`, `need_attachment`) VALUES
  ('AL', '年假', 1, 15.0, 0),
  ('SL', '病假', 1, NULL, 1),
  ('PL', '事假', 0, NULL, 0),
  ('ML', '婚假', 1, 10.0, 1),
  ('OL', '调休', 1, NULL, 0)
ON DUPLICATE KEY UPDATE `type_name` = VALUES(`type_name`);

INSERT INTO `work_shift` (`shift_code`, `shift_name`, `planned_start_time`, `planned_end_time`, `late_grace_minutes`) VALUES
  ('DAY_STD', '常白班', '09:00:00', '18:00:00', 10),
  ('CS_LATE', '客服晚班', '14:00:00', '23:00:00', 10)
ON DUPLICATE KEY UPDATE `shift_name` = VALUES(`shift_name`);
