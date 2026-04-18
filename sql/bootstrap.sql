-- =============================================================
-- AUDITED_FINANCIALS bootstrap — Cortex edition
-- Idempotent: safe to re-run.
-- New vs. original: adds @AFS_STAGE and COMMON.PDF_STAGING.
-- =============================================================
CREATE DATABASE IF NOT EXISTS AUDITED_FINANCIALS
    COMMENT = 'Parsed health system audited financial statements + consulting insights';

USE DATABASE AUDITED_FINANCIALS;

CREATE SCHEMA IF NOT EXISTS COMMON
    COMMENT = 'Cross-org standardized model, registries, and findings';

USE SCHEMA COMMON;

-- -------------------------------------------------------------
-- @AFS_STAGE  — internal stage for incoming PDF files
-- -------------------------------------------------------------
CREATE STAGE IF NOT EXISTS AFS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Upload AFS PDFs here before running the ingest notebook';

-- -------------------------------------------------------------
-- PDF_STAGING  — extracted text cache (avoids re-calling PARSE_DOCUMENT)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PDF_STAGING (
    STAGING_ID      STRING      NOT NULL PRIMARY KEY DEFAULT UUID_STRING(),
    FILENAME        STRING      NOT NULL UNIQUE,        -- bare filename as in stage
    FILING_ID       STRING      NOT NULL,               -- sha256 of page text blob
    TOTAL_PAGES     NUMBER      NOT NULL,
    PAGE_TEXTS      VARIANT     NOT NULL,               -- [{page: N, text: "..."}]
    EXTRACTED_AT    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    STATUS          STRING      DEFAULT 'pending',      -- pending | processing | done | failed
    STAGES_COMPLETED VARIANT    DEFAULT PARSE_JSON('[]') -- list of completed stage names for resume
);

-- -------------------------------------------------------------
-- ORG_REGISTRY
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ORG_REGISTRY (
    ORG_ID          STRING      NOT NULL PRIMARY KEY,
    ORG_CODE        STRING      NOT NULL UNIQUE,
    LEGAL_NAME      STRING      NOT NULL,
    DBA             STRING,
    EIN             STRING,
    HQ_STATE        STRING,
    FYE_MONTH       NUMBER(2),
    SECTOR          STRING,
    FIRST_SEEN      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    NOTES           STRING
);

-- -------------------------------------------------------------
-- FILINGS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS FILINGS (
    FILING_ID           STRING      NOT NULL PRIMARY KEY,
    ORG_ID              STRING      NOT NULL,
    FISCAL_YEAR_END     DATE        NOT NULL,
    FY_LABEL            STRING      NOT NULL,
    YEARS_PRESENT       ARRAY,
    AUDIT_FIRM          STRING,
    AUDIT_OPINION       STRING,
    SOURCE_FILENAME     STRING,
    PAGE_COUNT          NUMBER,
    PARSED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    EXTRACTOR_VERSION   STRING,
    EXTRACTION_BLOB     VARIANT,
    CONSTRAINT FK_FILINGS_ORG FOREIGN KEY (ORG_ID) REFERENCES ORG_REGISTRY(ORG_ID)
);

-- -------------------------------------------------------------
-- STANDARD_TAXONOMY  (seeded from sql/standard_taxonomy_seed.csv)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS STANDARD_TAXONOMY (
    CONCEPT             STRING      NOT NULL PRIMARY KEY,
    STATEMENT           STRING      NOT NULL,
    CATEGORY            STRING,
    DEFINITION          STRING,
    SIGN_CONVENTION     STRING,
    UOM                 STRING,
    PARENT_CONCEPT      STRING
);

-- -------------------------------------------------------------
-- LINE_ITEM_MAP
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS LINE_ITEM_MAP (
    ORG_ID              STRING      NOT NULL,
    NATIVE_LABEL_NORM   STRING      NOT NULL,
    NATIVE_LABEL        STRING,
    STATEMENT           STRING      NOT NULL,
    CONCEPT             STRING,
    CONFIDENCE          FLOAT,
    RATIONALE           STRING,
    SOURCE              STRING,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_LIM PRIMARY KEY (ORG_ID, NATIVE_LABEL_NORM, STATEMENT)
);

-- -------------------------------------------------------------
-- Standardized statement tables
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS INCOME_STATEMENT (
    FILING_ID           STRING      NOT NULL,
    ORG_ID              STRING      NOT NULL,
    FY_LABEL            STRING      NOT NULL,
    FISCAL_YEAR_END     DATE,
    CONCEPT             STRING      NOT NULL,
    AMOUNT              NUMBER(38,2),
    UOM                 STRING      DEFAULT 'usd',
    NATIVE_LABEL        STRING,
    SOURCE_PAGE         NUMBER,
    CONFIDENCE          FLOAT,
    LOADED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_IS PRIMARY KEY (ORG_ID, FY_LABEL, CONCEPT)
);

CREATE TABLE IF NOT EXISTS BALANCE_SHEET (
    FILING_ID           STRING      NOT NULL,
    ORG_ID              STRING      NOT NULL,
    FY_LABEL            STRING      NOT NULL,
    FISCAL_YEAR_END     DATE,
    CONCEPT             STRING      NOT NULL,
    AMOUNT              NUMBER(38,2),
    UOM                 STRING      DEFAULT 'usd',
    NATIVE_LABEL        STRING,
    SOURCE_PAGE         NUMBER,
    CONFIDENCE          FLOAT,
    LOADED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_BS PRIMARY KEY (ORG_ID, FY_LABEL, CONCEPT)
);

CREATE TABLE IF NOT EXISTS CASH_FLOW (
    FILING_ID           STRING      NOT NULL,
    ORG_ID              STRING      NOT NULL,
    FY_LABEL            STRING      NOT NULL,
    FISCAL_YEAR_END     DATE,
    CONCEPT             STRING      NOT NULL,
    AMOUNT              NUMBER(38,2),
    UOM                 STRING      DEFAULT 'usd',
    NATIVE_LABEL        STRING,
    SOURCE_PAGE         NUMBER,
    CONFIDENCE          FLOAT,
    LOADED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_CF PRIMARY KEY (ORG_ID, FY_LABEL, CONCEPT)
);

CREATE TABLE IF NOT EXISTS OPERATING_STATS (
    FILING_ID           STRING      NOT NULL,
    ORG_ID              STRING      NOT NULL,
    FY_LABEL            STRING      NOT NULL,
    FISCAL_YEAR_END     DATE,
    CONCEPT             STRING      NOT NULL,
    AMOUNT              NUMBER(38,4),
    UOM                 STRING,
    NATIVE_LABEL        STRING,
    SOURCE_PAGE         NUMBER,
    CONFIDENCE          FLOAT,
    LOADED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_OS PRIMARY KEY (ORG_ID, FY_LABEL, CONCEPT)
);

-- -------------------------------------------------------------
-- FINDINGS + REVIEW_QUEUE
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS FINDINGS (
    FINDING_ID          STRING      NOT NULL PRIMARY KEY,
    ORG_ID              STRING      NOT NULL,
    FILING_ID           STRING      NOT NULL,
    FY_LABEL            STRING,
    CATEGORY            STRING,
    SEVERITY            STRING,
    TITLE               STRING      NOT NULL,
    NARRATIVE           STRING,
    EST_IMPACT_LOW      NUMBER(38,2),
    EST_IMPACT_HIGH     NUMBER(38,2),
    IMPACT_UNIT         STRING      DEFAULT 'usd_annualized',
    SUPPORTING_CONCEPTS VARIANT,
    PLAYBOOK_HINT       STRING,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS REVIEW_QUEUE (
    REVIEW_ID           STRING      NOT NULL PRIMARY KEY,
    FILING_ID           STRING      NOT NULL,
    ORG_ID              STRING      NOT NULL,
    STATEMENT           STRING,
    NATIVE_LABEL        STRING,
    FY_LABEL            STRING,
    AMOUNT              NUMBER(38,4),
    CONFIDENCE          FLOAT,
    REASON              STRING,
    SOURCE_PAGE         NUMBER,
    PAYLOAD             VARIANT,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    RESOLVED            BOOLEAN     DEFAULT FALSE
);
