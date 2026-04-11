-- Migration: Add missing columns to projects table
-- These columns are referenced by the backend (projects-controller.ts getById)
-- but were missing from the base schema (1_tables.sql).
-- Without these columns, opening a project after creation fails.

ALTER TABLE projects ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'USD';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS budget NUMERIC(15,2) DEFAULT 0;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS budget_type VARCHAR(20) DEFAULT 'fixed';
