USE `tmall_attendance`;
-- =============================================================================
-- 天猫商城员工考勤管理系统 - MySQL 8.0+ 建表脚本
-- 设计说明（第三范式 3NF）：
--   - 部门、员工、岗位、班次、请假类型等实体各自成表，避免非主属性对码的传递依赖
--   - 考勤打卡与考勤日汇总分离：打卡为事件事实，日汇总为派生/归档维度（仅存外键与日期键）
--   - 请假申请通过 leave_type_id 引用请假类型，不冗余存储类型名称
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. 部门表：部门信息独立存储；负责人通过员工表逻辑关联（不设 FK 避免环依赖）
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `dept_id`       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '部门主键',
  `dept_code`     VARCHAR(32)  NOT NULL COMMENT '部门编码',
  `dept_name`     VARCHAR(64)  NOT NULL COMMENT '部门名称',
  `parent_dept_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '上级部门（可选，树形组织）',
  `location`      VARCHAR(128) DEFAULT NULL COMMENT '办公地点',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`dept_id`),
  UNIQUE KEY `uk_department_code` (`dept_code`),
  KEY `idx_department_parent` (`parent_dept_id`),
  CONSTRAINT `fk_department_parent`
    FOREIGN KEY (`parent_dept_id`) REFERENCES `department` (`dept_id`)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门';

-- -----------------------------------------------------------------------------
-- 2. 岗位表：岗位名称与职级与员工解耦
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `job_position`;
CREATE TABLE `job_position` (
  `position_id`   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `position_code` VARCHAR(32)  NOT NULL COMMENT '岗位编码',
  `position_name` VARCHAR(64)  NOT NULL COMMENT '岗位名称',
  `job_level`     VARCHAR(32)  DEFAULT NULL COMMENT '职级/序列',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`position_id`),
  UNIQUE KEY `uk_job_position_code` (`position_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='岗位';

-- -----------------------------------------------------------------------------
-- 3. 员工表：仅存部门与岗位外键，不冗余部门名、岗位名
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `employee`;
CREATE TABLE `employee` (
  `emp_id`        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_no`        VARCHAR(32)  NOT NULL COMMENT '工号',
  `full_name`     VARCHAR(64)  NOT NULL COMMENT '姓名',
  `gender`        CHAR(1)      DEFAULT NULL COMMENT '性别 M/F/U',
  `mobile`        VARCHAR(20)  DEFAULT NULL,
  `email`         VARCHAR(128) DEFAULT NULL,
  `dept_id`       BIGINT UNSIGNED NOT NULL,
  `position_id`   BIGINT UNSIGNED NOT NULL,
  `hire_date`     DATE         NOT NULL COMMENT '入职日期',
  `work_status`   VARCHAR(16)  NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE/PROBATION/LEFT',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`emp_id`),
  UNIQUE KEY `uk_employee_emp_no` (`emp_no`),
  KEY `idx_employee_dept` (`dept_id`),
  KEY `idx_employee_position` (`position_id`),
  CONSTRAINT `fk_employee_dept`
    FOREIGN KEY (`dept_id`) REFERENCES `department` (`dept_id`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_employee_position`
    FOREIGN KEY (`position_id`) REFERENCES `job_position` (`position_id`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工';

-- 部门负责人（在员工表存在后添加，避免创建顺序问题）
ALTER TABLE `department`
  ADD COLUMN `manager_emp_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '部门负责人' AFTER `parent_dept_id`,
  ADD KEY `idx_department_manager` (`manager_emp_id`),
  ADD CONSTRAINT `fk_department_manager`
    FOREIGN KEY (`manager_emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 4. 系统账号（与业务员工一对一）：登录凭证与员工档案分离，满足 3NF
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `employee_account`;
CREATE TABLE `employee_account` (
  `account_id`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_id`         BIGINT UNSIGNED NOT NULL,
  `username`       VARCHAR(64)  NOT NULL,
  `password_hash`  VARCHAR(255) NOT NULL COMMENT '存储哈希，不明文',
  `account_status` VARCHAR(16) NOT NULL DEFAULT 'ENABLED' COMMENT 'ENABLED/LOCKED',
  `last_login_at`  DATETIME DEFAULT NULL,
  `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `uk_account_emp` (`emp_id`),
  UNIQUE KEY `uk_account_username` (`username`),
  CONSTRAINT `fk_account_employee`
    FOREIGN KEY (`emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工登录账号';

-- -----------------------------------------------------------------------------
-- 5. 班次表：规则与考勤记录分离
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `work_shift`;
CREATE TABLE `work_shift` (
  `shift_id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `shift_code`        VARCHAR(32)  NOT NULL,
  `shift_name`        VARCHAR(64)  NOT NULL COMMENT '例如 常白班/客服晚班',
  `planned_start_time` TIME NOT NULL COMMENT '应上班时间',
  `planned_end_time`   TIME NOT NULL COMMENT '应下班时间',
  `late_grace_minutes` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '迟到宽限分钟',
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`shift_id`),
  UNIQUE KEY `uk_work_shift_code` (`shift_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='班次';

-- 员工默认班次（多对多：员工可排不同班）
DROP TABLE IF EXISTS `employee_shift_assignment`;
CREATE TABLE `employee_shift_assignment` (
  `assignment_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_id`      BIGINT UNSIGNED NOT NULL,
  `shift_id`    BIGINT UNSIGNED NOT NULL,
  `effective_from` DATE NOT NULL,
  `effective_to`   DATE DEFAULT NULL COMMENT '空表示至今有效',
  PRIMARY KEY (`assignment_id`),
  KEY `idx_esa_emp` (`emp_id`),
  KEY `idx_esa_shift` (`shift_id`),
  CONSTRAINT `fk_esa_employee` FOREIGN KEY (`emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_esa_shift` FOREIGN KEY (`shift_id`) REFERENCES `work_shift` (`shift_id`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工班次分配';

-- -----------------------------------------------------------------------------
-- 6. 考勤打卡原始记录：一条为一事件（上班/下班打卡）
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `attendance_punch`;
CREATE TABLE `attendance_punch` (
  `punch_id`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_id`       BIGINT UNSIGNED NOT NULL,
  `punch_at`     DATETIME NOT NULL COMMENT '打卡时间',
  `punch_type`   VARCHAR(16) NOT NULL COMMENT 'CHECK_IN / CHECK_OUT',
  `source`       VARCHAR(32) DEFAULT 'TERMINAL' COMMENT 'TERMINAL/MOBILE/IMPORT',
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`punch_id`),
  KEY `idx_punch_emp_time` (`emp_id`, `punch_at`),
  CONSTRAINT `fk_punch_employee` FOREIGN KEY (`emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='考勤打卡明细';

-- -----------------------------------------------------------------------------
-- 7. 考勤日汇总：每人每天一条，状态码引用业务字典（可后续扩展为字典表）
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `attendance_daily`;
CREATE TABLE `attendance_daily` (
  `daily_id`        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_id`          BIGINT UNSIGNED NOT NULL,
  `work_date`       DATE NOT NULL COMMENT '归属工作日',
  `shift_id`        BIGINT UNSIGNED DEFAULT NULL COMMENT '当日适用班次',
  `first_check_in`  DATETIME DEFAULT NULL,
  `last_check_out`  DATETIME DEFAULT NULL,
  `work_minutes`    INT UNSIGNED DEFAULT NULL COMMENT '计工时（分钟），可由业务计算写入',
  `attendance_status` VARCHAR(24) NOT NULL DEFAULT 'PENDING'
    COMMENT 'PRESENT/LATE/EARLY_LEAVE/ABSENT/LEAVE/PENDING',
  `remark`          VARCHAR(255) DEFAULT NULL,
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`daily_id`),
  UNIQUE KEY `uk_daily_emp_date` (`emp_id`, `work_date`),
  KEY `idx_daily_date` (`work_date`),
  CONSTRAINT `fk_daily_employee` FOREIGN KEY (`emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_daily_shift` FOREIGN KEY (`shift_id`) REFERENCES `work_shift` (`shift_id`)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='考勤日汇总';

-- -----------------------------------------------------------------------------
-- 8. 请假类型字典
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `leave_type`;
CREATE TABLE `leave_type` (
  `leave_type_id`   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_code`       VARCHAR(32)  NOT NULL,
  `type_name`       VARCHAR(64)  NOT NULL COMMENT '事假/病假/年假等',
  `paid`            TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否带薪',
  `max_days_per_year` DECIMAL(5,1) DEFAULT NULL COMMENT '年度上限（天），空表示不限制',
  `need_attachment` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否需证明',
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`leave_type_id`),
  UNIQUE KEY `uk_leave_type_code` (`type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='请假类型';

-- -----------------------------------------------------------------------------
-- 9. 请假申请：类型、申请人、审批人仅存外键与状态，不冗余姓名
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `leave_application`;
CREATE TABLE `leave_application` (
  `application_id`  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `emp_id`          BIGINT UNSIGNED NOT NULL COMMENT '申请人',
  `leave_type_id`   BIGINT UNSIGNED NOT NULL,
  `start_at`        DATETIME NOT NULL,
  `end_at`          DATETIME NOT NULL,
  `reason`          VARCHAR(512) NOT NULL,
  `attachment_url`  VARCHAR(512) DEFAULT NULL,
  `approval_status` VARCHAR(16) NOT NULL DEFAULT 'PENDING'
    COMMENT 'PENDING/APPROVED/REJECTED/CANCELLED',
  `approver_emp_id` BIGINT UNSIGNED DEFAULT NULL COMMENT '审批人（主管/HR）',
  `approval_remark` VARCHAR(255) DEFAULT NULL,
  `submitted_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `decided_at`      DATETIME DEFAULT NULL,
  PRIMARY KEY (`application_id`),
  KEY `idx_leave_emp` (`emp_id`),
  KEY `idx_leave_status` (`approval_status`),
  KEY `idx_leave_period` (`start_at`, `end_at`),
  CONSTRAINT `fk_leave_employee` FOREIGN KEY (`emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT `fk_leave_type` FOREIGN KEY (`leave_type_id`) REFERENCES `leave_type` (`leave_type_id`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_leave_approver` FOREIGN KEY (`approver_emp_id`) REFERENCES `employee` (`emp_id`)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='请假申请';

-- -----------------------------------------------------------------------------
-- 10. 审批通过后与日考勤的关联（可选：便于查询某日已批准的请假区间）
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `leave_application_daily`;
CREATE TABLE `leave_application_daily` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `application_id`  BIGINT UNSIGNED NOT NULL,
  `work_date`       DATE NOT NULL,
  `deduct_minutes`  INT UNSIGNED NOT NULL DEFAULT 480 COMMENT '当日折算请假分钟',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_lad_app_date` (`application_id`, `work_date`),
  KEY `idx_lad_date` (`work_date`),
  CONSTRAINT `fk_lad_application` FOREIGN KEY (`application_id`) REFERENCES `leave_application` (`application_id`)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='请假按日展开（审批通过后写入；员工通过申请单关联）';

SET FOREIGN_KEY_CHECKS = 1;
