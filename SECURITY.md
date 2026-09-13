# Security model

Authorization is enforced in **two** places, in order of authority:

1. **Firebase Security Rules** (`firestore.rules`) — the source of truth for
   every read and write. There is no server tier; privileged operations
   (provisioning accounts, bulk import) run from the manager's client and are
   validated by these rules.
2. **Flutter UI / routing** — hides unauthorized actions only. Never trusted.

## Account provisioning without a server

A client cannot create an Auth user without signing *itself* in as that user,
and cannot disable or delete another user's Auth record. So:

- **Create** — the account is created on a throwaway secondary `FirebaseApp`
  (`UserProvisioner`), which signs out and is deleted; the manager's session on
  the default app is untouched. The `users/{uid}` profile is then written and
  validated by the `users` create rule.
- **Deactivate** — `isActive: false` on the profile. Rules treat any user whose
  profile is missing or `isActive != true` as having no privileges, and the
  client signs such a session out on the next auth-state emission.
- **Delete** — the `users/{uid}` profile is removed. The orphaned Auth record
  has no profile, so rules deny it everything; a manager clears it from the
  Firebase console (Authentication tab) when convenient.

## Roles

| Role | Kind | Home |
|------|------|------|
| `security` | internal | `/security` |
| `manager` | internal | `/manager` |
| `supervisor` | internal | `/supervisor` |
| `parent` | external | `/parent` |

A user's role and `isActive` flag live in `users/{uid}`. Deactivated accounts
have **no** privileges (rules check `isActive == true`) and are signed out
client-side on the next auth-state emission.

## Permission matrix

| Collection | security | manager | supervisor | parent |
|------------|----------|---------|------------|--------|
| `users/{uid}` | read others | read others | read others | read **self only** |
| `users` writes | — | ✅ create (role/isActive validated), update (identity locked), delete | — | — |
| `students` read | ✅ | ✅ | ✅ | **linked children only** |
| `students` write | — | ✅ (id/qr/names validated) | — | — |
| `workers` read | ✅ | ✅ | ✅ | — |
| `workers` write | — | ✅ | — | — |
| `attendance` read | ✅ | ✅ | ✅ | **own child's records only** |
| `attendance` create/update | ✅ (identity + check-in audit locked) | ✅ historical Excel import only | — | — |
| `attendance` delete | — | — | — | — |
| `pickupRequests` read | ✅ | ✅ | ✅ | **own requests only** |
| `pickupRequests` create | — | — | — | ✅ pending, own child, `requestedAt == request.time` |
| `pickupRequests` update | ✅ any status | — | — | **own → `cancelled` only** |
| `pickupRequests` delete | — | — | — | — |
| `pickupActive/{studentId}` | delete | — | — | create/delete for own child |
| `metadata/counters` | — | ✅ | — | — |

## Parent ↔ student link

The link is `users/{parentUid}.studentIds: [...]`. Rules validate it with
`parentOwnsStudent(studentId)` — a `studentId` sent by the client is **never**
trusted on its own. Only a manager can change the link (`users` update rule);
the client also checks each student exists before writing.

## Business rules not expressible in Security Rules

Attendance state transitions (Rules 1–3: no double check-in, no check-out
without check-in, no double check-out) and pickup status transitions are
enforced **transactionally in the client** via the pure `AttendanceRules` /
`PickupRules` classes and re-checked inside each Firestore transaction. Rules
lock down identity/audit fields so a compromised client still cannot rewrite
history.

## Tests

- `test/` — Dart unit tests for the business-rule classes and Cubits.
