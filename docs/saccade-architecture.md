# Saccade Architecture
**Status:** Working architecture as of 13 September 2026
**Product definition:** [Saccade README](Saccade.md)

---
# System Boundaries
## Teable: the database
Teable owns:
- physical PostgreSQL tables and columns;
- table and field metadata;
- canonical record persistence;
- field constraints, relation integrity, select options, link cardinality;
- the authoritative REST API for schema and record operations.

Nothing more is asked of it. Teable is not the UI, not the view layer, not the workspace experience. Its own interface remains an administrative and recovery fallback.

Saccade reads and mutates all state through Teable's API. It never maintains a competing copy of user schema or records as truth.
## Saccade client: the workspace
The client is responsible for:
- discovering schema at runtime;
- representing databases, fields, relations, records, views, and workspaces;
- schema creation (databases, fields, relations);
- rendering and editing records of supported kinds;
- navigating linked records;
- Saccade-owned views and workspace navigation;
- hosting schema-specific extensions;
- exposing unsupported states and failures visibly.

The v1 client talks directly to Teable. A future middle service is an extension, not a prerequisite.
## Extensions
An extension may deliberately understand particular databases, fields, and relations. It may combine records or provide domain-specific interaction.

An extension must:
- use Saccade's data boundaries, not unrelated HTTP calls;
- declare the schema capabilities it depends on, and diagnose missing or incompatible ones precisely;
- never become the only door to its records.

Binding mechanism (stable IDs, a setup mapping, a portable manifest, or a mix) remains unresolved; dependencies being explicit and diagnosable is settled.
## Optional future service
Automations, semantic search, long-running jobs, integrations, and credential-mediated access may later live in a separate service. Teable remains canonical for user schema and records unless a decision explicitly changes that.

---
# Runtime Model
- **Workspace:** a named group of databases belonging to one workflow or domain (Project Tracking, Records, Education & Career). First-class; every database belongs to exactly one.
- **Database:** a user-facing collection of records, corresponding to a Teable table.
- **Field:** stable identity, display name, kind, constraints, options, kind-specific metadata.
- **Relation:** derived from Teable link metadata: participating databases, paired fields, cardinality.
- **Record:** identity plus values keyed by stable field identity.
- **View:** a Saccade-owned saved description of selection and presentation.
- **Extension:** a purpose-built interface bound to declared schema capabilities.

---
# Field Kinds
v1 scope is based on what I already have: the eight kinds live in the base today.

1. **Editable in v1:** `singleLineText`, `longText`, `number`, `date`, `singleSelect`, `checkbox`, `link`. 
2. **Read-only:** attachment. 
3. **Everything else:** recognized but unsupported: rendered visibly, never hidden, never silently coerced. An unknown kind in a response throws.
4. **Computed fields (formula, lookup, rollup) are deferred**: zero exist in the current base. When supported, Teable's returned result is authoritative; Saccade never reimplements the formula engine.

Each supported kind defines: decode, represent, validate, encode, read-only render, editor render, applicable filter/sort/group, and malformed-state behaviour. A kind may be fully supported, read-only, recognized-unsupported, or unknown.

---
# Writes
Confirmed writes: submit a mutation, take Teable's response, reconcile the displayed record with the authoritative result. No optimistic UI until observed latency justifies it.

The patch contract is fpdart `Option<T>` on every patch field:
- `None` — field untouched;
- `Some(value)` — set;
- `Some(null)` (inner nullable) — clear.

Record deletion maps to Teable's trash-backed delete. Saccade never permanently purges; a purge only happens deliberately from Teable's own admin interface.

---
# Views and System Table
Saccade owns its views. There will be no dependence on Teable views.

Filtering, sorting, and grouping execution is still delegated per-request to Teable's record API query params. Saccade-owned views do not mean fetch-everything-then-filter, though that's not necessarily forbidden. Use what we can.

All Saccade-owned state like view rows, workspace definitions, future extension bindings lives in a dedicated **system table** inside the Teable base:
- identified by naming convention and table-ID list, excluded from generic browsing;
- every row carries a schema **version** field from day one;
- one table today; more system tables only when a demonstrated need appears.

View row payload (initial): name, target database ID, layout type, and a versioned JSON payload of columns, filters, sort. Workspace rows: name, member table IDs.

---
# Navigation and Grouping
The workspace's information architecture — grouped navigation by workspace, databases, recents, relation traversal — is a product-design task for the first UI slice, not decided here beyond: groups are first-class, navigation is grouped by workspace, and the `PT ·` / `RC ·` table-name prefixes are legacy Fibery naming, seeded into workspace definitions once, never parsed at runtime.

---
# Authentication and Deployment
Flutter web cannot keep an embedded secret; a browser-held token is accessible to that browser. The v1 boundary is personal LAN use on trusted devices, no public exposure. Remote or multi-user access would require OAuth, Teable permissions, or a credential-holding service.

A client-side hide/passcode layer, if ever built, is disclosure control, not authorization. Strong authorization is enforced by Teable or a credential-holding service. Deferred until the core works.

---
# Data Ownership and Recovery
Records and physical schema live in the self-hosted Teable/PostgreSQL system and remain fully usable without Saccade. Saccade-owned state must be documented, exportable, and distinguishable from user records. Backups must cover Teable metadata plus the system table.

---
# Invariants
1. The generalized core contains no user-defined domain concepts.
2. Teable is authoritative for user schema and records.
3. Creating a database with supported kinds requires no Saccade code change.
4. Unknown and incompatible data is visible, never silently altered. An unknown field kind throws.
5. Stable IDs are internal identity; names are presentation.
6. Extensions are additive and never trap their records.
7. Extension dependencies are explicit and diagnosable.
8. Removing Saccade removes nothing: the base stands alone.
9. Future services never silently become competing record authorities.
10. Saccade-specific state lives in versioned rows in the base, never device-local only.