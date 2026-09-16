CREATE WAREHOUSE IF NOT EXISTS REDBUS_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS REDBUS_ANALYTICS;

USE DATABASE REDBUS_ANALYTICS;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS DW;
CREATE SCHEMA IF NOT EXISTS OPS;

USE WAREHOUSE REDBUS_WH;

CREATE OR REPLACE TABLE REDBUS_ANALYTICS.RAW.RAW_CUSTOMERS (
    CUSTOMER_ID VARCHAR(50),
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    EMAIL VARCHAR(200),
    PHONE VARCHAR(50),
    SEGMENT VARCHAR(50),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    COUNTRY VARCHAR(100),
    UPDATED_AT TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE REDBUS_ANALYTICS.RAW.RAW_ROUTES (
    ROUTE_ID VARCHAR(50),
    SOURCE_CITY VARCHAR(100),
    DEST_CITY VARCHAR(100),
    DISTANCE_KM NUMBER(10,2),
    SOURCE_STATE VARCHAR(10),
    DEST_STATE VARCHAR(10),
    REGION VARCHAR(100),
    EFFECTIVE_FROM TIMESTAMP_NTZ,
    STATUS VARCHAR(30)
);

CREATE OR REPLACE TABLE REDBUS_ANALYTICS.RAW.RAW_BUSES (
    BUS_ID VARCHAR(50),
    OPERATOR_NAME VARCHAR(200),
    BUS_TYPE VARCHAR(50),
    SEAT_CAPACITY NUMBER(5),
    BUS_MODEL VARCHAR(50),
    REGISTRATION_NO VARCHAR(50),
    IN_SERVICE_DATE DATE,
    STATUS VARCHAR(20),
    UPDATED_AT TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE REDBUS_ANALYTICS.RAW.RAW_BOOKINGS (
    BOOKING_ID VARCHAR(50),
    BOOKING_LINE_ID VARCHAR(50),
    BOOKING_DATE DATE,
    CUSTOMER_ID VARCHAR(50),
    ROUTE_ID VARCHAR(50),
    BUS_ID VARCHAR(50),
    JOURNEY_DATE DATE,
    DEPARTURE_TIME TIME,
    ARRIVAL_TIME TIME,
    SEAT_TYPE VARCHAR(50),
    SEAT_NO VARCHAR(10),
    PASSENGER_COUNT NUMBER(5),
    FARE_AMOUNT NUMBER(10,2),
    DISCOUNT_PCT NUMBER(5,2),
    PAYMENT_MODE VARCHAR(50),
    BOOKING_STATUS VARCHAR(20)
);

-- Verify row counts after CSV upload
SELECT 'RAW_CUSTOMERS' AS TBL, COUNT(*) AS ROW_COUNT FROM REDBUS_ANALYTICS.RAW.RAW_CUSTOMERS
UNION ALL SELECT 'RAW_ROUTES', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_ROUTES
UNION ALL SELECT 'RAW_BUSES', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_BUSES
UNION ALL SELECT 'RAW_BOOKINGS', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_BOOKINGS;


CREATE OR REPLACE TABLE REDBUS_ANALYTICS.DW.DOCS (
    DOC_ID INTEGER IDENTITY(1,1) PRIMARY KEY,
    FILE_NAME VARCHAR(200),
    FILE_CONTENT VARCHAR(16777216),
    UPLOAD_TS TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insert policy documents for RAG
INSERT INTO REDBUS_ANALYTICS.DW.DOCS (FILE_NAME, FILE_CONTENT) VALUES

('cancellation_policy.txt', 'REDBUS CANCELLATION POLICY

1. Standard Cancellation:
   - Free cancellation up to 24 hours before journey start time
   - 25% cancellation fee for cancellations between 12-24 hours before journey
   - 50% cancellation fee for cancellations between 6-12 hours before journey
   - No refund for cancellations within 6 hours of journey start time

2. Special Cancellation:
   - Premium customers (VIP) get free cancellation up to 12 hours before journey
   - Senior citizens (above 60 years) get 50% extra refund on all cancellations
   - Group bookings (5+ passengers) require 48 hours notice for free cancellation

3. Refund Process:
   - Refunds processed within 3-5 business days
   - Refund credited to original payment method
   - For cash payments, refund processed via bank transfer within 7 days

4. Exceptions:
   - Government-issued travel advisories: 100% refund
   - Natural disasters: 100% refund
   - Operator cancellation: 200% refund of ticket amount'),

('refund_rules.txt', 'REDBUS REFUND RULES

1. Refund Timeline:
   - Refunds processed within 24 hours of cancellation approval
   - Credit card refunds: 3-5 business days to reflect
   - UPI refunds: 1-2 business days to reflect
   - Bank transfer refunds: 5-7 business days to reflect

2. Refund Amount Calculation:
   - Total refund = Ticket amount - Cancellation fee
   - For partial journeys (used part of trip): Refund = 50% of unused portion

3. Refund Methods:
   - Original payment method gets priority refund
   - If original method unavailable, RedBus wallet credit offered
   - Wallet credit valid for 365 days from date of issue

4. Contact Information:
   - For refund queries: refunds@redbus.com
   - Support number: 1-800-REDBUS (1-800-733-287)'),

('operator_sop.txt', 'REDBUS OPERATOR STANDARD OPERATING PROCEDURES

1. Booking Confirmation:
   - Operators must confirm booking within 15 minutes of receipt
   - Seat allocation done automatically by system
   - Manual seat changes allowed only with customer consent

2. Bus Standards:
   - All buses must have GPS tracking
   - AC buses: Temperature maintained at 18-22°C
   - Non-AC buses: Windows must be in good condition

3. On-Time Performance:
   - Departure within 5 minutes of scheduled time: ON TIME
   - Departure between 5-30 minutes delayed: MINOR DELAY
   - Departure beyond 30 minutes delayed: MAJOR DELAY

4. Customer Service:
   - All queries responded within 2 hours
   - Complaints escalated within 24 hours
   - Resolution timeline: 48 hours for standard issues'),

('safety_policy.txt', 'REDBUS PASSENGER SAFETY GUIDELINES

1. Seat Belts:
   - All buses must have functioning seat belts
   - Passengers must wear seat belts where fitted
   - Operators are responsible for verifying seat belt function before each trip

2. Fire Safety:
   - Fire extinguishers required on every bus
   - Emergency exits clearly marked and unobstructed
   - Drivers trained in emergency evacuation procedures

3. Driver Rest:
   - Mandatory rest breaks every 4 hours on overnight routes
   - No driver allowed to operate more than 8 hours continuously
   - Fitness verification required before each trip

4. Incident Reporting:
   - Any safety incident must be reported to operator within 24 hours
   - All incidents logged for compliance review
   - Serious incidents escalated to safety officer immediately'),

('baggage_policy.txt', 'REDBUS BAGGAGE RULES

1. Free Allowance:
   - Each passenger: one check-in luggage up to 15 kg
   - Each passenger: one hand bag up to 5 kg

2. Excess Baggage:
   - Charged at Rs. 50 per kg beyond free allowance
   - Must be paid at boarding
   - Operator may refuse excess baggage if bus is full

3. Restricted Items:
   - Flammable, explosive, or hazardous materials prohibited
   - Fragile, valuable, or perishable items travel at owner risk
   - Operators not liable for damage to unregistered hand baggage'),

('loyalty_program.txt', 'REDBUS LOYALTY & REWARDS PROGRAM

1. Point Earning:
   - REGULAR segment: 1 point per Rs. 100 spent
   - VIP segment: 2 points per Rs. 100 spent
   - Points credited within 24 hours of journey completion

2. Point Redemption:
   - 500 points = Rs. 100 off next booking
   - Points can be combined with promotional discounts
   - Minimum 100 points required for redemption

3. Point Expiry:
   - Points expire 12 months after being earned
   - Expired points cannot be reinstated
   - Balance visible in customer account'),

('group_booking_policy.txt', 'REDBUS GROUP BOOKING TERMS

1. Eligibility:
   - Groups of 5 or more passengers on a single booking
   - Must be booked in a single transaction

2. Discount:
   - 15% discount applied automatically
   - Cannot be combined with other promotional offers
   - Full advance payment required at booking

3. Cancellation:
   - Group bookings cannot be partially cancelled
   - Entire group must be cancelled together
   - Follows standard cancellation policy

4. Support:
   - Dedicated support contact for groups of 15+
   - Priority assistance during booking and travel'),

('booking_modification_policy.txt', 'REDBUS BOOKING MODIFICATION & RESCHEDULING

1. Rescheduling:
   - Allowed up to 6 hours before departure
   - Subject to seat availability
   - Rescheduling fee: Rs. 100

2. Restrictions:
   - Rescheduling within 6 hours of departure not permitted
   - Treated as cancellation if attempted
   - Only one reschedule allowed per booking

3. Process:
   - Request via app or website
   - Confirmation email sent after successful reschedule
   - Refund of rescheduling fee not applicable'),

('customer_support_policy.txt', 'REDBUS CUSTOMER SUPPORT & ESCALATION

1. Availability:
   - 24x7 support through app chat and helpline
   - Multi-language support available

2. Resolution Timeline:
   - Standard queries: within 24 hours
   - Refund and complaint escalations: within 5 business days
   - Grievance officer escalation: within 10 business days

3. Escalation Path:
   - Level 1: Customer support agent
   - Level 2: Regional support manager
   - Level 3: Grievance officer

4. Contact:
   - In-app chat: fastest response
   - Helpline: 1-800-REDBUS
   - Email: support@redbus.com'),

('kpi_glossary.txt', 'REDBUS ANALYTICS - KPI DEFINITIONS

1. Total Bookings:
   - Count of all booking lines in the fact table
   - Includes cancelled bookings

2. Total Revenue:
   - Sum of fare_amount multiplied by passenger_count
   - Before discount applied

3. Net Revenue:
   - Sum of net_amount (after discount applied)
   - This is the actual money received

4. Average Fare:
   - Average of fare_amount across all bookings
   - Does not account for passenger count

5. Cancellation Rate:
   - Percentage of bookings with status = CANCELLED
   - Formula: (Cancelled Bookings / Total Bookings) * 100

6. Occupancy Rate:
   - Ratio of passengers carried to total seat capacity
   - Formula: (Passengers / Seat Capacity) * 100

7. Revenue Per KM:
   - Net revenue divided by route distance
   - Useful for comparing route profitability');

-- Verify documents loaded
SELECT COUNT(*) AS TOTAL_DOCS FROM REDBUS_ANALYTICS.DW.DOCS;

SELECT DOC_ID, FILE_NAME, LEFT(FILE_CONTENT, 80) AS PREVIEW
FROM REDBUS_ANALYTICS.DW.DOCS
ORDER BY DOC_ID;

CREATE OR REPLACE TABLE REDBUS_ANALYTICS.OPS.LOAD_AUDIT (
    AUDIT_ID       NUMBER AUTOINCREMENT START 1 INCREMENT 1 PRIMARY KEY,
    TABLE_NAME     VARCHAR(100),
    ROWS_LOADED    NUMBER,
    LOAD_TS        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    STATUS         VARCHAR(20),
    REMARKS        VARCHAR(500)
);

-- Log initial load
INSERT INTO REDBUS_ANALYTICS.OPS.LOAD_AUDIT (TABLE_NAME, ROWS_LOADED, STATUS, REMARKS)
SELECT 'RAW_CUSTOMERS', COUNT(*), 'SUCCESS', 'Initial load' FROM REDBUS_ANALYTICS.RAW.RAW_CUSTOMERS
UNION ALL SELECT 'RAW_ROUTES', COUNT(*), 'SUCCESS', 'Initial load' FROM REDBUS_ANALYTICS.RAW.RAW_ROUTES
UNION ALL SELECT 'RAW_BUSES', COUNT(*), 'SUCCESS', 'Initial load' FROM REDBUS_ANALYTICS.RAW.RAW_BUSES
UNION ALL SELECT 'RAW_BOOKINGS', COUNT(*), 'SUCCESS', 'Initial load' FROM REDBUS_ANALYTICS.RAW.RAW_BOOKINGS;

SELECT * FROM REDBUS_ANALYTICS.OPS.LOAD_AUDIT ORDER BY LOAD_TS DESC;


CREATE OR REPLACE FUNCTION REDBUS_ANALYTICS.DW.SEARCH_POLICY(QUESTION STRING)
RETURNS TABLE (DOC_ID INTEGER, FILE_NAME STRING, FILE_CONTENT STRING, RELEVANCE NUMBER)
AS
$$
  SELECT
    DOC_ID,
    FILE_NAME,
    FILE_CONTENT,
    (SELECT COUNT(*)
     FROM TABLE(SPLIT_TO_TABLE(LOWER(QUESTION), ' ')) W
     WHERE LENGTH(W.VALUE) > 3
       AND W.VALUE NOT IN ('what','when','where','which','does','their','with','from','have','this','that')
       AND CONTAINS(LOWER(FILE_CONTENT), W.VALUE)
    ) AS RELEVANCE
  FROM REDBUS_ANALYTICS.DW.DOCS
  ORDER BY RELEVANCE DESC
  LIMIT 1
$$;

-- Test the function
SELECT * FROM TABLE(REDBUS_ANALYTICS.DW.SEARCH_POLICY('What is the cancellation fee?'));
SELECT * FROM TABLE(REDBUS_ANALYTICS.DW.SEARCH_POLICY('How do I get a refund?'));
SELECT * FROM TABLE(REDBUS_ANALYTICS.DW.SEARCH_POLICY('What are the operator standards?'));

-- Full layer validation
SELECT 'BRONZE.brz_customers' AS LAYER_OBJECT, COUNT(*) AS ROW_COUNT FROM REDBUS_ANALYTICS.BRONZE.BRZ_CUSTOMERS
UNION ALL SELECT 'BRONZE.brz_routes', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_ROUTES
UNION ALL SELECT 'BRONZE.brz_buses', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_BUSES
UNION ALL SELECT 'BRONZE.brz_bookings', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_BOOKINGS
UNION ALL SELECT 'SILVER.dim_date', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_DATE
UNION ALL SELECT 'SILVER.dim_route', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_ROUTE
UNION ALL SELECT 'SILVER.dim_customer', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_CUSTOMER
UNION ALL SELECT 'SILVER.dim_bus', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_BUS
UNION ALL SELECT 'SILVER.fact_booking', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.FACT_BOOKING
UNION ALL SELECT 'GOLD.vw_customer', COUNT(*) FROM REDBUS_ANALYTICS.GOLD.VW_CUSTOMER
UNION ALL SELECT 'GOLD.vw_route', COUNT(*) FROM REDBUS_ANALYTICS.GOLD.VW_ROUTE
UNION ALL SELECT 'GOLD.vw_bus', COUNT(*) FROM REDBUS_ANALYTICS.GOLD.VW_BUS
UNION ALL SELECT 'GOLD.vw_bookings', COUNT(*) FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS;



SELECT 'RAW_CUSTOMERS' AS TBL, COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_CUSTOMERS
UNION ALL SELECT 'RAW_ROUTES', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_ROUTES
UNION ALL SELECT 'RAW_BUSES', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_BUSES
UNION ALL SELECT 'RAW_BOOKINGS', COUNT(*) FROM REDBUS_ANALYTICS.RAW.RAW_BOOKINGS;

-- after runing dbt we have to verify this
SELECT 'BRONZE.brz_customers' AS LAYER_OBJECT, COUNT(*) AS ROW_COUNT FROM REDBUS_ANALYTICS.BRONZE.BRZ_CUSTOMERS
UNION ALL SELECT 'BRONZE.brz_routes', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_ROUTES
UNION ALL SELECT 'BRONZE.brz_buses', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_BUSES
UNION ALL SELECT 'BRONZE.brz_bookings', COUNT(*) FROM REDBUS_ANALYTICS.BRONZE.BRZ_BOOKINGS
UNION ALL SELECT 'SILVER.dim_date', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_DATE
UNION ALL SELECT 'SILVER.dim_route', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_ROUTE
UNION ALL SELECT 'SILVER.dim_customer', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_CUSTOMER
UNION ALL SELECT 'SILVER.dim_bus', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.DIM_BUS
UNION ALL SELECT 'SILVER.fact_booking', COUNT(*) FROM REDBUS_ANALYTICS.SILVER.FACT_BOOKING
UNION ALL SELECT 'GOLD.vw_bookings', COUNT(*) FROM REDBUS_ANALYTICS.GOLD.VW_BOOKINGS;



-- removing the manual one 
DROP SCHEMA IF EXISTS REDBUS_ANALYTICS.SEMANTIC CASCADE;
-- Verify DBT_DEV is empty
SELECT COUNT(*) FROM REDBUS_ANALYTICS.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DBT_DEV';

-- If count is 0:
DROP SCHEMA IF EXISTS REDBUS_ANALYTICS.DBT_DEV CASCADE;
DROP SCHEMA IF EXISTS REDBUS_ANALYTICS.DBT_DEV_BRONZE CASCADE;
