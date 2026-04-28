-- ============================================================
-- БАЗА ДАННЫХ ДЛЯ ВЕБ-ПРИЛОЖЕНИЯ ГЕНЕРАЦИИ ИНФОГРАФИКИ
-- ПО УЧЕБНОЙ СТАТИСТИКЕ
--
-- Запускать в pgAdmin 4 через Query Tool
-- Перед запуском создать пустую базу данных, например:
-- InfographicAppDB
-- ============================================================

-- Расширение PostgreSQL для хэширования паролей
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- НАСТРОЙКА ЧАСОВОГО ПОЯСА
-- ============================================================
-- В проекте используется московское время, чтобы даты в журнале аудита,
-- регистрации, импорта, экспорта и сохранения инфографики совпадали
-- с фактическим временем работы пользователя в интерфейсе.
SET TIME ZONE 'Europe/Moscow';

DO $$
BEGIN
    EXECUTE format(
        'ALTER DATABASE %I SET timezone = %L',
        current_database(),
        'Europe/Moscow'
    );
END;
$$;

-- ============================================================
-- УДАЛЕНИЕ СТАРЫХ ОБЪЕКТОВ ДЛЯ ПОВТОРНОГО ЗАПУСКА СКРИПТА
-- ============================================================

DROP VIEW IF EXISTS AuditLogView CASCADE;
DROP VIEW IF EXISTS InfographicsView CASCADE;
DROP VIEW IF EXISTS GroupStatisticsView CASCADE;
DROP VIEW IF EXISTS StudentStatisticsView CASCADE;
DROP VIEW IF EXISTS AttendanceView CASCADE;
DROP VIEW IF EXISTS GradesView CASCADE;
DROP VIEW IF EXISTS StudentsView CASCADE;
DROP VIEW IF EXISTS UsersAccountsView CASCADE;

DROP TABLE IF EXISTS SystemSettings CASCADE;
DROP TABLE IF EXISTS AuditLog CASCADE;
DROP TABLE IF EXISTS ImportFiles CASCADE;
DROP TABLE IF EXISTS ExportedFiles CASCADE;
DROP TABLE IF EXISTS Infographics CASCADE;
DROP TABLE IF EXISTS InfographicTemplates CASCADE;
DROP TABLE IF EXISTS Attendance CASCADE;
DROP TABLE IF EXISTS Grades CASCADE;
DROP TABLE IF EXISTS StudyPeriods CASCADE;
DROP TABLE IF EXISTS Disciplines CASCADE;
DROP TABLE IF EXISTS Students CASCADE;
DROP TABLE IF EXISTS StudyGroups CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Accounts CASCADE;
DROP TABLE IF EXISTS Roles CASCADE;

DROP PROCEDURE IF EXISTS RegisterUser(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS AddStudent(VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT) CASCADE;
DROP PROCEDURE IF EXISTS AddGrade(INT, INT, INT, INT, VARCHAR, DATE) CASCADE;
DROP PROCEDURE IF EXISTS AddAttendance(INT, INT, INT, INT, INT) CASCADE;
DROP PROCEDURE IF EXISTS SaveInfographic(VARCHAR, VARCHAR, JSONB, JSONB, INT, INT) CASCADE;
DROP PROCEDURE IF EXISTS SetAccountBlockStatus(INT, BOOLEAN) CASCADE;
DROP PROCEDURE IF EXISTS SetAccountRole(INT, INT) CASCADE;

DROP FUNCTION IF EXISTS CheckUserPassword(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_group_avg_grade_period(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS get_group_success_rate_period(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS get_group_attendance_rate_period(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS get_grade_distribution(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS check_account_email() CASCADE;
DROP FUNCTION IF EXISTS check_attendance_values() CASCADE;
DROP FUNCTION IF EXISTS log_changes() CASCADE;
DROP FUNCTION IF EXISTS app_now() CASCADE;

-- ============================================================
-- СЛУЖЕБНАЯ ФУНКЦИЯ ТЕКУЩЕГО ВРЕМЕНИ
-- ============================================================
-- CURRENT_TIMESTAMP зависит от часового пояса подключения.
-- Чтобы журнал аудита и остальные даты не уходили в UTC или другое
-- серверное время, все значения времени по умолчанию берутся через
-- эту функцию.
CREATE OR REPLACE FUNCTION app_now()
RETURNS TIMESTAMP AS $$
    SELECT timezone('Europe/Moscow', now())::TIMESTAMP;
$$ LANGUAGE SQL STABLE;

-- ============================================================
-- ТАБЛИЦЫ
-- ============================================================

-- Роли пользователей
CREATE TABLE Roles (
    ID_Role SERIAL PRIMARY KEY,
    RoleName VARCHAR(40) UNIQUE NOT NULL
);

-- Аккаунты пользователей
CREATE TABLE Accounts (
    ID_Account SERIAL PRIMARY KEY,
    Email VARCHAR(120) UNIQUE NOT NULL,
    PasswordHash TEXT NOT NULL,
    RegistrationDate TIMESTAMP DEFAULT app_now() NOT NULL,
    IsBlocked BOOLEAN DEFAULT FALSE NOT NULL,
    Role_ID INT NOT NULL REFERENCES Roles(ID_Role)
);

-- Персональные данные пользователей
CREATE TABLE Users (
    ID_User SERIAL PRIMARY KEY,
    LastName VARCHAR(80) NOT NULL,
    FirstName VARCHAR(80) NOT NULL,
    Patronymic VARCHAR(80),
    Account_ID INT UNIQUE NOT NULL REFERENCES Accounts(ID_Account) ON DELETE CASCADE
);

-- Учебные группы
CREATE TABLE StudyGroups (
    ID_Group SERIAL PRIMARY KEY,
    GroupName VARCHAR(40) UNIQUE NOT NULL,
    Course INT NOT NULL CHECK (Course BETWEEN 1 AND 6),
    StudyYear VARCHAR(9) NOT NULL,
    DirectionName VARCHAR(150),
    CONSTRAINT chk_study_year_group CHECK (StudyYear ~ '^[0-9]{4}/[0-9]{4}$')
);

-- Студенты
CREATE TABLE Students (
    ID_Student SERIAL PRIMARY KEY,
    LastName VARCHAR(80) NOT NULL,
    FirstName VARCHAR(80) NOT NULL,
    Patronymic VARCHAR(80),
    RecordBookNumber VARCHAR(30) UNIQUE,
    Group_ID INT NOT NULL REFERENCES StudyGroups(ID_Group) ON DELETE RESTRICT
);

-- Дисциплины
CREATE TABLE Disciplines (
    ID_Discipline SERIAL PRIMARY KEY,
    DisciplineName VARCHAR(120) UNIQUE NOT NULL,
    Description TEXT,
    TeacherName VARCHAR(150)
);

-- Учебные периоды
CREATE TABLE StudyPeriods (
    ID_Period SERIAL PRIMARY KEY,
    StudyYear VARCHAR(9) NOT NULL,
    Semester INT NOT NULL CHECK (Semester BETWEEN 1 AND 12),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    CONSTRAINT uq_period UNIQUE (StudyYear, Semester),
    CONSTRAINT chk_period_study_year CHECK (StudyYear ~ '^[0-9]{4}/[0-9]{4}$'),
    CONSTRAINT chk_period_dates CHECK (StartDate <= EndDate)
);

-- Оценки студентов
CREATE TABLE Grades (
    ID_Grade SERIAL PRIMARY KEY,
    GradeValue INT NOT NULL CHECK (GradeValue BETWEEN 2 AND 5),
    ControlType VARCHAR(40) NOT NULL,
    GradeDate DATE DEFAULT CURRENT_DATE NOT NULL,
    Student_ID INT NOT NULL REFERENCES Students(ID_Student) ON DELETE CASCADE,
    Discipline_ID INT NOT NULL REFERENCES Disciplines(ID_Discipline) ON DELETE RESTRICT,
    Period_ID INT NOT NULL REFERENCES StudyPeriods(ID_Period) ON DELETE RESTRICT,
    CONSTRAINT uq_grade_student_discipline_period UNIQUE (Student_ID, Discipline_ID, Period_ID, ControlType)
);

-- Посещаемость студентов
CREATE TABLE Attendance (
    ID_Attendance SERIAL PRIMARY KEY,
    AttendedCount INT DEFAULT 0 NOT NULL CHECK (AttendedCount >= 0),
    MissedCount INT DEFAULT 0 NOT NULL CHECK (MissedCount >= 0),
    Student_ID INT NOT NULL REFERENCES Students(ID_Student) ON DELETE CASCADE,
    Discipline_ID INT NOT NULL REFERENCES Disciplines(ID_Discipline) ON DELETE RESTRICT,
    Period_ID INT NOT NULL REFERENCES StudyPeriods(ID_Period) ON DELETE RESTRICT,
    CONSTRAINT uq_attendance_student_discipline_period UNIQUE (Student_ID, Discipline_ID, Period_ID)
);

-- Шаблоны инфографики
CREATE TABLE InfographicTemplates (
    ID_Template SERIAL PRIMARY KEY,
    TemplateName VARCHAR(120) UNIQUE NOT NULL,
    ChartType VARCHAR(40) NOT NULL,
    ColorScheme VARCHAR(60) NOT NULL,
    Description TEXT,
    IsActive BOOLEAN DEFAULT TRUE NOT NULL,
    CONSTRAINT chk_chart_type_template CHECK (ChartType IN ('bar', 'line', 'pie', 'doughnut', 'card'))
);

-- Сохраненные инфографики
CREATE TABLE Infographics (
    ID_Infographic SERIAL PRIMARY KEY,
    Title VARCHAR(150) NOT NULL,
    ChartType VARCHAR(40) NOT NULL,
    Parameters JSONB NOT NULL,
    ResultData JSONB NOT NULL,
    CreationDate TIMESTAMP DEFAULT app_now() NOT NULL,
    Account_ID INT NOT NULL REFERENCES Accounts(ID_Account) ON DELETE RESTRICT,
    Template_ID INT REFERENCES InfographicTemplates(ID_Template) ON DELETE SET NULL,
    CONSTRAINT chk_chart_type_infographic CHECK (ChartType IN ('bar', 'line', 'pie', 'doughnut', 'card'))
);

-- Экспортированные результаты
CREATE TABLE ExportedFiles (
    ID_Export SERIAL PRIMARY KEY,
    FileName VARCHAR(255) NOT NULL,
    FileFormat VARCHAR(10) NOT NULL CHECK (FileFormat IN ('PNG', 'PDF', 'JPG')),
    ExportDate TIMESTAMP DEFAULT app_now() NOT NULL,
    Infographic_ID INT NOT NULL REFERENCES Infographics(ID_Infographic) ON DELETE CASCADE
);

-- Импортированные файлы
CREATE TABLE ImportFiles (
    ID_ImportFile SERIAL PRIMARY KEY,
    OriginalFileName VARCHAR(255) NOT NULL,
    FileType VARCHAR(10) NOT NULL CHECK (FileType IN ('CSV', 'XLSX')),
    ImportStatus VARCHAR(40) DEFAULT 'Загружен' NOT NULL,
    RowsTotal INT DEFAULT 0 NOT NULL CHECK (RowsTotal >= 0),
    RowsSuccess INT DEFAULT 0 NOT NULL CHECK (RowsSuccess >= 0),
    RowsFailed INT DEFAULT 0 NOT NULL CHECK (RowsFailed >= 0),
    ErrorMessage TEXT,
    ImportDate TIMESTAMP DEFAULT app_now() NOT NULL,
    Account_ID INT NOT NULL REFERENCES Accounts(ID_Account) ON DELETE RESTRICT,
    CONSTRAINT chk_import_rows CHECK (RowsSuccess + RowsFailed <= RowsTotal)
);

-- Журнал аудита
CREATE TABLE AuditLog (
    ID_AuditLog SERIAL PRIMARY KEY,
    ActionName VARCHAR(50) NOT NULL,
    EntityName VARCHAR(100) NOT NULL,
    EntityID INT NOT NULL,
    OldValue JSONB,
    NewValue JSONB,
    ActionDate TIMESTAMP DEFAULT app_now() NOT NULL,
    Account_ID INT REFERENCES Accounts(ID_Account)
);

-- Системные настройки
CREATE TABLE SystemSettings (
    ID_Setting SERIAL PRIMARY KEY,
    SettingKey VARCHAR(100) UNIQUE NOT NULL,
    SettingValue JSONB NOT NULL,
    Description TEXT
);

-- ============================================================
-- ИНДЕКСЫ
-- ============================================================

CREATE INDEX idx_accounts_role_id ON Accounts(Role_ID);
CREATE INDEX idx_accounts_email ON Accounts(Email);
CREATE INDEX idx_accounts_is_blocked ON Accounts(IsBlocked);

CREATE INDEX idx_users_account_id ON Users(Account_ID);

CREATE INDEX idx_students_group_id ON Students(Group_ID);

CREATE INDEX idx_grades_student_id ON Grades(Student_ID);
CREATE INDEX idx_grades_discipline_id ON Grades(Discipline_ID);
CREATE INDEX idx_grades_period_id ON Grades(Period_ID);

CREATE INDEX idx_attendance_student_id ON Attendance(Student_ID);
CREATE INDEX idx_attendance_discipline_id ON Attendance(Discipline_ID);
CREATE INDEX idx_attendance_period_id ON Attendance(Period_ID);

CREATE INDEX idx_infographics_account_id ON Infographics(Account_ID);
CREATE INDEX idx_infographics_template_id ON Infographics(Template_ID);

CREATE INDEX idx_auditlog_account_id ON AuditLog(Account_ID);
CREATE INDEX idx_auditlog_action_date ON AuditLog(ActionDate);

-- ============================================================
-- ПРЕДСТАВЛЕНИЯ
-- ============================================================

-- Пользователи, аккаунты и роли
CREATE OR REPLACE VIEW UsersAccountsView AS
SELECT
    u.ID_User AS "Код пользователя",
    u.LastName AS "Фамилия",
    u.FirstName AS "Имя",
    u.Patronymic AS "Отчество",
    a.ID_Account AS "Код аккаунта",
    a.Email AS "Электронная почта",
    r.RoleName AS "Роль",
    a.RegistrationDate AS "Дата регистрации",
    a.IsBlocked AS "Заблокирован"
FROM Users u
JOIN Accounts a ON u.Account_ID = a.ID_Account
JOIN Roles r ON a.Role_ID = r.ID_Role;

-- Студенты с учебными группами
CREATE OR REPLACE VIEW StudentsView AS
SELECT
    s.ID_Student AS "Код студента",
    s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS "ФИО студента",
    s.RecordBookNumber AS "Номер зачетной книжки",
    g.GroupName AS "Группа",
    g.Course AS "Курс",
    g.StudyYear AS "Учебный год",
    g.DirectionName AS "Направление подготовки"
FROM Students s
JOIN StudyGroups g ON s.Group_ID = g.ID_Group;

-- Оценки студентов
CREATE OR REPLACE VIEW GradesView AS
SELECT
    gr.ID_Grade AS "Код оценки",
    s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS "Студент",
    sg.GroupName AS "Группа",
    d.DisciplineName AS "Дисциплина",
    sp.StudyYear AS "Учебный год",
    sp.Semester AS "Семестр",
    gr.GradeValue AS "Оценка",
    gr.ControlType AS "Форма контроля",
    gr.GradeDate AS "Дата оценки"
FROM Grades gr
JOIN Students s ON gr.Student_ID = s.ID_Student
JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
JOIN Disciplines d ON gr.Discipline_ID = d.ID_Discipline
JOIN StudyPeriods sp ON gr.Period_ID = sp.ID_Period;

-- Посещаемость студентов
CREATE OR REPLACE VIEW AttendanceView AS
SELECT
    a.ID_Attendance AS "Код посещаемости",
    s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS "Студент",
    sg.GroupName AS "Группа",
    d.DisciplineName AS "Дисциплина",
    sp.StudyYear AS "Учебный год",
    sp.Semester AS "Семестр",
    a.AttendedCount AS "Посещено занятий",
    a.MissedCount AS "Пропущено занятий",
    a.AttendedCount + a.MissedCount AS "Всего занятий",
    ROUND(
        CASE
            WHEN a.AttendedCount + a.MissedCount = 0 THEN 0
            ELSE a.AttendedCount::NUMERIC / (a.AttendedCount + a.MissedCount) * 100
        END,
        2
    ) AS "Процент посещаемости"
FROM Attendance a
JOIN Students s ON a.Student_ID = s.ID_Student
JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
JOIN Disciplines d ON a.Discipline_ID = d.ID_Discipline
JOIN StudyPeriods sp ON a.Period_ID = sp.ID_Period;

-- Статистика по студентам
CREATE OR REPLACE VIEW StudentStatisticsView AS
SELECT
    s.ID_Student AS "Код студента",
    s.LastName || ' ' || s.FirstName || ' ' || COALESCE(s.Patronymic, '') AS "ФИО студента",
    sg.GroupName AS "Группа",
    ROUND(AVG(g.GradeValue), 2) AS "Средний балл",
    COUNT(g.ID_Grade) AS "Количество оценок",
    COUNT(g.ID_Grade) FILTER (WHERE g.GradeValue = 5) AS "Количество отличных оценок",
    COUNT(g.ID_Grade) FILTER (WHERE g.GradeValue = 2) AS "Количество неудовлетворительных оценок"
FROM Students s
JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
LEFT JOIN Grades g ON s.ID_Student = g.Student_ID
GROUP BY
    s.ID_Student,
    s.LastName,
    s.FirstName,
    s.Patronymic,
    sg.GroupName;

-- Сводная статистика по группам
CREATE OR REPLACE VIEW GroupStatisticsView AS
WITH StudentCounts AS (
    SELECT
        sg.ID_Group,
        COUNT(s.ID_Student) AS StudentsCount
    FROM StudyGroups sg
    LEFT JOIN Students s ON sg.ID_Group = s.Group_ID
    GROUP BY sg.ID_Group
),
GradeStats AS (
    SELECT
        sg.ID_Group,
        ROUND(AVG(g.GradeValue), 2) AS AverageGrade,
        ROUND(
            CASE
                WHEN COUNT(g.ID_Grade) = 0 THEN 0
                ELSE COUNT(g.ID_Grade) FILTER (WHERE g.GradeValue >= 3)::NUMERIC / COUNT(g.ID_Grade) * 100
            END,
            2
        ) AS SuccessRate,
        COUNT(DISTINCT s.ID_Student) FILTER (WHERE g.GradeValue = 2) AS DebtorCount,
        COUNT(DISTINCT s.ID_Student) FILTER (WHERE g.GradeValue = 5) AS ExcellentCount
    FROM StudyGroups sg
    LEFT JOIN Students s ON sg.ID_Group = s.Group_ID
    LEFT JOIN Grades g ON s.ID_Student = g.Student_ID
    GROUP BY sg.ID_Group
),
AttendanceStats AS (
    SELECT
        sg.ID_Group,
        ROUND(
            AVG(
                CASE
                    WHEN a.AttendedCount + a.MissedCount = 0 THEN 0
                    ELSE a.AttendedCount::NUMERIC / (a.AttendedCount + a.MissedCount) * 100
                END
            ),
            2
        ) AS AttendanceRate
    FROM StudyGroups sg
    LEFT JOIN Students s ON sg.ID_Group = s.Group_ID
    LEFT JOIN Attendance a ON s.ID_Student = a.Student_ID
    GROUP BY sg.ID_Group
)
SELECT
    sg.ID_Group AS "Код группы",
    sg.GroupName AS "Группа",
    sg.Course AS "Курс",
    sg.StudyYear AS "Учебный год",
    sc.StudentsCount AS "Количество студентов",
    COALESCE(gs.AverageGrade, 0) AS "Средний балл",
    COALESCE(gs.SuccessRate, 0) AS "Процент успеваемости",
    COALESCE(gs.DebtorCount, 0) AS "Количество задолженностей",
    COALESCE(gs.ExcellentCount, 0) AS "Количество отличников",
    COALESCE(ast.AttendanceRate, 0) AS "Средний процент посещаемости"
FROM StudyGroups sg
JOIN StudentCounts sc ON sg.ID_Group = sc.ID_Group
JOIN GradeStats gs ON sg.ID_Group = gs.ID_Group
JOIN AttendanceStats ast ON sg.ID_Group = ast.ID_Group;

-- Сохраненные инфографики
-- Данные заблокированных пользователей не удаляются, но скрываются из представления.
CREATE OR REPLACE VIEW InfographicsView AS
SELECT
    i.ID_Infographic AS "Код инфографики",
    i.Title AS "Название",
    i.ChartType AS "Тип диаграммы",
    t.TemplateName AS "Шаблон",
    u.LastName || ' ' || u.FirstName || ' ' || COALESCE(u.Patronymic, '') AS "Автор",
    a.Email AS "Email автора",
    i.CreationDate AS "Дата создания"
FROM Infographics i
JOIN Accounts a ON i.Account_ID = a.ID_Account
JOIN Users u ON a.ID_Account = u.Account_ID
LEFT JOIN InfographicTemplates t ON i.Template_ID = t.ID_Template
WHERE a.IsBlocked = FALSE;

-- Журнал аудита
-- В представлении отображается пользователь, который совершил действие.
-- Действия заблокированных пользователей скрываются из представления, но остаются в таблице AuditLog.
CREATE OR REPLACE VIEW AuditLogView AS
SELECT
    al.ID_AuditLog AS "Код записи",
    al.ActionName AS "Действие",
    al.EntityName AS "Таблица",
    al.EntityID AS "Код записи таблицы",
    al.OldValue AS "Старое значение",
    al.NewValue AS "Новое значение",
    al.ActionDate AS "Дата действия",
    a.ID_Account AS "Код аккаунта",
    a.Email AS "Email пользователя",
    r.RoleName AS "Роль пользователя",
    CASE
        WHEN a.ID_Account IS NULL THEN 'Система'
        WHEN TRIM(
            COALESCE(u.LastName, '') || ' ' ||
            COALESCE(u.FirstName, '') || ' ' ||
            COALESCE(u.Patronymic, '')
        ) = '' THEN a.Email
        ELSE TRIM(
            COALESCE(u.LastName, '') || ' ' ||
            COALESCE(u.FirstName, '') || ' ' ||
            COALESCE(u.Patronymic, '')
        )
    END AS "Пользователь"
FROM AuditLog al
LEFT JOIN Accounts a ON al.Account_ID = a.ID_Account
LEFT JOIN Users u ON u.Account_ID = a.ID_Account
LEFT JOIN Roles r ON a.Role_ID = r.ID_Role
WHERE a.ID_Account IS NULL
   OR a.IsBlocked = FALSE;

-- ============================================================
-- ПРОЦЕДУРЫ
-- ============================================================

-- Регистрация обычного пользователя.
-- Пароль передается в открытом виде только в процедуру,
-- а в таблицу Accounts сохраняется уже bcrypt-хэш через pgcrypto.
CREATE OR REPLACE PROCEDURE RegisterUser(
    p_email VARCHAR,
    p_password VARCHAR,
    p_last_name VARCHAR,
    p_first_name VARCHAR,
    p_patronymic VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id INT;
    v_role_id INT;
BEGIN
    IF length(trim(p_email)) = 0 THEN
        RAISE EXCEPTION 'Электронная почта не может быть пустой.';
    END IF;

    IF p_email NOT LIKE '%@%' THEN
        RAISE EXCEPTION 'Некорректный адрес электронной почты.';
    END IF;

    IF length(p_password) < 8 THEN
        RAISE EXCEPTION 'Пароль должен содержать не менее 8 символов.';
    END IF;

    IF EXISTS (SELECT 1 FROM Accounts WHERE Email = p_email) THEN
        RAISE EXCEPTION 'Пользователь с электронной почтой % уже существует.', p_email;
    END IF;

    SELECT ID_Role INTO v_role_id
    FROM Roles
    WHERE RoleName = 'Пользователь';

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Роль Пользователь не найдена.';
    END IF;

    INSERT INTO Accounts (Email, PasswordHash, Role_ID)
    VALUES (
        p_email,
        crypt(p_password, gen_salt('bf', 12)),
        v_role_id
    )
    RETURNING ID_Account INTO v_account_id;

    INSERT INTO Users (LastName, FirstName, Patronymic, Account_ID)
    VALUES (p_last_name, p_first_name, p_patronymic, v_account_id);
END;
$$;

-- Добавление студента
CREATE OR REPLACE PROCEDURE AddStudent(
    p_last_name VARCHAR,
    p_first_name VARCHAR,
    p_patronymic VARCHAR,
    p_record_book_number VARCHAR,
    p_group_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM StudyGroups WHERE ID_Group = p_group_id) THEN
        RAISE EXCEPTION 'Учебная группа с идентификатором % не найдена.', p_group_id;
    END IF;

    INSERT INTO Students (LastName, FirstName, Patronymic, RecordBookNumber, Group_ID)
    VALUES (p_last_name, p_first_name, p_patronymic, p_record_book_number, p_group_id);
END;
$$;

-- Добавление оценки
CREATE OR REPLACE PROCEDURE AddGrade(
    p_student_id INT,
    p_discipline_id INT,
    p_period_id INT,
    p_grade_value INT,
    p_control_type VARCHAR,
    p_grade_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_grade_value NOT BETWEEN 2 AND 5 THEN
        RAISE EXCEPTION 'Оценка должна быть в диапазоне от 2 до 5.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Students WHERE ID_Student = p_student_id) THEN
        RAISE EXCEPTION 'Студент с идентификатором % не найден.', p_student_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Disciplines WHERE ID_Discipline = p_discipline_id) THEN
        RAISE EXCEPTION 'Дисциплина с идентификатором % не найдена.', p_discipline_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM StudyPeriods WHERE ID_Period = p_period_id) THEN
        RAISE EXCEPTION 'Учебный период с идентификатором % не найден.', p_period_id;
    END IF;

    INSERT INTO Grades (
        GradeValue,
        ControlType,
        GradeDate,
        Student_ID,
        Discipline_ID,
        Period_ID
    )
    VALUES (
        p_grade_value,
        p_control_type,
        COALESCE(p_grade_date, CURRENT_DATE),
        p_student_id,
        p_discipline_id,
        p_period_id
    );
END;
$$;

-- Добавление посещаемости
CREATE OR REPLACE PROCEDURE AddAttendance(
    p_student_id INT,
    p_discipline_id INT,
    p_period_id INT,
    p_attended_count INT,
    p_missed_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_attended_count < 0 OR p_missed_count < 0 THEN
        RAISE EXCEPTION 'Количество посещенных и пропущенных занятий не может быть отрицательным.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Students WHERE ID_Student = p_student_id) THEN
        RAISE EXCEPTION 'Студент с идентификатором % не найден.', p_student_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Disciplines WHERE ID_Discipline = p_discipline_id) THEN
        RAISE EXCEPTION 'Дисциплина с идентификатором % не найдена.', p_discipline_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM StudyPeriods WHERE ID_Period = p_period_id) THEN
        RAISE EXCEPTION 'Учебный период с идентификатором % не найден.', p_period_id;
    END IF;

    INSERT INTO Attendance (
        AttendedCount,
        MissedCount,
        Student_ID,
        Discipline_ID,
        Period_ID
    )
    VALUES (
        p_attended_count,
        p_missed_count,
        p_student_id,
        p_discipline_id,
        p_period_id
    );
END;
$$;

-- Сохранение инфографики
CREATE OR REPLACE PROCEDURE SaveInfographic(
    p_title VARCHAR,
    p_chart_type VARCHAR,
    p_parameters JSONB,
    p_result_data JSONB,
    p_account_id INT,
    p_template_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE ID_Account = p_account_id) THEN
        RAISE EXCEPTION 'Аккаунт с идентификатором % не найден.', p_account_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM Accounts
        WHERE ID_Account = p_account_id
          AND IsBlocked = TRUE
    ) THEN
        RAISE EXCEPTION 'Аккаунт с идентификатором % заблокирован. Сохранение инфографики запрещено.', p_account_id;
    END IF;

    IF p_template_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM InfographicTemplates WHERE ID_Template = p_template_id) THEN
        RAISE EXCEPTION 'Шаблон инфографики с идентификатором % не найден.', p_template_id;
    END IF;

    IF p_chart_type NOT IN ('bar', 'line', 'pie', 'doughnut', 'card') THEN
        RAISE EXCEPTION 'Недопустимый тип диаграммы.';
    END IF;

    INSERT INTO Infographics (
        Title,
        ChartType,
        Parameters,
        ResultData,
        Account_ID,
        Template_ID
    )
    VALUES (
        p_title,
        p_chart_type,
        p_parameters,
        p_result_data,
        p_account_id,
        p_template_id
    );
END;
$$;

-- Блокировка или разблокировка аккаунта
CREATE OR REPLACE PROCEDURE SetAccountBlockStatus(
    p_account_id INT,
    p_is_blocked BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE ID_Account = p_account_id) THEN
        RAISE EXCEPTION 'Аккаунт с идентификатором % не найден.', p_account_id;
    END IF;

    UPDATE Accounts
    SET IsBlocked = p_is_blocked
    WHERE ID_Account = p_account_id;
END;
$$;

-- Изменение роли аккаунта
CREATE OR REPLACE PROCEDURE SetAccountRole(
    p_account_id INT,
    p_role_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE ID_Account = p_account_id) THEN
        RAISE EXCEPTION 'Аккаунт с идентификатором % не найден.', p_account_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Roles WHERE ID_Role = p_role_id) THEN
        RAISE EXCEPTION 'Роль с идентификатором % не найдена.', p_role_id;
    END IF;

    UPDATE Accounts
    SET Role_ID = p_role_id
    WHERE ID_Account = p_account_id;
END;
$$;

-- ============================================================
-- ФУНКЦИИ
-- ============================================================

-- Проверка пароля пользователя.
-- Возвращает строку, если email и пароль корректные.
CREATE OR REPLACE FUNCTION CheckUserPassword(
    p_email VARCHAR,
    p_password VARCHAR
)
RETURNS TABLE (
    account_id INT,
    email VARCHAR,
    role_name VARCHAR,
    is_blocked BOOLEAN,
    last_name VARCHAR,
    first_name VARCHAR,
    patronymic VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.ID_Account,
        a.Email,
        r.RoleName,
        a.IsBlocked,
        u.LastName,
        u.FirstName,
        u.Patronymic
    FROM Accounts a
    JOIN Roles r ON a.Role_ID = r.ID_Role
    JOIN Users u ON u.Account_ID = a.ID_Account
    WHERE a.Email = p_email
      AND a.PasswordHash = crypt(p_password, a.PasswordHash);
END;
$$ LANGUAGE plpgsql;

-- Средний балл группы за период
CREATE OR REPLACE FUNCTION get_group_avg_grade_period(
    p_group_id INT,
    p_period_id INT
)
RETURNS NUMERIC AS $$
DECLARE
    avg_grade NUMERIC;
BEGIN
    SELECT ROUND(AVG(g.GradeValue), 2)
    INTO avg_grade
    FROM Grades g
    JOIN Students s ON g.Student_ID = s.ID_Student
    WHERE s.Group_ID = p_group_id
      AND g.Period_ID = p_period_id;

    RETURN COALESCE(avg_grade, 0);
END;
$$ LANGUAGE plpgsql;

-- Процент успеваемости группы за период
CREATE OR REPLACE FUNCTION get_group_success_rate_period(
    p_group_id INT,
    p_period_id INT
)
RETURNS NUMERIC AS $$
DECLARE
    success_rate NUMERIC;
BEGIN
    SELECT ROUND(
        CASE
            WHEN COUNT(g.ID_Grade) = 0 THEN 0
            ELSE COUNT(g.ID_Grade) FILTER (WHERE g.GradeValue >= 3)::NUMERIC / COUNT(g.ID_Grade) * 100
        END,
        2
    )
    INTO success_rate
    FROM Grades g
    JOIN Students s ON g.Student_ID = s.ID_Student
    WHERE s.Group_ID = p_group_id
      AND g.Period_ID = p_period_id;

    RETURN COALESCE(success_rate, 0);
END;
$$ LANGUAGE plpgsql;

-- Средний процент посещаемости группы за период
CREATE OR REPLACE FUNCTION get_group_attendance_rate_period(
    p_group_id INT,
    p_period_id INT
)
RETURNS NUMERIC AS $$
DECLARE
    attendance_rate NUMERIC;
BEGIN
    SELECT ROUND(
        AVG(
            CASE
                WHEN (a.AttendedCount + a.MissedCount) = 0 THEN 0
                ELSE a.AttendedCount::NUMERIC / (a.AttendedCount + a.MissedCount) * 100
            END
        ),
        2
    )
    INTO attendance_rate
    FROM Attendance a
    JOIN Students s ON a.Student_ID = s.ID_Student
    WHERE s.Group_ID = p_group_id
      AND a.Period_ID = p_period_id;

    RETURN COALESCE(attendance_rate, 0);
END;
$$ LANGUAGE plpgsql;

-- Распределение оценок для построения диаграммы
CREATE OR REPLACE FUNCTION get_grade_distribution(
    p_group_id INT,
    p_discipline_id INT,
    p_period_id INT
)
RETURNS TABLE (
    grade_label VARCHAR,
    grade_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        g.GradeValue::VARCHAR AS grade_label,
        COUNT(g.ID_Grade) AS grade_count
    FROM Grades g
    JOIN Students s ON g.Student_ID = s.ID_Student
    WHERE s.Group_ID = p_group_id
      AND g.Discipline_ID = p_discipline_id
      AND g.Period_ID = p_period_id
    GROUP BY g.GradeValue
    ORDER BY g.GradeValue DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ТРИГГЕРНЫЕ ФУНКЦИИ
-- ============================================================

-- Проверка email
CREATE OR REPLACE FUNCTION check_account_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Email NOT LIKE '%@%' THEN
        RAISE EXCEPTION 'Некорректный адрес электронной почты: должен содержать символ @.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверка посещаемости
CREATE OR REPLACE FUNCTION check_attendance_values()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.AttendedCount < 0 OR NEW.MissedCount < 0 THEN
        RAISE EXCEPTION 'Количество посещенных и пропущенных занятий не может быть отрицательным.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Аудит изменений
CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER AS $$
DECLARE
    key_field TEXT;
    key_value INT;
    current_account_id INT;
BEGIN
    SELECT column_name
    INTO key_field
    FROM information_schema.columns
    WHERE table_name = TG_TABLE_NAME
      AND column_name ILIKE 'id_%'
    ORDER BY ordinal_position
    LIMIT 1;

    BEGIN
        current_account_id := NULLIF(current_setting('app.current_account_id', true), '')::INT;
    EXCEPTION
        WHEN OTHERS THEN
            current_account_id := NULL;
    END;

    IF TG_OP = 'INSERT' THEN
        EXECUTE format('SELECT ($1).%I', key_field)
        INTO key_value
        USING NEW;

        INSERT INTO AuditLog (
            ActionName,
            EntityName,
            EntityID,
            OldValue,
            NewValue,
            Account_ID
        )
        VALUES (
            'INSERT',
            TG_TABLE_NAME,
            key_value,
            NULL,
            row_to_json(NEW)::JSONB,
            current_account_id
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        EXECUTE format('SELECT ($1).%I', key_field)
        INTO key_value
        USING NEW;

        INSERT INTO AuditLog (
            ActionName,
            EntityName,
            EntityID,
            OldValue,
            NewValue,
            Account_ID
        )
        VALUES (
            'UPDATE',
            TG_TABLE_NAME,
            key_value,
            row_to_json(OLD)::JSONB,
            row_to_json(NEW)::JSONB,
            current_account_id
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE format('SELECT ($1).%I', key_field)
        INTO key_value
        USING OLD;

        INSERT INTO AuditLog (
            ActionName,
            EntityName,
            EntityID,
            OldValue,
            NewValue,
            Account_ID
        )
        VALUES (
            'DELETE',
            TG_TABLE_NAME,
            key_value,
            row_to_json(OLD)::JSONB,
            NULL,
            current_account_id
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ТРИГГЕРЫ
-- ============================================================

CREATE TRIGGER trg_check_account_email
BEFORE INSERT OR UPDATE ON Accounts
FOR EACH ROW
EXECUTE FUNCTION check_account_email();

CREATE TRIGGER trg_check_attendance_values
BEFORE INSERT OR UPDATE ON Attendance
FOR EACH ROW
EXECUTE FUNCTION check_attendance_values();

CREATE TRIGGER trg_roles_audit
AFTER INSERT OR UPDATE OR DELETE ON Roles
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_accounts_audit
AFTER INSERT OR UPDATE OR DELETE ON Accounts
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON Users
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_study_groups_audit
AFTER INSERT OR UPDATE OR DELETE ON StudyGroups
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_students_audit
AFTER INSERT OR UPDATE OR DELETE ON Students
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_disciplines_audit
AFTER INSERT OR UPDATE OR DELETE ON Disciplines
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_study_periods_audit
AFTER INSERT OR UPDATE OR DELETE ON StudyPeriods
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_grades_audit
AFTER INSERT OR UPDATE OR DELETE ON Grades
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_attendance_audit
AFTER INSERT OR UPDATE OR DELETE ON Attendance
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_infographic_templates_audit
AFTER INSERT OR UPDATE OR DELETE ON InfographicTemplates
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_infographics_audit
AFTER INSERT OR UPDATE OR DELETE ON Infographics
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_exported_files_audit
AFTER INSERT OR UPDATE OR DELETE ON ExportedFiles
FOR EACH ROW
EXECUTE FUNCTION log_changes();

CREATE TRIGGER trg_import_files_audit
AFTER INSERT OR UPDATE OR DELETE ON ImportFiles
FOR EACH ROW
EXECUTE FUNCTION log_changes();

-- ============================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ============================================================

-- Роли
INSERT INTO Roles (RoleName) VALUES
('Администратор'),
('Пользователь');

-- Аккаунты
-- Пароли:
-- admin@infographic.ru / Admin123!
-- user@infographic.ru  / User123!
INSERT INTO Accounts (Email, PasswordHash, Role_ID) VALUES
(
    'admin@infographic.ru',
    crypt('Admin123!', gen_salt('bf', 12)),
    1
),
(
    'user@infographic.ru',
    crypt('User123!', gen_salt('bf', 12)),
    2
);

-- Пользователи
INSERT INTO Users (LastName, FirstName, Patronymic, Account_ID) VALUES
('Овцунова', 'Анастасия', 'Александровна', 1),
('Иванова', 'Мария', 'Сергеевна', 2);

-- Учебные группы
INSERT INTO StudyGroups (GroupName, Course, StudyYear, DirectionName) VALUES
('ИС-31', 3, '2025/2026', 'Информационные системы и программирование'),
('ИС-32', 3, '2025/2026', 'Информационные системы и программирование'),
('ПР-21', 2, '2025/2026', 'Программирование в компьютерных системах');

-- Студенты
INSERT INTO Students (LastName, FirstName, Patronymic, RecordBookNumber, Group_ID) VALUES
('Петров', 'Алексей', 'Игоревич', 'ИС31001', 1),
('Смирнова', 'Екатерина', 'Олеговна', 'ИС31002', 1),
('Кузнецов', 'Дмитрий', 'Андреевич', 'ИС31003', 1),
('Соколова', 'Анна', 'Павловна', 'ИС32001', 2),
('Морозов', 'Никита', 'Владимирович', 'ИС32002', 2),
('Волкова', 'Дарья', 'Романовна', 'ПР21001', 3);

-- Дисциплины
INSERT INTO Disciplines (DisciplineName, Description, TeacherName) VALUES
('Базы данных', 'Проектирование и сопровождение реляционных баз данных', 'Комаров А. А.'),
('Web-программирование', 'Разработка клиент-серверных веб-приложений', 'Бойцова Е. Ю.'),
('МДК 02.01 Технология разработки программного обеспечения', 'Интеграция программных модулей', 'Шестакова О. Н.');

-- Учебные периоды
INSERT INTO StudyPeriods (StudyYear, Semester, StartDate, EndDate) VALUES
('2025/2026', 5, '2025-09-01', '2025-12-31'),
('2025/2026', 6, '2026-02-01', '2026-06-30');

-- Оценки
INSERT INTO Grades (GradeValue, ControlType, GradeDate, Student_ID, Discipline_ID, Period_ID) VALUES
(5, 'Экзамен', '2025-12-20', 1, 1, 1),
(4, 'Экзамен', '2025-12-20', 2, 1, 1),
(3, 'Экзамен', '2025-12-20', 3, 1, 1),
(5, 'Экзамен', '2025-12-20', 4, 1, 1),
(2, 'Экзамен', '2025-12-20', 5, 1, 1),
(4, 'Экзамен', '2025-12-20', 6, 2, 1);

-- Посещаемость
INSERT INTO Attendance (AttendedCount, MissedCount, Student_ID, Discipline_ID, Period_ID) VALUES
(28, 2, 1, 1, 1),
(25, 5, 2, 1, 1),
(21, 9, 3, 1, 1),
(30, 0, 4, 1, 1),
(18, 12, 5, 1, 1),
(26, 4, 6, 2, 1);

-- Шаблоны инфографики
INSERT INTO InfographicTemplates (TemplateName, ChartType, ColorScheme, Description, IsActive) VALUES
('Столбчатая диаграмма успеваемости', 'bar', 'blue', 'Шаблон для отображения распределения оценок', TRUE),
('Круговая диаграмма показателей', 'pie', 'green', 'Шаблон для отображения долей показателей', TRUE),
('Линейная диаграмма динамики', 'line', 'purple', 'Шаблон для отображения изменения показателей по периодам', TRUE),
('Карточки ключевых показателей', 'card', 'default', 'Шаблон для среднего балла, посещаемости и успеваемости', TRUE);

-- Сохраненная инфографика
-- Формат ResultData соответствует клиентскому разделу "Сохранённые инфографики":
-- cards отображаются как карточки показателей, chartItems используются для построения диаграммы.
INSERT INTO Infographics (Title, ChartType, Parameters, ResultData, Account_ID, Template_ID) VALUES
(
    'Распределение оценок группы ИС-31',
    'bar',
    jsonb_build_object(
        'groupId', 1,
        'disciplineId', 1,
        'periodId', 1,
        'chartType', 'gradeDistribution',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', TRUE,
        'sortOrder', 'source'
    ),
    jsonb_build_object(
        'title', 'Распределение оценок',
        'subtitle', 'ИС-31 • Базы данных • 2025/2026, семестр 5',
        'chartType', 'gradeDistribution',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', TRUE,
        'sortOrder', 'source',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Средний балл', 'value', '4'),
            jsonb_build_object('title', 'Успеваемость', 'value', '100%'),
            jsonb_build_object('title', 'Средняя посещаемость', 'value', '82.2%'),
            jsonb_build_object('title', 'Задолженности', 'value', '0'),
            jsonb_build_object('title', 'Оценок «5»', 'value', '1'),
            jsonb_build_object('title', 'Записей посещаемости', 'value', '3')
        ),
        'chartItems', jsonb_build_array(
            jsonb_build_object('label', 'Оценка 5', 'value', 1),
            jsonb_build_object('label', 'Оценка 4', 'value', 1),
            jsonb_build_object('label', 'Оценка 3', 'value', 1),
            jsonb_build_object('label', 'Оценка 2', 'value', 0)
        )
    ),
    2,
    1
);

-- Экспортированный файл
INSERT INTO ExportedFiles (FileName, FileFormat, Infographic_ID) VALUES
('grades_is_31.png', 'PNG', 1);

-- Импортированный файл
INSERT INTO ImportFiles (
    OriginalFileName,
    FileType,
    ImportStatus,
    RowsTotal,
    RowsSuccess,
    RowsFailed,
    ErrorMessage,
    Account_ID
)
VALUES
(
    'students_statistics.xlsx',
    'XLSX',
    'Успешно',
    6,
    6,
    0,
    NULL,
    2
);

-- Системные настройки
INSERT INTO SystemSettings (SettingKey, SettingValue, Description) VALUES
(
    'available_export_formats',
    '["PNG", "PDF", "JPG"]'::JSONB,
    'Доступные форматы экспорта инфографики'
),
(
    'default_chart_type',
    '"bar"'::JSONB,
    'Тип диаграммы по умолчанию'
),
(
    'default_color_scheme',
    '"blue"'::JSONB,
    'Цветовая схема по умолчанию'
);

-- ============================================================
-- СКРЫТИЕ ДАННЫХ ЗАБЛОКИРОВАННЫХ ПОЛЬЗОВАТЕЛЕЙ И АУДИТ ДЕЙСТВИЙ
-- ============================================================
-- Данный скрипт не удаляет данные заблокированных пользователей.
-- Он изменяет представления так, чтобы данные и действия заблокированных
-- аккаунтов не отображались в пользовательских и административных выборках.
-- В журнале аудита дополнительно отображается пользователь, совершивший действие.
-- ============================================================

CREATE OR REPLACE VIEW InfographicsView AS
SELECT
    i.ID_Infographic AS "Код инфографики",
    i.Title AS "Название",
    i.ChartType AS "Тип диаграммы",
    t.TemplateName AS "Шаблон",
    u.LastName || ' ' || u.FirstName || ' ' || COALESCE(u.Patronymic, '') AS "Автор",
    a.Email AS "Email автора",
    i.CreationDate AS "Дата создания"
FROM Infographics i
JOIN Accounts a ON i.Account_ID = a.ID_Account
JOIN Users u ON a.ID_Account = u.Account_ID
LEFT JOIN InfographicTemplates t ON i.Template_ID = t.ID_Template
WHERE a.IsBlocked = FALSE;

CREATE OR REPLACE VIEW AuditLogView AS
SELECT
    al.ID_AuditLog AS "Код записи",
    al.ActionName AS "Действие",
    al.EntityName AS "Таблица",
    al.EntityID AS "Код записи таблицы",
    al.OldValue AS "Старое значение",
    al.NewValue AS "Новое значение",
    al.ActionDate AS "Дата действия",
    a.ID_Account AS "Код аккаунта",
    a.Email AS "Email пользователя",
    r.RoleName AS "Роль пользователя",
    CASE
        WHEN a.ID_Account IS NULL THEN 'Система'
        WHEN TRIM(
            COALESCE(u.LastName, '') || ' ' ||
            COALESCE(u.FirstName, '') || ' ' ||
            COALESCE(u.Patronymic, '')
        ) = '' THEN a.Email
        ELSE TRIM(
            COALESCE(u.LastName, '') || ' ' ||
            COALESCE(u.FirstName, '') || ' ' ||
            COALESCE(u.Patronymic, '')
        )
    END AS "Пользователь"
FROM AuditLog al
LEFT JOIN Accounts a ON al.Account_ID = a.ID_Account
LEFT JOIN Users u ON u.Account_ID = a.ID_Account
LEFT JOIN Roles r ON a.Role_ID = r.ID_Role
WHERE a.ID_Account IS NULL
   OR a.IsBlocked = FALSE;

-- ============================================================
-- ============================================================
-- ДОПОЛНИТЕЛЬНЫЕ ТЕСТОВЫЕ ДАННЫЕ
-- для веб-приложения генерации инфографики по учебной статистике
-- ============================================================
-- Назначение:
-- 1. Добавить больше учебных групп, студентов, дисциплин и периодов.
-- 2. Заполнить оценки и посещаемость большим количеством записей.
-- 3. Добавить несколько сохранённых инфографик в новом формате клиента.
-- 4. Добавить тестовые записи импорта и экспорта.
--
-- Запускать после основного файла создания БД:
--   InfographicAppDB_checked.sql
--
-- Скрипт можно запускать повторно: основные справочники обновляются,
-- оценки и посещаемость обновляются по уникальным ограничениям,
-- тестовые сохранённые инфографики предварительно пересоздаются.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

-- ============================================================
-- 1. Роли и дополнительные тестовые аккаунты
-- ============================================================

INSERT INTO Roles (RoleName)
VALUES
    ('Администратор'),
    ('Пользователь')
ON CONFLICT (RoleName) DO NOTHING;

DO $$
DECLARE
    v_user_role_id INT;
    v_account_id INT;
BEGIN
    SELECT ID_Role
    INTO v_user_role_id
    FROM Roles
    WHERE RoleName = 'Пользователь';

    IF v_user_role_id IS NULL THEN
        RAISE EXCEPTION 'Роль Пользователь не найдена.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE Email = 'teacher@infographic.ru') THEN
        INSERT INTO Accounts (Email, PasswordHash, Role_ID)
        VALUES (
            'teacher@infographic.ru',
            crypt('Teacher123!', gen_salt('bf', 12)),
            v_user_role_id
        )
        RETURNING ID_Account INTO v_account_id;

        INSERT INTO Users (LastName, FirstName, Patronymic, Account_ID)
        VALUES ('Соколова', 'Наталья', 'Игоревна', v_account_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE Email = 'analyst@infographic.ru') THEN
        INSERT INTO Accounts (Email, PasswordHash, Role_ID)
        VALUES (
            'analyst@infographic.ru',
            crypt('Analyst123!', gen_salt('bf', 12)),
            v_user_role_id
        )
        RETURNING ID_Account INTO v_account_id;

        INSERT INTO Users (LastName, FirstName, Patronymic, Account_ID)
        VALUES ('Мельников', 'Павел', 'Андреевич', v_account_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Accounts WHERE Email = 'blocked@infographic.ru') THEN
        INSERT INTO Accounts (Email, PasswordHash, Role_ID, IsBlocked)
        VALUES (
            'blocked@infographic.ru',
            crypt('Blocked123!', gen_salt('bf', 12)),
            v_user_role_id,
            TRUE
        )
        RETURNING ID_Account INTO v_account_id;

        INSERT INTO Users (LastName, FirstName, Patronymic, Account_ID)
        VALUES ('Заблокированная', 'Ольга', 'Петровна', v_account_id);
    END IF;
END;
$$;

-- Устанавливаем автора действий для аудита при ручном запуске скрипта.
SELECT set_config(
    'app.current_account_id',
    COALESCE(
        (SELECT ID_Account::TEXT FROM Accounts WHERE Email = 'admin@infographic.ru' LIMIT 1),
        ''
    ),
    false
);

-- ============================================================
-- 2. Учебные группы
-- ============================================================

INSERT INTO StudyGroups (GroupName, Course, StudyYear, DirectionName)
VALUES
    ('ИС-31', 3, '2025/2026', 'Информационные системы и программирование'),
    ('ИС-32', 3, '2025/2026', 'Информационные системы и программирование'),
    ('ИС-33', 3, '2025/2026', 'Информационные системы и программирование'),
    ('ИС-34', 3, '2025/2026', 'Информационные системы и программирование'),
    ('ПР-21', 2, '2025/2026', 'Программирование в компьютерных системах'),
    ('ПР-22', 2, '2025/2026', 'Программирование в компьютерных системах'),
    ('ВЕБ-11', 1, '2025/2026', 'Веб-разработка'),
    ('ВЕБ-12', 1, '2025/2026', 'Веб-разработка'),
    ('ДИ-41', 4, '2025/2026', 'Дизайн интерфейсов'),
    ('БД-31', 3, '2025/2026', 'Администрирование баз данных')
ON CONFLICT (GroupName) DO UPDATE
SET
    Course = EXCLUDED.Course,
    StudyYear = EXCLUDED.StudyYear,
    DirectionName = EXCLUDED.DirectionName;

-- ============================================================
-- 3. Дисциплины
-- ============================================================

INSERT INTO Disciplines (DisciplineName, Description, TeacherName)
VALUES
    ('Базы данных', 'Проектирование и сопровождение реляционных баз данных', 'Комаров А. А.'),
    ('Web-программирование', 'Разработка клиент-серверных веб-приложений', 'Бойцова Е. Ю.'),
    ('МДК 02.01 Технология разработки программного обеспечения', 'Интеграция программных модулей', 'Шестакова О. Н.'),
    ('Алгоритмы и структуры данных', 'Изучение алгоритмов обработки данных и структур хранения', 'Васильев П. И.'),
    ('Компьютерные сети', 'Основы сетевого взаимодействия и сетевых протоколов', 'Орлова Е. А.'),
    ('Информационная безопасность', 'Основы защиты информации и безопасной разработки', 'Кузнецов Д. В.'),
    ('Проектирование информационных систем', 'Анализ предметной области и проектирование ИС', 'Морозова И. Н.'),
    ('Математическая статистика', 'Статистическая обработка данных и анализ показателей', 'Смирнов А. Л.'),
    ('Анализ данных', 'Методы анализа, агрегации и визуализации данных', 'Федорова Н. С.'),
    ('Основы UI/UX', 'Проектирование пользовательских интерфейсов', 'Егорова М. П.')
ON CONFLICT (DisciplineName) DO UPDATE
SET
    Description = EXCLUDED.Description,
    TeacherName = EXCLUDED.TeacherName;

-- ============================================================
-- 4. Учебные периоды
-- ============================================================

INSERT INTO StudyPeriods (StudyYear, Semester, StartDate, EndDate)
VALUES
    ('2024/2025', 3, '2024-09-01', '2024-12-31'),
    ('2024/2025', 4, '2025-02-01', '2025-06-30'),
    ('2025/2026', 5, '2025-09-01', '2025-12-31'),
    ('2025/2026', 6, '2026-02-01', '2026-06-30'),
    ('2026/2027', 7, '2026-09-01', '2026-12-31')
ON CONFLICT (StudyYear, Semester) DO UPDATE
SET
    StartDate = EXCLUDED.StartDate,
    EndDate = EXCLUDED.EndDate;

-- ============================================================
-- 5. Студенты
-- ============================================================
-- Добавляется примерно 80 дополнительных студентов.
-- Номера зачётных книжек TEST0001...TEST0080 позволяют безопасно
-- запускать скрипт повторно без дублирования студентов.
-- ============================================================

DO $$
DECLARE
    v_group RECORD;
    v_index INT;
    v_sequence INT := 1;
    v_record_book VARCHAR(30);
    v_last_names TEXT[] := ARRAY[
        'Алексеева', 'Белов', 'Васильева', 'Громов', 'Денисова', 'Елисеев', 'Жукова', 'Зайцев',
        'Ильина', 'Ковалев', 'Лебедева', 'Макаров', 'Никитина', 'Орлов', 'Павлова', 'Романов',
        'Семенова', 'Тимофеев', 'Уварова', 'Фролов', 'Харитонова', 'Цветков', 'Чернова', 'Широков'
    ];
    v_first_names TEXT[] := ARRAY[
        'Артём', 'Мария', 'Дмитрий', 'Анна', 'Иван', 'Екатерина', 'Никита', 'Софья',
        'Максим', 'Дарья', 'Александр', 'Полина', 'Михаил', 'Виктория', 'Кирилл', 'Елизавета',
        'Роман', 'Алина', 'Павел', 'Ксения', 'Глеб', 'Вероника', 'Матвей', 'Анастасия'
    ];
    v_patronymics TEXT[] := ARRAY[
        'Алексеевич', 'Сергеевна', 'Дмитриевич', 'Игоревна', 'Павлович', 'Олеговна', 'Владимирович', 'Андреевна',
        'Романович', 'Максимовна', 'Петрович', 'Николаевна', 'Евгеньевич', 'Викторовна', 'Артурович', 'Михайловна',
        'Денисович', 'Кирилловна', 'Ильич', 'Александровна', 'Станиславович', 'Юрьевна', 'Львович', 'Павловна'
    ];
BEGIN
    FOR v_group IN
        SELECT ID_Group, GroupName
        FROM StudyGroups
        WHERE GroupName IN ('ИС-31', 'ИС-32', 'ИС-33', 'ИС-34', 'ПР-21', 'ПР-22', 'ВЕБ-11', 'ВЕБ-12', 'ДИ-41', 'БД-31')
        ORDER BY GroupName
    LOOP
        FOR v_index IN 1..8 LOOP
            v_record_book := 'TEST' || LPAD(v_sequence::TEXT, 4, '0');

            INSERT INTO Students (
                LastName,
                FirstName,
                Patronymic,
                RecordBookNumber,
                Group_ID
            )
            VALUES (
                v_last_names[((v_sequence - 1) % array_length(v_last_names, 1)) + 1],
                v_first_names[((v_sequence - 1) % array_length(v_first_names, 1)) + 1],
                v_patronymics[((v_sequence - 1) % array_length(v_patronymics, 1)) + 1],
                v_record_book,
                v_group.ID_Group
            )
            ON CONFLICT (RecordBookNumber) DO UPDATE
            SET
                LastName = EXCLUDED.LastName,
                FirstName = EXCLUDED.FirstName,
                Patronymic = EXCLUDED.Patronymic,
                Group_ID = EXCLUDED.Group_ID;

            v_sequence := v_sequence + 1;
        END LOOP;
    END LOOP;
END;
$$;

-- ============================================================
-- 6. Оценки
-- ============================================================
-- Заполняются оценки по всем тестовым студентам, дисциплинам и периодам.
-- Данные специально неоднородные, чтобы графики отличались по группам.
-- ============================================================

INSERT INTO Grades (
    GradeValue,
    ControlType,
    GradeDate,
    Student_ID,
    Discipline_ID,
    Period_ID
)
SELECT
    CASE
        WHEN sg.GroupName IN ('ИС-31', 'ДИ-41') THEN 3 + ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 3)
        WHEN sg.GroupName IN ('ПР-21', 'ВЕБ-11') THEN 2 + ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 4)
        WHEN sg.GroupName IN ('БД-31') THEN 4 + ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 2)
        ELSE 2 + ((s.ID_Student + d.ID_Discipline + sp.ID_Period + sg.ID_Group) % 4)
    END AS GradeValue,
    CASE
        WHEN d.ID_Discipline % 3 = 0 THEN 'Контрольная работа'
        WHEN d.ID_Discipline % 2 = 0 THEN 'Зачёт'
        ELSE 'Экзамен'
    END AS ControlType,
    LEAST(
        sp.EndDate,
        (sp.StartDate + (((s.ID_Student + d.ID_Discipline) % 95) * INTERVAL '1 day'))::DATE
    ) AS GradeDate,
    s.ID_Student,
    d.ID_Discipline,
    sp.ID_Period
FROM Students s
JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
CROSS JOIN Disciplines d
CROSS JOIN StudyPeriods sp
WHERE s.RecordBookNumber LIKE 'TEST%'
ON CONFLICT ON CONSTRAINT uq_grade_student_discipline_period DO UPDATE
SET
    GradeValue = EXCLUDED.GradeValue,
    GradeDate = EXCLUDED.GradeDate;

-- ============================================================
-- 7. Посещаемость
-- ============================================================
-- Заполняется посещаемость по всем тестовым студентам, дисциплинам и периодам.
-- ============================================================

INSERT INTO Attendance (
    AttendedCount,
    MissedCount,
    Student_ID,
    Discipline_ID,
    Period_ID
)
SELECT
    GREATEST(
        0,
        (24 + ((d.ID_Discipline + sp.ID_Period) % 12))
        - CASE
            WHEN sg.GroupName IN ('БД-31', 'ИС-31') THEN ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 4)
            WHEN sg.GroupName IN ('ПР-22', 'ВЕБ-12') THEN ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 9)
            ELSE ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 7)
          END
    ) AS AttendedCount,
    CASE
        WHEN sg.GroupName IN ('БД-31', 'ИС-31') THEN ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 4)
        WHEN sg.GroupName IN ('ПР-22', 'ВЕБ-12') THEN ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 9)
        ELSE ((s.ID_Student + d.ID_Discipline + sp.ID_Period) % 7)
    END AS MissedCount,
    s.ID_Student,
    d.ID_Discipline,
    sp.ID_Period
FROM Students s
JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
CROSS JOIN Disciplines d
CROSS JOIN StudyPeriods sp
WHERE s.RecordBookNumber LIKE 'TEST%'
ON CONFLICT ON CONSTRAINT uq_attendance_student_discipline_period DO UPDATE
SET
    AttendedCount = EXCLUDED.AttendedCount,
    MissedCount = EXCLUDED.MissedCount;

-- ============================================================
-- 8. Тестовые сохранённые инфографики
-- ============================================================
-- Старые тестовые инфографики с этими названиями пересоздаются,
-- чтобы не копились дубли при повторном запуске скрипта.
-- ============================================================

DELETE FROM Infographics
WHERE Title IN (
    'Тест: распределение оценок ИС-31',
    'Тест: средний балл по группам',
    'Тест: посещаемость по группам',
    'Тест: круговая диаграмма оценок',
    'Тест: сравнение групп по успеваемости'
);

-- 8.1 Распределение оценок по ИС-31 / Базы данных / 5 семестр
INSERT INTO Infographics (
    Title,
    ChartType,
    Parameters,
    ResultData,
    Account_ID,
    Template_ID
)
WITH base AS (
    SELECT
        g.GradeValue,
        COUNT(*)::NUMERIC AS GradeCount
    FROM Grades g
    JOIN Students s ON g.Student_ID = s.ID_Student
    JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
    JOIN Disciplines d ON g.Discipline_ID = d.ID_Discipline
    JOIN StudyPeriods sp ON g.Period_ID = sp.ID_Period
    WHERE sg.GroupName = 'ИС-31'
      AND d.DisciplineName = 'Базы данных'
      AND sp.StudyYear = '2025/2026'
      AND sp.Semester = 5
    GROUP BY g.GradeValue
), metrics AS (
    SELECT
        ROUND(AVG(g.GradeValue), 2) AS avg_grade,
        ROUND(COUNT(*) FILTER (WHERE g.GradeValue >= 3)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1) AS success_rate,
        COUNT(*) AS grades_count
    FROM Grades g
    JOIN Students s ON g.Student_ID = s.ID_Student
    JOIN StudyGroups sg ON s.Group_ID = sg.ID_Group
    JOIN Disciplines d ON g.Discipline_ID = d.ID_Discipline
    JOIN StudyPeriods sp ON g.Period_ID = sp.ID_Period
    WHERE sg.GroupName = 'ИС-31'
      AND d.DisciplineName = 'Базы данных'
      AND sp.StudyYear = '2025/2026'
      AND sp.Semester = 5
)
SELECT
    'Тест: распределение оценок ИС-31',
    'bar',
    jsonb_build_object(
        'groupId', (SELECT ID_Group FROM StudyGroups WHERE GroupName = 'ИС-31'),
        'disciplineId', (SELECT ID_Discipline FROM Disciplines WHERE DisciplineName = 'Базы данных'),
        'periodId', (SELECT ID_Period FROM StudyPeriods WHERE StudyYear = '2025/2026' AND Semester = 5),
        'chartType', 'gradeDistribution',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', true,
        'sortOrder', 'source'
    ),
    jsonb_build_object(
        'title', 'Распределение оценок',
        'subtitle', 'ИС-31 • Базы данных • 2025/2026, семестр 5',
        'chartType', 'gradeDistribution',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', true,
        'sortOrder', 'source',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Средний балл', 'value', COALESCE((SELECT avg_grade::TEXT FROM metrics), '0')),
            jsonb_build_object('title', 'Успеваемость', 'value', COALESCE((SELECT success_rate::TEXT || '%' FROM metrics), '0%')),
            jsonb_build_object('title', 'Количество оценок', 'value', COALESCE((SELECT grades_count::TEXT FROM metrics), '0'))
        ),
        'chartItems', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'label', 'Оценка ' || grades.GradeValue,
                    'value', COALESCE(base.GradeCount, 0)
                )
                ORDER BY grades.GradeValue
            )
            FROM generate_series(2, 5) AS grades(GradeValue)
            LEFT JOIN base ON base.GradeValue = grades.GradeValue
        )
    ),
    (SELECT ID_Account FROM Accounts WHERE Email = 'user@infographic.ru'),
    (SELECT ID_Template FROM InfographicTemplates WHERE ChartType = 'bar' ORDER BY ID_Template LIMIT 1);

-- 8.2 Средний балл по группам
INSERT INTO Infographics (
    Title,
    ChartType,
    Parameters,
    ResultData,
    Account_ID,
    Template_ID
)
WITH group_values AS (
    SELECT
        sg.GroupName,
        ROUND(AVG(g.GradeValue), 2)::NUMERIC AS AverageGrade
    FROM StudyGroups sg
    JOIN Students s ON s.Group_ID = sg.ID_Group
    JOIN Grades g ON g.Student_ID = s.ID_Student
    GROUP BY sg.GroupName
)
SELECT
    'Тест: средний балл по группам',
    'line',
    jsonb_build_object(
        'groupId', NULL,
        'disciplineId', NULL,
        'periodId', NULL,
        'chartType', 'averageGradeByGroup',
        'visualType', 'line',
        'colorScheme', 'purple',
        'showLabels', true,
        'sortOrder', 'descending'
    ),
    jsonb_build_object(
        'title', 'Средний балл по группам',
        'subtitle', 'Все группы • Все дисциплины • Все периоды',
        'chartType', 'averageGradeByGroup',
        'visualType', 'line',
        'colorScheme', 'purple',
        'showLabels', true,
        'sortOrder', 'descending',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Групп в сравнении', 'value', (SELECT COUNT(*)::TEXT FROM group_values)),
            jsonb_build_object('title', 'Лучший средний балл', 'value', (SELECT COALESCE(MAX(AverageGrade)::TEXT, '0') FROM group_values)),
            jsonb_build_object('title', 'Общий средний балл', 'value', (SELECT COALESCE(ROUND(AVG(AverageGrade), 2)::TEXT, '0') FROM group_values))
        ),
        'chartItems', (
            SELECT jsonb_agg(
                jsonb_build_object('label', GroupName, 'value', AverageGrade)
                ORDER BY AverageGrade DESC
            )
            FROM group_values
        )
    ),
    (SELECT ID_Account FROM Accounts WHERE Email = 'teacher@infographic.ru'),
    (SELECT ID_Template FROM InfographicTemplates WHERE ChartType = 'line' ORDER BY ID_Template LIMIT 1);

-- 8.3 Посещаемость по группам
INSERT INTO Infographics (
    Title,
    ChartType,
    Parameters,
    ResultData,
    Account_ID,
    Template_ID
)
WITH attendance_values AS (
    SELECT
        sg.GroupName,
        ROUND(
            AVG(
                CASE
                    WHEN a.AttendedCount + a.MissedCount = 0 THEN 0
                    ELSE a.AttendedCount::NUMERIC / (a.AttendedCount + a.MissedCount) * 100
                END
            ),
            2
        )::NUMERIC AS AttendanceRate
    FROM StudyGroups sg
    JOIN Students s ON s.Group_ID = sg.ID_Group
    JOIN Attendance a ON a.Student_ID = s.ID_Student
    GROUP BY sg.GroupName
)
SELECT
    'Тест: посещаемость по группам',
    'bar',
    jsonb_build_object(
        'groupId', NULL,
        'disciplineId', NULL,
        'periodId', NULL,
        'chartType', 'attendanceByGroup',
        'visualType', 'bar',
        'colorScheme', 'green',
        'showLabels', true,
        'sortOrder', 'descending'
    ),
    jsonb_build_object(
        'title', 'Посещаемость по группам',
        'subtitle', 'Все группы • Все дисциплины • Все периоды',
        'chartType', 'attendanceByGroup',
        'visualType', 'bar',
        'colorScheme', 'green',
        'showLabels', true,
        'sortOrder', 'descending',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Групп в сравнении', 'value', (SELECT COUNT(*)::TEXT FROM attendance_values)),
            jsonb_build_object('title', 'Максимальная посещаемость', 'value', (SELECT COALESCE(MAX(AttendanceRate)::TEXT || '%', '0%') FROM attendance_values)),
            jsonb_build_object('title', 'Средняя посещаемость', 'value', (SELECT COALESCE(ROUND(AVG(AttendanceRate), 2)::TEXT || '%', '0%') FROM attendance_values))
        ),
        'chartItems', (
            SELECT jsonb_agg(
                jsonb_build_object('label', GroupName, 'value', AttendanceRate)
                ORDER BY AttendanceRate DESC
            )
            FROM attendance_values
        )
    ),
    (SELECT ID_Account FROM Accounts WHERE Email = 'analyst@infographic.ru'),
    (SELECT ID_Template FROM InfographicTemplates WHERE ChartType = 'bar' ORDER BY ID_Template LIMIT 1);

-- 8.4 Круговая диаграмма оценок
INSERT INTO Infographics (
    Title,
    ChartType,
    Parameters,
    ResultData,
    Account_ID,
    Template_ID
)
WITH distribution AS (
    SELECT
        g.GradeValue,
        COUNT(*)::NUMERIC AS GradeCount
    FROM Grades g
    GROUP BY g.GradeValue
)
SELECT
    'Тест: круговая диаграмма оценок',
    'pie',
    jsonb_build_object(
        'groupId', NULL,
        'disciplineId', NULL,
        'periodId', NULL,
        'chartType', 'gradeDistribution',
        'visualType', 'pie',
        'colorScheme', 'orange',
        'showLabels', true,
        'sortOrder', 'source'
    ),
    jsonb_build_object(
        'title', 'Распределение оценок',
        'subtitle', 'Все группы • Все дисциплины • Все периоды',
        'chartType', 'gradeDistribution',
        'visualType', 'pie',
        'colorScheme', 'orange',
        'showLabels', true,
        'sortOrder', 'source',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Всего оценок', 'value', (SELECT COALESCE(SUM(GradeCount)::TEXT, '0') FROM distribution)),
            jsonb_build_object('title', 'Оценок «5»', 'value', (SELECT COALESCE(SUM(GradeCount) FILTER (WHERE GradeValue = 5)::TEXT, '0') FROM distribution)),
            jsonb_build_object('title', 'Оценок «2»', 'value', (SELECT COALESCE(SUM(GradeCount) FILTER (WHERE GradeValue = 2)::TEXT, '0') FROM distribution))
        ),
        'chartItems', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'label', 'Оценка ' || grades.GradeValue,
                    'value', COALESCE(distribution.GradeCount, 0)
                )
                ORDER BY grades.GradeValue
            )
            FROM generate_series(2, 5) AS grades(GradeValue)
            LEFT JOIN distribution ON distribution.GradeValue = grades.GradeValue
        )
    ),
    (SELECT ID_Account FROM Accounts WHERE Email = 'user@infographic.ru'),
    (SELECT ID_Template FROM InfographicTemplates WHERE ChartType = 'pie' ORDER BY ID_Template LIMIT 1);

-- 8.5 Сравнение групп по успеваемости
INSERT INTO Infographics (
    Title,
    ChartType,
    Parameters,
    ResultData,
    Account_ID,
    Template_ID
)
WITH success_values AS (
    SELECT
        sg.GroupName,
        ROUND(
            COUNT(g.ID_Grade) FILTER (WHERE g.GradeValue >= 3)::NUMERIC / NULLIF(COUNT(g.ID_Grade), 0) * 100,
            2
        )::NUMERIC AS SuccessRate
    FROM StudyGroups sg
    JOIN Students s ON s.Group_ID = sg.ID_Group
    JOIN Grades g ON g.Student_ID = s.ID_Student
    GROUP BY sg.GroupName
)
SELECT
    'Тест: сравнение групп по успеваемости',
    'bar',
    jsonb_build_object(
        'groupId', NULL,
        'disciplineId', NULL,
        'periodId', NULL,
        'chartType', 'attendanceByGroup',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', true,
        'sortOrder', 'descending'
    ),
    jsonb_build_object(
        'title', 'Успеваемость по группам',
        'subtitle', 'Процент оценок выше неудовлетворительных',
        'chartType', 'attendanceByGroup',
        'visualType', 'bar',
        'colorScheme', 'blue',
        'showLabels', true,
        'sortOrder', 'descending',
        'cards', jsonb_build_array(
            jsonb_build_object('title', 'Групп в сравнении', 'value', (SELECT COUNT(*)::TEXT FROM success_values)),
            jsonb_build_object('title', 'Лучшая успеваемость', 'value', (SELECT COALESCE(MAX(SuccessRate)::TEXT || '%', '0%') FROM success_values)),
            jsonb_build_object('title', 'Средняя успеваемость', 'value', (SELECT COALESCE(ROUND(AVG(SuccessRate), 2)::TEXT || '%', '0%') FROM success_values))
        ),
        'chartItems', (
            SELECT jsonb_agg(
                jsonb_build_object('label', GroupName, 'value', SuccessRate)
                ORDER BY SuccessRate DESC
            )
            FROM success_values
        )
    ),
    (SELECT ID_Account FROM Accounts WHERE Email = 'teacher@infographic.ru'),
    (SELECT ID_Template FROM InfographicTemplates WHERE ChartType = 'bar' ORDER BY ID_Template LIMIT 1);

-- ============================================================
-- 9. Импортированные и экспортированные файлы
-- ============================================================

INSERT INTO ImportFiles (
    OriginalFileName,
    FileType,
    ImportStatus,
    RowsTotal,
    RowsSuccess,
    RowsFailed,
    ErrorMessage,
    Account_ID
)
SELECT
    data.OriginalFileName,
    data.FileType,
    data.ImportStatus,
    data.RowsTotal,
    data.RowsSuccess,
    data.RowsFailed,
    data.ErrorMessage,
    data.Account_ID
FROM (
    VALUES
        ('grades_2025_semester_5.csv', 'CSV', 'Успешно', 820, 820, 0, NULL, (SELECT ID_Account FROM Accounts WHERE Email = 'teacher@infographic.ru')),
        ('attendance_2025_semester_5.xlsx', 'XLSX', 'Успешно', 780, 774, 6, '6 строк пропущено из-за пустого номера зачётной книжки', (SELECT ID_Account FROM Accounts WHERE Email = 'analyst@infographic.ru')),
        ('students_groups_update.csv', 'CSV', 'Успешно', 80, 80, 0, NULL, (SELECT ID_Account FROM Accounts WHERE Email = 'admin@infographic.ru')),
        ('bad_grades_file.xlsx', 'XLSX', 'Ошибка', 120, 83, 37, 'Некорректные значения оценок в 37 строках', (SELECT ID_Account FROM Accounts WHERE Email = 'user@infographic.ru'))
) AS data(OriginalFileName, FileType, ImportStatus, RowsTotal, RowsSuccess, RowsFailed, ErrorMessage, Account_ID)
WHERE data.Account_ID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM ImportFiles i
      WHERE i.OriginalFileName = data.OriginalFileName
  );

INSERT INTO ExportedFiles (FileName, FileFormat, Infographic_ID)
SELECT
    LOWER(REPLACE(REPLACE(i.Title, 'Тест: ', ''), ' ', '_')) || '.png' AS FileName,
    'PNG' AS FileFormat,
    i.ID_Infographic
FROM Infographics i
WHERE i.Title LIKE 'Тест:%'
  AND NOT EXISTS (
      SELECT 1
      FROM ExportedFiles e
      WHERE e.Infographic_ID = i.ID_Infographic
        AND e.FileFormat = 'PNG'
  );

-- ============================================================
-- 10. Итоговая проверка
-- ============================================================

SELECT set_config('app.current_account_id', '', false);

COMMIT;

-- После выполнения можно проверить количество данных:
-- SELECT COUNT(*) AS groups_count FROM StudyGroups;
-- SELECT COUNT(*) AS students_count FROM Students;
-- SELECT COUNT(*) AS disciplines_count FROM Disciplines;
-- SELECT COUNT(*) AS periods_count FROM StudyPeriods;
-- SELECT COUNT(*) AS grades_count FROM Grades;
-- SELECT COUNT(*) AS attendance_count FROM Attendance;
-- SELECT COUNT(*) AS infographics_count FROM Infographics;
-- SELECT * FROM GroupStatisticsView ORDER BY "Группа";
-- SELECT * FROM InfographicsView ORDER BY "Дата создания" DESC;

-- ПРОВЕРОЧНЫЕ ЗАПРОСЫ
-- Можно выполнять отдельно после создания базы
-- ============================================================

-- Проверка пользователей
-- SELECT * FROM UsersAccountsView;

-- Проверка студентов
-- SELECT * FROM StudentsView;

-- Проверка оценок
-- SELECT * FROM GradesView;

-- Проверка посещаемости
-- SELECT * FROM AttendanceView;

-- Проверка статистики по студентам
-- SELECT * FROM StudentStatisticsView;

-- Проверка статистики по группам
-- SELECT * FROM GroupStatisticsView;

-- Проверка сохраненных инфографик
-- SELECT * FROM InfographicsView;

-- Проверка аудита
-- SELECT * FROM AuditLogView;

-- Проверка текущего времени БД
-- SELECT app_now() AS current_moscow_time;

-- Проверка пользователя, совершившего действие в аудите
-- SELECT "Код записи", "Действие", "Таблица", "Пользователь", "Email пользователя", "Роль пользователя"
-- FROM AuditLogView
-- LIMIT 50;

-- Проверка входа администратора
-- SELECT * FROM CheckUserPassword('admin@infographic.ru', 'Admin123!');

-- Проверка входа пользователя
-- SELECT * FROM CheckUserPassword('user@infographic.ru', 'User123!');

-- Неверный пароль должен вернуть пустой результат
-- SELECT * FROM CheckUserPassword('user@infographic.ru', 'wrong_password');

-- Средний балл группы ИС-31 за 5 семестр
-- SELECT get_group_avg_grade_period(1, 1);

-- Процент успеваемости группы ИС-31 за 5 семестр
-- SELECT get_group_success_rate_period(1, 1);

-- Процент посещаемости группы ИС-31 за 5 семестр
-- SELECT get_group_attendance_rate_period(1, 1);

-- Распределение оценок для диаграммы
-- SELECT * FROM get_grade_distribution(1, 1, 1);

-- Пример регистрации нового пользователя
-- CALL RegisterUser(
--     'newuser@infographic.ru',
--     'NewUser123!',
--     'Сидорова',
--     'Елена',
--     'Петровна'
-- );

-- Пример блокировки пользователя
-- CALL SetAccountBlockStatus(2, TRUE);

-- Пример разблокировки пользователя
-- CALL SetAccountBlockStatus(2, FALSE);
