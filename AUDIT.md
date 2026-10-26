# TaskSphere Schema Audit

## Scope note

The supplied challenge attachment contains the TaskSphere symptoms and required outputs, but it does not include a repository URL, broken ER image, or broken SQL file. The archive available in the workspace contains an unrelated FocusForge application. This audit therefore records the broken baseline implied by the brief and makes each redesign assumption explicit.

## Findings

| ID | Broken-design finding | Production impact | Correction |
| --- | --- | --- | --- |
| F-01 | Projects, tasks, and team members are not separated into stable entities with primary keys. | Rows cannot be referenced reliably, updates become ambiguous, and duplicate records appear in reports. | Added UUID primary keys to `users`, `teams`, `projects`, and `tasks`; junction tables use composite primary keys. |
| F-02 | A task assignment is represented without an enforced relationship to a user. | A task can point to a user that does not exist, producing orphaned assignments and broken joins. | Added `task_assignees(task_id, user_id)` with foreign keys to `tasks` and `users`. |
| F-03 | Team membership and project membership are stored as repeated columns or embedded lists. | Many-to-many relationships become difficult to query and invite duplicate membership rows. | Added normalized `team_members` and `project_members` junction tables. |
| F-04 | Project and task attributes are duplicated across report rows. | A rename or status change can update one copy and leave conflicting values elsewhere. | Kept descriptive attributes on their owning entity and connected records by foreign keys. |
| F-05 | No uniqueness rules exist for natural identifiers. | The same user or same project name can be inserted repeatedly, causing duplicate report counts. | Added `users.email UNIQUE` and `projects(team_id, name) UNIQUE`. |
| F-06 | Frequently filtered relationship columns are not indexed. | Project task lists and user assignment queries degrade as data grows. | Added indexes for project status, due dates, membership lookups, assignee lookups, and parent tasks. |
| F-07 | Optional values and lifecycle values have no domain rules. | Invalid status strings, impossible priorities, and inconsistent null semantics leak into application code. | Added `NOT NULL`, `CHECK` constraints, defaults, and a partial due-date index. |
| F-08 | Ownership is not enforced as a meaningful relationship. | A project owner can be someone outside the project, creating authorization ambiguity. | Added `owner_id` as a foreign key plus a deferred constraint trigger requiring project membership. |

## Relationship review

A team has many members and a user can join many teams, so `team_members` resolves a many-to-many relationship. A team owns many projects, while a project has many members through `project_members`. A project contains many tasks. Tasks can have multiple assignees through `task_assignees`, and a task can optionally have a parent task for decomposition.

## Normalization review

The corrected design is close to Third Normal Form. Each table represents one subject or relationship, every non-key attribute depends on the whole key, and no non-key attribute is stored because it depends on another non-key attribute. Reporting joins are performed through foreign keys instead of copied names or comma-separated IDs.
