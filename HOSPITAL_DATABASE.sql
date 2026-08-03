SET SERVEROUTPUT ON;

--==========================================================================
-- CLEANUP BLOCK (Prevents ORA-00955 Errors)
--==========================================================================
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN (
        'PRESCRIPTION_REFILLS', 'APPOINTMENT_HISTORY', 'BILLING', 'PRESCRIPTIONS', 
        'APPOINTMENTS', 'DOCTORS', 'PATIENTS', 'SPECIALIZATIONS'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
    
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name IN (
        'PATIENT_SEQ', 'DOCTOR_SEQ', 'APPOINTMENT_SEQ', 
        'PRESCRIPTION_SEQ', 'BILL_SEQ', 'SPECIALIZATION_SEQ', 'HISTORY_SEQ', 'REFILL_SEQ'
    )) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

--==========================================================================
-- PART 1: DDL (TABLES & SEQUENCES)
--==========================================================================

-- patient table & sequence
CREATE TABLE patients(
patient_id NUMBER Primary Key, 
first_name VARCHAR2(50) NOT NULL,  
last_name VARCHAR2(50) NOT NULL,  
date_of_birth DATE NOT NULL, 
gender VARCHAR2(10) CHECK (gender IN('Male', 'Female', 'Other')), 
phone VARCHAR2(20) NOT NULL, 
email VARCHAR2(100) UNIQUE, 
address VARCHAR2(200), 
blood_group VARCHAR2(5) CHECK (blood_group IN('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-')),
registration_date DATE NOT NULL, 
status VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN('ACTIVE','INACTIVE'))
);

CREATE SEQUENCE patient_seq START WITH 1000 INCREMENT BY 1;

-- doctor table & sequence
CREATE TABLE doctors(
doctor_id NUMBER Primary Key, 
first_name VARCHAR2(50) NOT NULL,
last_name VARCHAR2(50) NOT NULL, 
specialization VARCHAR2(50) NOT NULL,
phone VARCHAR2(20) NOT NULL,
email VARCHAR2(100) NOT NULL UNIQUE, 
license_number VARCHAR2(50) NOT NULL UNIQUE, 
consultation_fee NUMBER(8,2) NOT NULL CHECK (consultation_fee > 0), 
years_experience NUMBER(2) CHECK (years_experience >= 0), 
status VARCHAR2(20) DEFAULT 'AVAILABLE' CHECK (status IN('AVAILABLE', 'ON_LEAVE', 'UNAVAILABLE'))  
);

CREATE SEQUENCE doctor_seq START WITH 2000 INCREMENT BY 1;

-- appointments table & sequence
CREATE TABLE appointments(
appointment_id NUMBER Primary Key,
patient_id NUMBER REFERENCES PATIENTS(patient_id), 
doctor_id NUMBER REFERENCES DOCTORS(doctor_id), 
appointment_date DATE NOT NULL, 
appointment_time VARCHAR2(10) NOT NULL, 
reason VARCHAR2(200) NOT NULL, 
status VARCHAR2(20) DEFAULT 'SCHEDULED' CHECK( status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED', 'NO_SHOW')), 
booking_date DATE NOT NULL,
notes VARCHAR2(500)   
);

CREATE SEQUENCE appointment_seq START WITH 3000 INCREMENT BY 1;

-- prescriptions table & sequence
CREATE TABLE prescriptions(
prescription_id NUMBER Primary Key, 
appointment_id NUMBER REFERENCES APPOINTMENTS(appointment_id), 
patient_id NUMBER REFERENCES PATIENTS(patient_id),
doctor_id NUMBER REFERENCES DOCTORS(doctor_id),
medication_name VARCHAR2(100) NOT NULL, 
dosage VARCHAR2(50) NOT NULL, 
duration_days NUMBER(3) NOT NULL CHECK (duration_days > 0), 
instructions VARCHAR2(200), 
prescription_date DATE NOT NULL
);

CREATE SEQUENCE prescription_seq START WITH 4000 INCREMENT BY 1;

-- billing table & sequence
CREATE TABLE billing(
bill_id NUMBER Primary Key, 
appointment_id NUMBER REFERENCES APPOINTMENTS(appointment_id),
patient_id NUMBER REFERENCES PATIENTS(patient_id),
consultation_fee NUMBER(8,2) NOT NULL,
medication_cost NUMBER(8,2) DEFAULT 0, 
lab_test_cost NUMBER(8,2) DEFAULT 0,
total_amount NUMBER(10,2) NOT NULL, 
payment_status VARCHAR2(20) DEFAULT 'PENDING' CHECK(payment_status IN('PENDING', 'PAID', 'PARTIALLY_PAID')), 
bill_date DATE NOT NULL, 
payment_date DATE
);

CREATE SEQUENCE bill_seq START WITH 5000 INCREMENT BY 1;

-- specializations table & sequence
CREATE TABLE specializations(
specialization_id NUMBER Primary Key,
specialization_name VARCHAR2(50) NOT NULL UNIQUE, 
description VARCHAR2(200) 
);

CREATE SEQUENCE specialization_seq START WITH 100 INCREMENT BY 1;

-- appointment_history table & sequence
CREATE TABLE appointment_history(
history_id NUMBER Primary Key,
appointment_id NUMBER NOT NULL, 
patient_id NUMBER NOT NULL, 
doctor_id NUMBER NOT NULL, 
action_type VARCHAR2(20) CHECK(action_type IN('SCHEDULED', 'COMPLETED', 'CANCELLED', 'RESCHEDULED')), 
action_date DATE NOT NULL, 
performed_by VARCHAR2(50) DEFAULT USER, 
remarks VARCHAR2(200) 
);

CREATE SEQUENCE history_seq START WITH 1 INCREMENT BY 1;

-- prescription refills table & sequence
CREATE TABLE prescription_refills (
    refill_id NUMBER PRIMARY KEY,
    prescription_id NUMBER REFERENCES prescriptions(prescription_id),
    request_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'PENDING'
);

CREATE SEQUENCE refill_seq START WITH 1 INCREMENT BY 1;

--==========================================================================
-- PART 2: DATA INSERTION (Loaded before triggers to avoid ORA-20030)
--==========================================================================

-- Specializations
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'General Medicine', 'Primary healthcare and general checkups');
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'Cardiology', 'Heart and vascular system disorders');
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'Pediatrics', 'Medical care for infants, children, and adolescents');
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'Orthopedics', 'Musculoskeletal system and bone health');
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'Dermatology', 'Skin, hair, and nail conditions');
INSERT INTO specializations VALUES (specialization_seq.NEXTVAL, 'Gynecology', 'Female reproductive health');

-- Doctors
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Jean', 'Mugisha', 'General Medicine', '0788100100', 'mugisha@hosp.rw', 'LIC001', 30000, 10, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Alice', 'Umutoni', 'General Medicine', '0788100101', 'umutoni@hosp.rw', 'LIC002', 35000, 5, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'David', 'Kamanzi', 'Cardiology', '0788100102', 'kamanzi@hosp.rw', 'LIC003', 90000, 15, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Grace', 'Irakoze', 'Cardiology', '0788100103', 'irakoze@hosp.rw', 'LIC004', 100000, 20, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Paul', 'Rwanda', 'Pediatrics', '0788100104', 'rwanda@hosp.rw', 'LIC005', 40000, 8, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Marie', 'Saro', 'Pediatrics', '0788100105', 'saro@hosp.rw', 'LIC006', 45000, 12, 'ON_LEAVE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Eric', 'Nshuti', 'Orthopedics', '0788100106', 'nshuti@hosp.rw', 'LIC007', 70000, 7, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Bella', 'Uwase', 'Orthopedics', '0788100107', 'uwase@hosp.rw', 'LIC008', 75000, 25, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Kevin', 'Gakwaya', 'Dermatology', '0788100108', 'gakwaya@hosp.rw', 'LIC009', 60000, 4, 'AVAILABLE');
INSERT INTO doctors VALUES (doctor_seq.NEXTVAL, 'Fiona', 'Isimbi', 'Gynecology', '0788100109', 'isimbi@hosp.rw', 'LIC010', 55000, 2, 'AVAILABLE');

-- Patients
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'John', 'Doe', TO_DATE('1955-05-15','YYYY-MM-DD'), 'Male', '0780000001', 'john@mail.com', 'Kigali', 'O+', TO_DATE('2023-01-10','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Jane', 'Smith', TO_DATE('2018-08-20','YYYY-MM-DD'), 'Female', '0780000002', 'jane@mail.com', 'Musanze', 'A-', TO_DATE('2024-02-15','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Mark', 'Turi', TO_DATE('1988-11-30','YYYY-MM-DD'), 'Male', '0780000003', 'mark@mail.com', 'Rubavu', 'B+', TO_DATE('2023-06-20','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Lucy', 'Keza', TO_DATE('2022-03-12','YYYY-MM-DD'), 'Female', '0780000004', 'lucy@mail.com', 'Kigali', 'AB+', TO_DATE('2025-01-05','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Bob', 'Musa', TO_DATE('1970-01-01','YYYY-MM-DD'), 'Male', '0780000005', 'bob@mail.com', 'Huye', 'O-', TO_DATE('2023-12-12','YYYY-MM-DD'), 'INACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Sara', 'Uwera', TO_DATE('1995-04-25','YYYY-MM-DD'), 'Female', '0780000006', 'sara@mail.com', 'Kigali', 'A+', TO_DATE('2024-05-10','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Tom', 'Kazi', TO_DATE('1960-07-07','YYYY-MM-DD'), 'Male', '0780000007', 'tom@mail.com', 'Nyamata', 'B-', TO_DATE('2024-08-15','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Ina', 'Mazi', TO_DATE('2010-02-14','YYYY-MM-DD'), 'Female', '0780000008', 'ina@mail.com', 'Kigali', 'AB-', TO_DATE('2024-10-10','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Sam', 'Ruru', TO_DATE('1990-12-25','YYYY-MM-DD'), 'Male', '0780000009', 'sam@mail.com', 'Gisenyi', 'O+', TO_DATE('2023-03-03','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Lea', 'Ira', TO_DATE('1985-06-18','YYYY-MM-DD'), 'Female', '0780000010', 'lea@mail.com', 'Kigali', 'A-', TO_DATE('2024-11-20','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Guy', 'Naza', TO_DATE('2000-09-09','YYYY-MM-DD'), 'Male', '0780000011', 'guy@mail.com', 'Kigali', 'B+', TO_DATE('2025-02-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Amy', 'Umu', TO_DATE('1940-03-30','YYYY-MM-DD'), 'Female', '0780000012', 'amy@mail.com', 'Byumba', 'O-', TO_DATE('2023-09-15','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Dan', 'Manzi', TO_DATE('2015-05-05','YYYY-MM-DD'), 'Male', '0780000013', 'dan@mail.com', 'Kigali', 'AB+', TO_DATE('2024-12-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Eve', 'Gara', TO_DATE('1975-10-10','YYYY-MM-DD'), 'Female', '0780000014', 'eve@mail.com', 'Kigali', 'A+', TO_DATE('2023-07-20','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO patients VALUES (patient_seq.NEXTVAL, 'Zoe', 'Bera', TO_DATE('1992-01-20','YYYY-MM-DD'), 'Female', '0780000015', 'zoe@mail.com', 'Kigali', 'B-', TO_DATE('2024-04-04','YYYY-MM-DD'), 'ACTIVE');

-- Appointments
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1000, 2000, DATE '2026-01-05', '08:00', 'General checkup',        'COMPLETED', DATE '2026-01-03', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1001, 2001, DATE '2026-01-10', '09:30', 'Fever and headache',      'COMPLETED', DATE '2026-01-08', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1002, 2002, DATE '2026-01-15', '10:00', 'Chest pain evaluation',   'COMPLETED', DATE '2026-01-13', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1003, 2003, DATE '2026-01-20', '11:00', 'Child vaccination',       'COMPLETED', DATE '2026-01-18', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1004, 2004, DATE '2026-02-01', '14:00', 'Skin rash check',        'COMPLETED', DATE '2026-01-30', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1005, 2005, DATE '2026-02-05', '15:00', 'Back pain consultation', 'COMPLETED', DATE '2026-02-03', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1006, 2006, DATE '2026-02-10', '16:00', 'Heart monitoring',       'COMPLETED', DATE '2026-02-08', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1007, 2007, DATE '2026-02-15', '08:30', 'Orthopedic review',      'COMPLETED', DATE '2026-02-13', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1008, 2008, DATE '2026-02-20', '09:00', 'Eye infection',          'COMPLETED', DATE '2026-02-18', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1009, 2009, DATE '2026-02-25', '10:30', 'Pregnancy checkup',      'COMPLETED', DATE '2026-02-23', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1010, 2000, DATE '2026-03-01', '11:30', 'Routine checkup',        'COMPLETED', DATE '2026-02-27', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1011, 2001, DATE '2026-03-05', '14:30', 'Flu treatment',          'COMPLETED', DATE '2026-03-03', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1012, 2002, DATE '2026-03-10', '15:30', 'Heart pain follow-up',   'COMPLETED', DATE '2026-03-08', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1013, 2003, DATE '2026-03-15', '16:00', 'Child fever',            'COMPLETED', DATE '2026-03-13', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1014, 2004, DATE '2026-03-20', '08:30', 'Blood pressure check',   'COMPLETED', DATE '2026-03-18', NULL);

INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1000, 2005, DATE '2026-08-10', '09:00', 'Follow-up visit',        'SCHEDULED', SYSDATE, NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1001, 2006, DATE '2026-08-12', '10:00', 'Cardiology review',      'SCHEDULED', SYSDATE, NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1002, 2007, DATE '2026-08-15', '11:00', 'Bone scan review',       'SCHEDULED', SYSDATE, NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1003, 2008, DATE '2026-08-18', '14:00', 'Skin treatment follow-up','SCHEDULED', SYSDATE, NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1004, 2009, DATE '2026-08-20', '15:30', 'General consultation',   'SCHEDULED', SYSDATE, NULL);

INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1005, 2000, DATE '2026-02-12', '09:00', 'Patient cancelled',      'CANCELLED', DATE '2026-02-10', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1006, 2001, DATE '2026-02-18', '14:00', 'Doctor unavailable',     'CANCELLED', DATE '2026-02-16', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1007, 2002, DATE '2026-03-02', '11:00', 'Emergency cancellation', 'CANCELLED', DATE '2026-02-28', NULL);

INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1008, 2003, DATE '2026-01-25', '10:00', 'Patient did not attend', 'NO_SHOW', DATE '2026-01-23', NULL);
INSERT INTO appointments VALUES (appointment_seq.NEXTVAL, 1009, 2004, DATE '2026-02-08', '15:00', 'Missed appointment',     'NO_SHOW', DATE '2026-02-06', NULL);

-- Prescriptions
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3000, 1000, 2000, 'Paracetamol', '500mg twice daily', 5, 'Take after meals', DATE '2026-01-05');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3001, 1001, 2001, 'Ibuprofen', '400mg three times daily', 3, 'Take with food', DATE '2026-01-10');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3002, 1002, 2002, 'Aspirin', '75mg once daily', 10, 'Avoid on empty stomach', DATE '2026-01-15');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3003, 1003, 2003, 'Vitamin C Syrup', '5ml twice daily', 7, 'Shake well before use', DATE '2026-01-20');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3004, 1004, 2004, 'Hydrocortisone Cream', 'Apply twice daily', 14, 'Apply to affected area', DATE '2026-02-01');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3005, 1005, 2005, 'Diclofenac', '50mg twice daily', 5, 'Take after meals', DATE '2026-02-05');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3006, 1006, 2006, 'Atorvastatin', '10mg once daily', 30, 'Take at night', DATE '2026-02-10');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3007, 1007, 2007, 'Calcium Tablets', '500mg daily', 20, 'Take with milk', DATE '2026-02-15');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3008, 1008, 2008, 'Eye Drops', '2 drops twice daily', 7, 'Do not touch tip', DATE '2026-02-20');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3009, 1009, 2009, 'Folic Acid', '5mg once daily', 30, 'Take before meals', DATE '2026-02-25');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3010, 1010, 2000, 'Amoxicillin', '500mg three times daily', 7, 'Complete full course', DATE '2026-03-01');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3011, 1011, 2001, 'Cough Syrup', '10ml three times daily', 5, 'Shake before use', DATE '2026-03-05');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3012, 1012, 2002, 'Nitroglycerin', '0.4mg when needed', 10, 'Use under tongue', DATE '2026-03-10');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3013, 1013, 2003, 'Paracetamol Syrup', '5ml every 6 hours', 5, 'Do not exceed dose', DATE '2026-03-15');
INSERT INTO prescriptions VALUES (prescription_seq.NEXTVAL, 3014, 1014, 2004, 'Lisinopril', '10mg once daily', 30, 'Monitor blood pressure', DATE '2026-03-20');

-- Billing 
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3003, 1003, 40000, 5000, 5000, 50000, 'PAID', DATE '2026-01-20', DATE '2026-01-20');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3004, 1004, 60000, 8000, 7000, 75000, 'PAID', DATE '2026-02-01', DATE '2026-02-01');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3005, 1005, 70000, 6000, 10000, 86000, 'PAID', DATE '2026-02-05', DATE '2026-02-05');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3006, 1006, 100000, 20000, 15000, 135000, 'PAID', DATE '2026-02-10', DATE '2026-02-10');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3007, 1007, 75000, 5000, 5000, 85000, 'PAID', DATE '2026-02-15', DATE '2026-02-15');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3008, 1008, 60000, 4000, 3000, 67000, 'PAID', DATE '2026-02-20', DATE '2026-02-20');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3009, 1009, 55000, 3000, 2000, 60000, 'PAID', DATE '2026-02-25', DATE '2026-02-25');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3010, 1010, 30000, 5000, 5000, 40000, 'PAID', DATE '2026-03-01', DATE '2026-03-01');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3011, 1011, 35000, 6000, 4000, 45000, 'PAID', DATE '2026-03-05', DATE '2026-03-05');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3012, 1012, 90000, 10000, 10000, 110000, 'PENDING', DATE '2026-03-10', NULL);
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3013, 1013, 40000, 5000, 3000, 48000, 'PENDING', DATE '2026-03-15', NULL);
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3014, 1014, 60000, 7000, 8000, 75000, 'PENDING', DATE '2026-03-20', NULL);
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3015, 1000, 70000, 6000, 4000, 80000, 'PENDING', DATE '2026-05-01', NULL);
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3016, 1001, 100000, 15000, 5000, 120000, 'PENDING', DATE '2026-05-03', NULL);
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3017, 1002, 75000, 8000, 7000, 90000, 'PARTIALLY_PAID', DATE '2026-05-05', DATE '2026-05-06');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3018, 1003, 60000, 6000, 6000, 72000, 'PARTIALLY_PAID', DATE '2026-05-07', DATE '2026-05-08');
INSERT INTO billing VALUES (bill_seq.NEXTVAL, 3019, 1004, 55000, 5000, 5000, 65000, 'PARTIALLY_PAID', DATE '2026-05-10', DATE '2026-05-11');

COMMIT;

--==========================================================================
-- PART 3: CURSOR IMPLEMENTATIONS
--==========================================================================

-- Task 1: Doctor Schedule and Revenue Report Cursor
DECLARE
    CURSOR doc_cursor IS
        SELECT d.doctor_id,
               d.first_name || ' ' || d.last_name AS doctor_name,
               d.specialization,
               d.consultation_fee
        FROM doctors d;

    v_total_appts NUMBER;
    v_completed NUMBER;
    v_cancelled NUMBER;
    v_revenue NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== DOCTOR REPORT =====');

    FOR doc IN doc_cursor LOOP
        SELECT COUNT(*) INTO v_total_appts
        FROM appointments WHERE doctor_id = doc.doctor_id;

        SELECT COUNT(*) INTO v_completed
        FROM appointments WHERE doctor_id = doc.doctor_id AND status = 'COMPLETED';

        SELECT COUNT(*) INTO v_cancelled
        FROM appointments WHERE doctor_id = doc.doctor_id AND status IN ('CANCELLED','NO_SHOW');

        SELECT NVL(SUM(b.total_amount),0) INTO v_revenue
        FROM billing b
        JOIN appointments a ON a.appointment_id = b.appointment_id
        WHERE a.doctor_id = doc.doctor_id AND a.status = 'COMPLETED';

        DBMS_OUTPUT.PUT_LINE('Doctor: ' || doc.doctor_name);
        DBMS_OUTPUT.PUT_LINE('Specialization: ' || doc.specialization);
        DBMS_OUTPUT.PUT_LINE('Total Appointments: ' || v_total_appts);
        DBMS_OUTPUT.PUT_LINE('Completed: ' || v_completed);
        DBMS_OUTPUT.PUT_LINE('Cancelled/No-show: ' || v_cancelled);
        DBMS_OUTPUT.PUT_LINE('Revenue: ' || v_revenue);
        DBMS_OUTPUT.PUT_LINE('----------------------------------');
    END LOOP;
END;
/

-- Task 2: Patient Activity Summary
BEGIN
    FOR p IN (SELECT patient_id, first_name, last_name, blood_group FROM patients) LOOP
        DECLARE
            v_visits NUMBER;
            v_last DATE;
            v_spent NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_visits FROM appointments WHERE patient_id = p.patient_id AND status = 'COMPLETED';
            SELECT MAX(appointment_date) INTO v_last FROM appointments WHERE patient_id = p.patient_id;
            SELECT NVL(SUM(total_amount),0) INTO v_spent FROM billing WHERE patient_id = p.patient_id;

            DBMS_OUTPUT.PUT_LINE('Patient: '||p.first_name||' '||p.last_name);
            DBMS_OUTPUT.PUT_LINE('Visits: '||v_visits);
            DBMS_OUTPUT.PUT_LINE('Last Visit: '||v_last);
            DBMS_OUTPUT.PUT_LINE('Total Spent: '||v_spent);
            DBMS_OUTPUT.PUT_LINE('----------------------------------');
        END;
    END LOOP;
END;
/

--============================================================================
-- PART 4: PROCEDURES
--============================================================================

CREATE OR REPLACE PROCEDURE register_patient (
    p_first_name     IN VARCHAR2,
    p_last_name      IN VARCHAR2,
    p_date_of_birth  IN DATE,
    p_gender         IN VARCHAR2,
    p_phone          IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_blood_group    IN VARCHAR2,
    p_patient_id     OUT NUMBER
) AS
    v_email_count NUMBER;
BEGIN
    IF p_email NOT LIKE '%@%.%' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid email format.');
    END IF;

    IF LENGTH(p_phone) != 10 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Phone number must be exactly 10 digits.');
    END IF;

    IF p_date_of_birth > SYSDATE OR p_date_of_birth < ADD_MONTHS(SYSDATE, -150*12) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Date of birth is unrealistic.');
    END IF;

    SELECT COUNT(*) INTO v_email_count FROM patients WHERE email = p_email;
    IF v_email_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Email already exists.');
    END IF;

    SELECT patient_seq.NEXTVAL INTO p_patient_id FROM dual;

    INSERT INTO patients (
        patient_id, first_name, last_name, date_of_birth, gender, 
        phone, email, blood_group, registration_date, status
    ) VALUES (
        p_patient_id, p_first_name, p_last_name, p_date_of_birth, p_gender, 
        p_phone, p_email, p_blood_group, SYSDATE, 'ACTIVE'
    );

    DBMS_OUTPUT.PUT_LINE('Patient Registered! ID: ' || p_patient_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE schedule_appointment (
    p_patient_id       IN NUMBER,
    p_doctor_id        IN NUMBER,
    p_appointment_date IN DATE,
    p_appointment_time IN VARCHAR2,
    p_reason           IN VARCHAR2
) AS
    v_p_status    VARCHAR2(20);
    v_d_status    VARCHAR2(20);
    v_debt        NUMBER;
    v_conflict    NUMBER;
    v_appt_id     NUMBER;
BEGIN
    SELECT status INTO v_p_status FROM patients WHERE patient_id = p_patient_id;
    IF v_p_status != 'ACTIVE' THEN RAISE_APPLICATION_ERROR(-20010, 'Patient is not ACTIVE.'); END IF;

    SELECT status INTO v_d_status FROM doctors WHERE doctor_id = p_doctor_id;
    IF v_d_status != 'AVAILABLE' THEN RAISE_APPLICATION_ERROR(-20011, 'Doctor is not AVAILABLE.'); END IF;

    IF p_appointment_date < TRUNC(SYSDATE) THEN RAISE_APPLICATION_ERROR(-20012, 'Date cannot be in the past.'); END IF;
    IF p_appointment_time NOT BETWEEN '08:00' AND '17:00' THEN RAISE_APPLICATION_ERROR(-20013, 'Outside working hours.'); END IF;

    SELECT COUNT(*) INTO v_conflict FROM appointments 
    WHERE doctor_id = p_doctor_id AND appointment_date = p_appointment_date AND appointment_time = p_appointment_time;
    IF v_conflict > 0 THEN RAISE_APPLICATION_ERROR(-20014, 'Doctor has a conflict.'); END IF;

    SELECT NVL(SUM(total_amount), 0) INTO v_debt FROM billing 
    WHERE patient_id = p_patient_id AND payment_status = 'PENDING';
    IF v_debt > 100000 THEN RAISE_APPLICATION_ERROR(-20015, 'High pending bills: ' || v_debt); END IF;

    SELECT appointment_seq.NEXTVAL INTO v_appt_id FROM dual;

    INSERT INTO appointments (appointment_id, patient_id, doctor_id, appointment_date, appointment_time, reason, status, booking_date)
    VALUES (v_appt_id, p_patient_id, p_doctor_id, p_appointment_date, p_appointment_time, p_reason, 'SCHEDULED', SYSDATE);

    INSERT INTO appointment_history (history_id, appointment_id, patient_id, doctor_id, action_type, action_date, remarks)
    VALUES (history_seq.NEXTVAL, v_appt_id, p_patient_id, p_doctor_id, 'SCHEDULED', SYSDATE, 'New booking created');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Appointment Scheduled Successfully. ID: ' || v_appt_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Error: ID not found.');
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM); ROLLBACK;
END;
/

CREATE OR REPLACE PROCEDURE complete_appointment (
    p_appointment_id  IN NUMBER,
    p_medication_cost IN NUMBER DEFAULT 0,
    p_lab_test_cost   IN NUMBER DEFAULT 0,
    p_notes           IN VARCHAR2 DEFAULT NULL
) AS
    v_status    VARCHAR2(20);
    v_date      DATE;
    v_p_id      NUMBER;
    v_d_id      NUMBER;
    v_cons_fee  NUMBER;
    v_total     NUMBER;
    v_bill_id   NUMBER;
BEGIN
    SELECT status, appointment_date, patient_id, doctor_id 
    INTO v_status, v_date, v_p_id, v_d_id 
    FROM appointments WHERE appointment_id = p_appointment_id;

    IF v_status != 'SCHEDULED' THEN RAISE_APPLICATION_ERROR(-20020, 'Not a scheduled appointment.'); END IF;
    IF v_date > SYSDATE THEN RAISE_APPLICATION_ERROR(-20021, 'Cannot complete a future appointment.'); END IF;

    UPDATE appointments 
    SET status = 'COMPLETED', notes = p_notes 
    WHERE appointment_id = p_appointment_id;

    SELECT consultation_fee INTO v_cons_fee FROM doctors WHERE doctor_id = v_d_id;
    v_total := v_cons_fee + p_medication_cost + p_lab_test_cost;

    INSERT INTO billing (bill_id, appointment_id, patient_id, consultation_fee, medication_cost, lab_test_cost, total_amount, payment_status, bill_date)
    VALUES (bill_seq.NEXTVAL, p_appointment_id, v_p_id, v_cons_fee, p_medication_cost, p_lab_test_cost, v_total, 'PENDING', SYSDATE);

    INSERT INTO appointment_history (history_id, appointment_id, patient_id, doctor_id, action_type, action_date, remarks)
    VALUES (history_seq.NEXTVAL, p_appointment_id, v_p_id, v_d_id, 'COMPLETED', SYSDATE, p_notes);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Appointment Completed. Bill Generated for Total: ' || v_total);
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('Error: Appointment ID not found.');
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM); ROLLBACK;
END;
/

--========================================================================
-- PART 5: FUNCTIONS
--========================================================================

CREATE OR REPLACE FUNCTION get_patient_age(p_patient_id IN NUMBER)
RETURN NUMBER IS
    v_date_of_birth DATE;
    v_age NUMBER;
BEGIN
    SELECT date_of_birth INTO v_date_of_birth FROM patients WHERE patient_id = p_patient_id;
    v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, v_date_of_birth) / 12);
    RETURN v_age;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
END get_patient_age;
/

CREATE OR REPLACE FUNCTION is_doctor_available(
    p_doctor_id IN NUMBER,
    p_appointment_date IN DATE,
    p_appointment_time IN VARCHAR2
) RETURN VARCHAR2 IS
    v_doctor_status VARCHAR2(20);
    v_count NUMBER;
BEGIN
    SELECT status INTO v_doctor_status FROM doctors WHERE doctor_id = p_doctor_id;
    IF v_doctor_status != 'AVAILABLE' THEN RETURN 'NO'; END IF;
    
    SELECT COUNT(*) INTO v_count FROM appointments
    WHERE doctor_id = p_doctor_id
    AND TRUNC(appointment_date) = TRUNC(p_appointment_date)
    AND appointment_time  = p_appointment_time
    AND status = 'SCHEDULED';

    IF v_count > 0 THEN RETURN 'NO'; END IF;
    RETURN 'YES';
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 'NO';
END is_doctor_available;
/

CREATE OR REPLACE FUNCTION get_patient_balance(p_patient_id IN NUMBER)
RETURN NUMBER IS
    v_count   NUMBER;
    v_balance NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
    IF v_count = 0 THEN RETURN -1; END IF;
   
    SELECT NVL(SUM(total_amount), 0) INTO v_balance FROM billing
    WHERE patient_id = p_patient_id AND payment_status IN ('PENDING', 'PARTIALLY_PAID');

    RETURN v_balance;
EXCEPTION
    WHEN OTHERS THEN RETURN -1;
END get_patient_balance;
/

--====================================================================
-- PART 6: TRIGGERS (Created after seed data)
--====================================================================

CREATE OR REPLACE TRIGGER trg_validate_appointment
BEFORE INSERT OR UPDATE ON appointments
FOR EACH ROW
DECLARE
    v_hour   NUMBER;
    v_minute NUMBER;
BEGIN
    IF INSERTING THEN
        IF TRUNC(:NEW.appointment_date) < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20030, 'Appointment date cannot be in the past');
        END IF;
    END IF;

    IF LENGTH(:NEW.appointment_time) != 5 OR
       SUBSTR(:NEW.appointment_time, 3, 1) != ':' OR
       REGEXP_LIKE(SUBSTR(:NEW.appointment_time, 1, 2), '[^0-9]') OR
       REGEXP_LIKE(SUBSTR(:NEW.appointment_time, 4, 2), '[^0-9]') THEN
        RAISE_APPLICATION_ERROR(-20031, 'Invalid time format. Must be HH:MM (e.g. 08:00, 14:30)');
    END IF;

    v_hour   := TO_NUMBER(SUBSTR(:NEW.appointment_time, 1, 2));
    v_minute := TO_NUMBER(SUBSTR(:NEW.appointment_time, 4, 2));

    IF v_hour < 8 OR v_hour > 17 OR (v_hour = 17 AND v_minute > 0) THEN
        RAISE_APPLICATION_ERROR(-20032,'Appointment time must be between 08:00 and 17:00');
    END IF;

    IF INSERTING THEN
        :NEW.booking_date := SYSDATE;
    END IF;
END trg_validate_appointment;
/

CREATE OR REPLACE TRIGGER trg_calculate_bill_total
BEFORE INSERT OR UPDATE ON billing
FOR EACH ROW
BEGIN
    IF :NEW.consultation_fee < 0 THEN RAISE_APPLICATION_ERROR(-20040,'Consultation fee cannot be negative'); END IF;
    IF NVL(:NEW.medication_cost, 0) < 0 THEN RAISE_APPLICATION_ERROR(-20041,'Medication cost cannot be negative'); END IF;
    IF NVL(:NEW.lab_test_cost, 0) < 0 THEN RAISE_APPLICATION_ERROR(-20042,'Lab test cost cannot be negative'); END IF;

    :NEW.medication_cost := NVL(:NEW.medication_cost, 0);
    :NEW.lab_test_cost   := NVL(:NEW.lab_test_cost, 0);
    :NEW.total_amount := :NEW.consultation_fee + :NEW.medication_cost + :NEW.lab_test_cost;

    IF :NEW.bill_date IS NULL THEN
        :NEW.bill_date := SYSDATE;
    END IF;
END trg_calculate_bill_total;
/

CREATE OR REPLACE TRIGGER trg_log_appointment_changes
AFTER UPDATE OF status ON appointments
FOR EACH ROW
DECLARE
    v_action_type VARCHAR2(20);
BEGIN
    IF :OLD.status != :NEW.status THEN
        CASE :NEW.status
            WHEN 'COMPLETED'  THEN v_action_type := 'COMPLETED';
            WHEN 'CANCELLED'  THEN v_action_type := 'CANCELLED';
            WHEN 'SCHEDULED'  THEN v_action_type := 'RESCHEDULED';
            WHEN 'NO_SHOW'    THEN v_action_type := 'CANCELLED';
            ELSE v_action_type := :NEW.status;
        END CASE;

        INSERT INTO appointment_history (
            history_id, appointment_id, patient_id, doctor_id, action_type, action_date, performed_by, remarks
        ) VALUES (
            history_seq.NEXTVAL, :NEW.appointment_id, :NEW.patient_id, :NEW.doctor_id, v_action_type, SYSDATE, USER,
            'Status changed from ' || :OLD.status || ' to ' || :NEW.status
        );
    END IF;
END trg_log_appointment_changes;
/

--====================================================================
-- PART 7: PACKAGE SPECIFICATION & BODY
--====================================================================

CREATE OR REPLACE PACKAGE HOSPITAL_MGT_PKG IS
    PROCEDURE register_patient(
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_gender        IN VARCHAR2,
        p_phone         IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_blood_group   IN VARCHAR2,
        p_patient_id    OUT NUMBER
    );
    PROCEDURE schedule_appointment(
        p_patient_id       IN NUMBER,
        p_doctor_id        IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_reason           IN VARCHAR2
    );
    PROCEDURE complete_appointment(
        p_appointment_id  IN NUMBER,
        p_medication_cost IN NUMBER DEFAULT 0,
        p_lab_test_cost   IN NUMBER DEFAULT 0,
        p_notes           IN VARCHAR2 DEFAULT NULL
    );
    PROCEDURE cancel_appointment(
        p_appointment_id IN NUMBER,
        p_reason         IN VARCHAR2
    );
    PROCEDURE process_payment(
        p_bill_id     IN NUMBER,
        p_amount_paid IN NUMBER
    );
    FUNCTION get_patient_age(p_patient_id IN NUMBER) RETURN NUMBER;
    FUNCTION is_doctor_available(
        p_doctor_id        IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2
    ) RETURN VARCHAR2;
    FUNCTION get_patient_balance(p_patient_id IN NUMBER) RETURN NUMBER;
    FUNCTION get_doctor_daily_schedule(
        p_doctor_id IN NUMBER,
        p_date      IN DATE
    ) RETURN NUMBER;
END HOSPITAL_MGT_PKG;
/

CREATE OR REPLACE PACKAGE BODY HOSPITAL_MGT_PKG IS

    PROCEDURE register_patient(
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_gender        IN VARCHAR2,
        p_phone         IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_blood_group   IN VARCHAR2,
        p_patient_id    OUT NUMBER
    ) IS
        v_count NUMBER;
        v_age   NUMBER;
    BEGIN
        IF INSTR(p_email, '@') = 0 THEN RAISE_APPLICATION_ERROR(-20001, 'Invalid email format.'); END IF;
        IF LENGTH(TRIM(p_phone)) != 10 OR REGEXP_LIKE(p_phone, '[^0-9]') THEN RAISE_APPLICATION_ERROR(-20002, 'Invalid phone number.'); END IF;
        IF p_gender NOT IN ('Male', 'Female', 'Other') THEN RAISE_APPLICATION_ERROR(-20003, 'Invalid gender.'); END IF;
        IF p_blood_group NOT IN ('A+','A-','B+','B-','O+','O-','AB+','AB-') THEN RAISE_APPLICATION_ERROR(-20004, 'Invalid blood group.'); END IF;

        v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, p_date_of_birth) / 12);
        IF p_date_of_birth > SYSDATE THEN RAISE_APPLICATION_ERROR(-20005, 'DOB in future'); END IF;
        IF v_age > 150 THEN RAISE_APPLICATION_ERROR(-20006, 'Age exceeds 150'); END IF;

        SELECT COUNT(*) INTO v_count FROM patients WHERE email = p_email;
        IF v_count > 0 THEN RAISE_APPLICATION_ERROR(-20007, 'Email exists.'); END IF;

        SELECT patient_seq.NEXTVAL INTO p_patient_id FROM dual;

        INSERT INTO patients (
            patient_id, first_name, last_name, date_of_birth, gender, phone, email, blood_group, registration_date, status
        ) VALUES (
            p_patient_id, p_first_name, p_last_name, p_date_of_birth, p_gender, p_phone, p_email, p_blood_group, SYSDATE, 'ACTIVE'
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END register_patient;

    PROCEDURE schedule_appointment(
        p_patient_id       IN NUMBER,
        p_doctor_id        IN NUMBER,
        p_appointment_date IN DATE,
        p_appointment_time IN VARCHAR2,
        p_reason           IN VARCHAR2
    ) IS
        v_patient_status VARCHAR2(20);
        v_doctor_status  VARCHAR2(20);
        v_count          NUMBER;
        v_outstanding    NUMBER;
        v_appointment_id NUMBER;
        v_hour           NUMBER;
    BEGIN
        SELECT status INTO v_patient_status FROM patients WHERE patient_id = p_patient_id;
        IF v_patient_status != 'ACTIVE' THEN RAISE_APPLICATION_ERROR(-20011, 'Patient not ACTIVE'); END IF;

        SELECT status INTO v_doctor_status FROM doctors WHERE doctor_id = p_doctor_id;
        IF v_doctor_status != 'AVAILABLE' THEN RAISE_APPLICATION_ERROR(-20013, 'Doctor not AVAILABLE'); END IF;

        IF TRUNC(p_appointment_date) < TRUNC(SYSDATE) THEN RAISE_APPLICATION_ERROR(-20014, 'Past date'); END IF;

        v_hour := TO_NUMBER(SUBSTR(p_appointment_time, 1, 2));
        IF v_hour < 8 OR v_hour >= 17 THEN RAISE_APPLICATION_ERROR(-20015, 'Invalid hours'); END IF;

        SELECT COUNT(*) INTO v_count FROM appointments
        WHERE doctor_id = p_doctor_id AND TRUNC(appointment_date) = TRUNC(p_appointment_date)
        AND appointment_time = p_appointment_time AND status = 'SCHEDULED';
        IF v_count > 0 THEN RAISE_APPLICATION_ERROR(-20016, 'Doctor booked'); END IF;

        SELECT NVL(SUM(total_amount), 0) INTO v_outstanding FROM billing
        WHERE patient_id = p_patient_id AND payment_status IN ('PENDING', 'PARTIALLY_PAID');
        IF v_outstanding > 100000 THEN RAISE_APPLICATION_ERROR(-20018, 'Outstanding balance exceeds limit'); END IF;

        SELECT appointment_seq.NEXTVAL INTO v_appointment_id FROM dual;

        INSERT INTO appointments VALUES (
            v_appointment_id, p_patient_id, p_doctor_id, p_appointment_date, p_appointment_time, p_reason, 'SCHEDULED', SYSDATE, NULL
        );

        INSERT INTO appointment_history VALUES (
            history_seq.NEXTVAL, v_appointment_id, p_patient_id, p_doctor_id, 'SCHEDULED', SYSDATE, USER, 'Scheduled'
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END schedule_appointment;

    PROCEDURE complete_appointment(
        p_appointment_id  IN NUMBER,
        p_medication_cost IN NUMBER DEFAULT 0,
        p_lab_test_cost   IN NUMBER DEFAULT 0,
        p_notes           IN VARCHAR2 DEFAULT NULL
    ) IS
        v_patient_id       NUMBER;
        v_doctor_id        NUMBER;
        v_appt_status      VARCHAR2(20);
        v_appt_date        DATE;
        v_consultation_fee NUMBER;
        v_total_amount     NUMBER;
        v_bill_id          NUMBER;
    BEGIN
        SELECT a.patient_id, a.doctor_id, a.status, a.appointment_date, d.consultation_fee
        INTO v_patient_id, v_doctor_id, v_appt_status, v_appt_date, v_consultation_fee
        FROM appointments a JOIN doctors d ON a.doctor_id = d.doctor_id
        WHERE a.appointment_id = p_appointment_id;

        IF v_appt_status != 'SCHEDULED' THEN RAISE_APPLICATION_ERROR(-20021, 'Not SCHEDULED'); END IF;
        IF TRUNC(v_appt_date) > TRUNC(SYSDATE) THEN RAISE_APPLICATION_ERROR(-20022, 'Future appointment'); END IF;

        UPDATE appointments SET status = 'COMPLETED', notes = NVL(p_notes, notes) WHERE appointment_id = p_appointment_id;

        v_total_amount := v_consultation_fee + NVL(p_medication_cost, 0) + NVL(p_lab_test_cost, 0);
        SELECT bill_seq.NEXTVAL INTO v_bill_id FROM dual;

        INSERT INTO billing VALUES (v_bill_id, p_appointment_id, v_patient_id, v_consultation_fee, NVL(p_medication_cost,0), NVL(p_lab_test_cost,0), v_total_amount, 'PENDING', SYSDATE, NULL);
        INSERT INTO appointment_history VALUES (history_seq.NEXTVAL, p_appointment_id, v_patient_id, v_doctor_id, 'COMPLETED', SYSDATE, USER, 'Completed');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END complete_appointment;

    PROCEDURE cancel_appointment(p_appointment_id IN NUMBER, p_reason IN VARCHAR2) IS
        v_patient_id NUMBER; v_doctor_id NUMBER; v_appt_status VARCHAR2(20); v_appt_date DATE; v_bill_id NUMBER;
    BEGIN
        SELECT patient_id, doctor_id, status, appointment_date INTO v_patient_id, v_doctor_id, v_appt_status, v_appt_date FROM appointments WHERE appointment_id = p_appointment_id;
        IF v_appt_status != 'SCHEDULED' THEN RAISE_APPLICATION_ERROR(-20021, 'Not SCHEDULED'); END IF;

        UPDATE appointments SET status = 'CANCELLED', notes = p_reason WHERE appointment_id = p_appointment_id;

        IF v_appt_date <= SYSDATE + INTERVAL '1' DAY AND v_appt_date >= SYSDATE THEN
            SELECT bill_seq.NEXTVAL INTO v_bill_id FROM dual;
            INSERT INTO billing VALUES (v_bill_id, p_appointment_id, v_patient_id, 1000, 0, 0, 1000, 'PENDING', SYSDATE, NULL);
        END IF;

        INSERT INTO appointment_history VALUES (history_seq.NEXTVAL, p_appointment_id, v_patient_id, v_doctor_id, 'CANCELLED', SYSDATE, USER, 'Cancelled: ' || p_reason);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END cancel_appointment;

    PROCEDURE process_payment(p_bill_id IN NUMBER, p_amount_paid IN NUMBER) IS
        v_total_amount NUMBER; v_payment_status VARCHAR2(20); v_new_status VARCHAR2(20);
    BEGIN
        SELECT total_amount, payment_status INTO v_total_amount, v_payment_status FROM billing WHERE bill_id = p_bill_id;
        IF p_amount_paid <= 0 THEN RAISE_APPLICATION_ERROR(-20031, 'Amount must be > 0'); END IF;
        IF v_payment_status = 'PAID' THEN RAISE_APPLICATION_ERROR(-20032, 'Already paid'); END IF;

        v_new_status := CASE WHEN p_amount_paid >= v_total_amount THEN 'PAID' ELSE 'PARTIALLY_PAID' END;
        UPDATE billing SET payment_status = v_new_status, payment_date = CASE WHEN v_new_status = 'PAID' THEN SYSDATE ELSE NULL END WHERE bill_id = p_bill_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END process_payment;

    FUNCTION get_patient_age(p_patient_id IN NUMBER) RETURN NUMBER IS
        v_dob DATE;
    BEGIN
        SELECT date_of_birth INTO v_dob FROM patients WHERE patient_id = p_patient_id;
        RETURN FLOOR(MONTHS_BETWEEN(SYSDATE, v_dob) / 12);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
    END get_patient_age;

    FUNCTION is_doctor_available(p_doctor_id IN NUMBER, p_appointment_date IN DATE, p_appointment_time IN VARCHAR2) RETURN VARCHAR2 IS
        v_status VARCHAR2(20); v_count NUMBER;
    BEGIN
        SELECT status INTO v_status FROM doctors WHERE doctor_id = p_doctor_id;
        IF v_status != 'AVAILABLE' THEN RETURN 'NO'; END IF;
        SELECT COUNT(*) INTO v_count FROM appointments WHERE doctor_id = p_doctor_id AND TRUNC(appointment_date) = TRUNC(p_appointment_date) AND appointment_time = p_appointment_time AND status = 'SCHEDULED';
        IF v_count > 0 THEN RETURN 'NO'; END IF;
        RETURN 'YES';
    EXCEPTION WHEN OTHERS THEN RETURN 'NO';
    END is_doctor_available;

    FUNCTION get_patient_balance(p_patient_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER; v_bal NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
        IF v_count = 0 THEN RETURN -1; END IF;
        SELECT NVL(SUM(total_amount), 0) INTO v_bal FROM billing WHERE patient_id = p_patient_id AND payment_status IN ('PENDING', 'PARTIALLY_PAID');
        RETURN v_bal;
    EXCEPTION WHEN OTHERS THEN RETURN -1;
    END get_patient_balance;

    FUNCTION get_doctor_daily_schedule(p_doctor_id IN NUMBER, p_date IN DATE) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM appointments WHERE doctor_id = p_doctor_id AND TRUNC(appointment_date) = TRUNC(p_date) AND status = 'SCHEDULED';
        RETURN v_count;
    EXCEPTION WHEN OTHERS THEN RETURN 0;
    END get_doctor_daily_schedule;

END HOSPITAL_MGT_PKG;
/

--===========================================================================
-- PART 8: BONUS FEATURES
--===========================================================================

CREATE OR REPLACE PROCEDURE send_sms_reminders IS
BEGIN
    FOR rec IN (
        SELECT p.first_name || ' ' || p.last_name AS patient_name, p.phone, d.first_name || ' ' || d.last_name AS doctor_name, a.appointment_time
        FROM appointments a JOIN patients p ON a.patient_id = p.patient_id JOIN doctors d ON a.doctor_id = d.doctor_id
        WHERE TRUNC(a.appointment_date) = TRUNC(SYSDATE + 1) AND a.status = 'SCHEDULED'
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('📩 SMS TO: ' || rec.phone);
        DBMS_OUTPUT.PUT_LINE('Hello ' || rec.patient_name || ', reminder: You have an appointment with Dr. ' || rec.doctor_name || ' tomorrow at ' || rec.appointment_time);
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE doctor_performance_report IS
BEGIN
    FOR rec IN (
        SELECT d.first_name || ' ' || d.last_name AS doctor_name,
               COUNT(CASE WHEN a.status = 'COMPLETED' THEN 1 END) AS completed_appointments,
               NVL(SUM(CASE WHEN a.status = 'COMPLETED' THEN b.total_amount END), 0) AS total_revenue,
               RANK() OVER (ORDER BY COUNT(CASE WHEN a.status = 'COMPLETED' THEN 1 END) DESC, NVL(SUM(b.total_amount),0) DESC) AS ranking
        FROM doctors d
        LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
        LEFT JOIN billing b ON a.appointment_id = b.appointment_id
        GROUP BY d.doctor_id, d.first_name, d.last_name
    ) LOOP
        IF rec.ranking <= 3 THEN
            DBMS_OUTPUT.PUT_LINE('🏆 Rank #' || rec.ranking || ' Doctor: ' || rec.doctor_name || ' | Completed: ' || rec.completed_appointments || ' | Revenue: ' || rec.total_revenue || ' RWF');
        END IF;
    END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE request_refill (p_prescription_id IN NUMBER) IS
    v_date DATE; v_duration NUMBER;
BEGIN
    SELECT prescription_date, duration_days INTO v_date, v_duration FROM prescriptions WHERE prescription_id = p_prescription_id;
    IF SYSDATE > (v_date + v_duration) THEN RAISE_APPLICATION_ERROR(-20001, 'Refill period expired'); END IF;

    INSERT INTO prescription_refills VALUES (refill_seq.NEXTVAL, p_prescription_id, SYSDATE, 'APPROVED');
    DBMS_OUTPUT.PUT_LINE('✅ Refill approved successfully');
EXCEPTION
    WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('❌ Prescription not found');
END;
/