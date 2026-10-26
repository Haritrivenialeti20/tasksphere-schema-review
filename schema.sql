-- TaskSphere corrected schema
-- PostgreSQL 15+

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teams (
  team_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE team_members (
  team_id UUID NOT NULL REFERENCES teams(team_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (team_id, user_id)
);

CREATE TABLE projects (
  project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(team_id) ON DELETE RESTRICT,
  owner_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (team_id, name)
);

CREATE TABLE project_members (
  project_id UUID NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);

CREATE TABLE tasks (
  task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  parent_task_id UUID REFERENCES tasks(task_id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done', 'blocked')),
  priority SMALLINT NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE task_assignees (
  task_id UUID NOT NULL REFERENCES tasks(task_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (task_id, user_id)
);

CREATE INDEX idx_projects_team_id ON projects(team_id);
CREATE INDEX idx_project_members_user_id ON project_members(user_id);
CREATE INDEX idx_tasks_project_status ON tasks(project_id, status);
CREATE INDEX idx_tasks_due_at ON tasks(due_at) WHERE due_at IS NOT NULL;
CREATE INDEX idx_task_assignees_user_id ON task_assignees(user_id);
CREATE INDEX idx_tasks_parent_task_id ON tasks(parent_task_id);

-- Optional integrity trigger: a project owner must also be a project member.
CREATE OR REPLACE FUNCTION enforce_project_owner_membership()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM project_members
    WHERE project_id = NEW.project_id AND user_id = NEW.owner_id
  ) THEN
    RAISE EXCEPTION 'Project owner must be a project member';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER project_owner_is_member
AFTER INSERT OR UPDATE OF owner_id, project_id ON projects
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION enforce_project_owner_membership();
