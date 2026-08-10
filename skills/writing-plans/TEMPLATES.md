# Plan Templates

## Simple Plan Template

```markdown
# Plan: [Title]

**Date:** YYYY-MM-DD
**Status:** DRAFT | APPROVED | IN-PROGRESS | COMPLETED
**Risk Level:** Low | Medium | High

---

## Overview

[Brief description of what will be implemented]

## Goal

[What the plan achieves]

## Requirements

- [Spec/requirement — behavior, constraints, acceptance criteria]

## Tasks

### Task 1: [Title]

**Description:** [What to implement]
**Files:** [List of files to modify/create]
**Test:** [What to test before implementing]
**Verify:** [Command to confirm it works]

- [ ] [Specific step 1]
- [ ] [Specific step 2]

### Task 2: [Title]

[Same structure]

---

## Open Questions

- [Unresolved questions]
```

## Multi-Phase Plan Template

```markdown
# Plan: [Title]

**Date:** YYYY-MM-DD
**Status:** DRAFT | APPROVED | IN-PROGRESS | COMPLETED
**Risk Level:** Low | Medium | High

---

## Overview

[Brief description]

## Goal

[What the plan achieves]

## Requirements

- [Spec/requirement — behavior, constraints, acceptance criteria]

## Phase 1: [Name]

### Task 1.1: [Title]

**Description:** [What to implement]
**Files:** [List of files]
**Test:** [What to test first]
**Verify:** [Command to run]

- [ ] [Step 1]
- [ ] [Step 2]

### Task 1.2: [Title]

[Same structure]

---

## Phase 2: [Name]

[Same structure]

---

## Dependencies

| Task | Depends On |
|------|------------|
| 1.2  | 1.1        |
| 2.1  | 1.1, 1.2   |

## Open Questions

- [Unresolved questions]
```