-- Migration: Fix cardinality violation in is_member_of_project function
-- Description: Changes '=' to 'IN' to handle multiple team memberships gracefully.

CREATE OR REPLACE FUNCTION is_member_of_project(_project_id uuid, _user_id uuid, _team_id uuid) RETURNS boolean
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    RETURN EXISTS(SELECT 1
                  FROM project_members
                  WHERE project_id = _project_id
                    AND team_member_id IN (SELECT id FROM team_members WHERE team_id = _team_id AND user_id = _user_id));
END
$$;
