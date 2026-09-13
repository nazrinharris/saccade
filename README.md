# Saccade
A "me-first" generalized workspace. A sinkhole for project management, time tracking, random records, and connected data. Shamelessly inspired by Fibery and Notion.

---
# What is Saccade?
Saccade is a self-hosted generalized workspace. It is for structured information and connected work. My intention is to replace my dependence on apps like Notion, Fibery, etc. Allowing me for heavy customization and of course, data that is mine.

I love and want to follow the philosophy of an "app builder" of sorts. With Saccade, one can create databases for whatever that's needed. Projects, tasks, documents, financial records, item records. Fields and relations can be defined easily and views can be created to view those records. Creating an ordinary database is an action in Saccade, not a change to its source code.

Databases can be organized into workspaces: groups of databases belonging to one workflow or domain, like Fibery's workspaces. A workspace for project tracking, one for records and collections, one for education and career, and so on.

Schema-specific interfaces, hand-written and personal, sit on top of the same data when the generic experience isn't enough. 

Like I said, Fibery. But with an emphasis on ME and less business/collaboration oriented. Maybe in the future I'll want to widen the scope, but this is what I want right now.

---
# Boundaries

I want to make it clear what Saccade is and isn't. Someone (i.e. me) defines what Saccade is to them. So, this app is:
1. a generalized workspace
2. a client over self-hosted data authority
3. a place to create and use connected databases
4. an environment that can host schema-specific interfaces
5. a software with extensibility and customizability to my liking

Saccade is **not**:
1. a project-management focused application (though one can make it be)
2. a mere frontend hard-coded to a backend (as of this moment Teable)
3. a database server
4. a Notion clone (though heavy inspiration)
5. a Fibery clone (though **very heavy** inspiration)

---
# Architecture
Saccade can be divided into two parts. Obviously, the backend and the frontend.
## Backend (Teable)
Saccade depends on Teable as its primary backend source. Essentially the reason was I wanted a flexible data layer at runtime, just like how Fibery does it, but didn't want to spend too much time building and validating such a system. So Teable was chosen to be its backend. Teable is just the database: it owns the schema, the records, and the API. Nothing more is asked of it.

Saccade's own state (saved views, workspace definitions, future extension bindings) lives as records in a dedicated system table inside the same Teable base. No state on any single device; the base is the single source of truth.

In the future, there may be a middle layer service to allow for more specific and advanced features, and maybe even replacing Teable, but that's for the future.
## Frontend (Flutter)
Flutter, web-first. The same codebase can target desktop and mobile later, but the browser is the primary surface.

---
# Status
Early development. v1 is an MVP that meets my needs: the generalized workspace end-to-end, meaning runtime schema, records, relations, views, workspaces.