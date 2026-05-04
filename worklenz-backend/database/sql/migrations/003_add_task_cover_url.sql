-- Migration: Add cover_url column to tasks table
-- Date: 2026-05-04
-- Description: Adds a TEXT column for storing task cover photo URLs

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS cover_url TEXT;
