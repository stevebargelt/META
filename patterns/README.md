# Patterns Library

Reusable code patterns, configurations, and structures extracted from real projects.

## Purpose

When you solve something well in one project, extract it here so all projects benefit. Patterns are living code/config that you've proven works, not theoretical examples.

## Categories

- **`api/`** — API patterns (REST, GraphQL, error handling, pagination, etc.)
- **`auth/`** — Authentication and authorization patterns
- **`testing/`** — Testing approaches, fixtures, mocking patterns
- **`deployment/`** — Deploy configurations, CI/CD, infrastructure
- **`project-structures/`** — Full project templates and structures

## Adding a Pattern

### When to Add

Add a pattern when:
- ✅ You've used it successfully in a project
- ✅ You'll likely use it again
- ✅ It's more than a few lines
- ✅ It captures a decision or approach

Don't add:
- ❌ Trivial one-liners
- ❌ Theoretical patterns you haven't used
- ❌ Copied from internet without understanding
- ❌ Project-specific code that won't generalize

### How to Add

1. **Create file in appropriate category**
   ```
   patterns/auth/jwt-refresh-rotation.js
   ```

2. **Include header comment**
   ```javascript
   /**
    * JWT Refresh Token Rotation
    *
    * Implements secure refresh token rotation to prevent token replay attacks.
    *
    * Usage: See example at bottom of file
    * Source: MycoGeek project (2026-01)
    * Pattern: When refresh token is used, invalidate it and issue new pair
    */
   ```

3. **Write clean, documented code**
   - Clear variable names
   - Inline comments for non-obvious logic
   - Error handling included
   - Example usage at bottom

4. **Update category README**
   Add entry to the category's README explaining what this pattern does.

## Using Patterns

### In Agent Prompts

Instead of explaining approach:

```markdown
❌ "Implement JWT auth with refresh tokens that rotate on each use..."

✅ "Use the approach in META/patterns/auth/jwt-refresh-rotation.js"
```

### In Project Code

Copy and adapt:

```javascript
// Based on META/patterns/auth/jwt-refresh-rotation.js
// Modified for this project: using Redis instead of Postgres

const rotateRefreshToken = async (oldToken) => {
  // ... adapted implementation
}
```

### Reference, Don't Copy-Paste

Patterns evolve. Reference them so you pick up improvements:

```markdown
# Project AGENTS.md

## Patterns in Use

- Auth: META/patterns/auth/jwt-refresh-rotation.js
- API Errors: META/patterns/api/rest-error-handling.ts
- Testing: META/patterns/testing/integration-test-setup.md
```

## Pattern Format

### Code Patterns

```javascript
/**
 * [Pattern Name]
 *
 * [What it does - 1-2 sentences]
 *
 * Usage: [How to use it]
 * Source: [Which project/when]
 * Pattern: [Core approach]
 */

// Implementation
const example = () => {
  // Clear, documented code
}

// Example usage
/*
Example:

const result = example({
  param: 'value'
})

Output: { ... }
*/
```

### Config Patterns

```json
{
  "_comment": "Pattern: ESLint config for Node.js projects",
  "_source": "Used across: MycoGeek, MeatGeek (2026)",
  "_usage": "Copy to project root as .eslintrc.json",

  "extends": ["eslint:recommended"],
  "rules": {
    // ... actual config
  }
}
```

### Documentation Patterns

```markdown
# [Pattern Name]

**What:** Brief description
**When to use:** Specific scenarios
**Source:** Project where proven

## Implementation

[Actual pattern content]

## Example

[How it's used]

## Variations

[Common adaptations]
```

## Evolution

Patterns should evolve:

**When pattern improves:**
1. Update the pattern file
2. Note what changed and why
3. Consider updating projects using old version
4. Document in learnings if significant

**When pattern stops working:**
1. Move to archive/ subdirectory or delete
2. Add note to learnings/what-doesnt.md
3. Remove references from active projects

## Quick Reference

### Before creating pattern

- [ ] Used successfully in real project
- [ ] More than trivial
- [ ] Will reuse
- [ ] Well-documented

### Pattern checklist

- [ ] Header comment with purpose, usage, source
- [ ] Clean, understandable code
- [ ] Example usage included
- [ ] Added to category README
- [ ] Referenced in source project's retrospective

### Using patterns

- Reference in prompts: "Use META/patterns/[category]/[file]"
- List in project AGENTS.md: "Patterns in Use" section
- Adapt for project needs, note changes
