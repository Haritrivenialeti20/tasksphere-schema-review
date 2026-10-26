# TaskSphere Schema Review

This repository contains the corrected relational design for the TaskSphere projects, tasks, and team-members domain.

## Deliverables

- [`AUDIT.md`](./AUDIT.md) — broken-design findings, production impact, and fixes.
- [`schema.sql`](./schema.sql) — PostgreSQL DDL with primary keys, foreign keys, constraints, indexes, and ownership enforcement.
- [`diagrams/tasksphere-er.mmd`](./diagrams/tasksphere-er.mmd) — corrected ER diagram source.
- [`diagrams/tasksphere-er.png`](./diagrams/tasksphere-er.png) — rendered ER diagram for reviewers.

## Design summary

The schema separates users, teams, projects, and tasks from their many-to-many relationships. `team_members`, `project_members`, and `task_assignees` prevent duplicated list columns and enforce valid references. All entities have stable primary keys. Foreign keys prevent orphaned records, while `UNIQUE`, `CHECK`, and `NOT NULL` constraints prevent duplicate or invalid data.

The design also adds indexes for the access paths a task-management backend will use frequently: project task lists, status filters, due dates, member lookups, assignee lookups, and parent-task traversal. A deferred constraint trigger ensures that a project owner is also a project member without making insert order brittle inside a transaction.

## Verification

The SQL was reviewed for PostgreSQL compatibility and cross-checked against the ER diagram. The deliverable intentionally does not include application secrets or a live database connection. To apply it in a PostgreSQL 15+ environment:

```bash
psql "$DATABASE_URL" -f schema.sql
```
