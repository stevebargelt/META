# Learnings

Knowledge that compounds across projects.

## Purpose

This directory captures what you learn from actually using AI agents on real projects. The goal is to get smarter over time — patterns that work get reused, patterns that fail get avoided.

## Files

- **`retrospective-template.md`** — Template for post-project reviews
- **`model-comparison.md`** — Which AI models are best for which tasks
- **`what-works.md`** — Proven patterns and approaches
- **`what-doesnt.md`** — Anti-patterns to avoid

## Usage

### After Each Project Milestone

1. Copy `retrospective-template.md` to `YYYY-MM-project-name.md`
2. Fill it out while the project is fresh
3. Extract insights to `what-works.md` or `what-doesnt.md`
4. Update `model-comparison.md` if you learned something about model performance
5. Update agent definitions in `agents/` if you discovered better approaches

### When You Discover a Pattern

**If it works:**
1. Add to `what-works.md` immediately
2. Consider extracting to `patterns/` if it's reusable code
3. Update relevant agent if it's a process improvement

**If it doesn't work:**
1. Add to `what-doesnt.md` immediately
2. Note what to do instead
3. Remove from `what-works.md` if it was previously there

### When Switching Models

Check `model-comparison.md` for guidance on which model to use for current task. Update it when you find the guidance wrong.

## Keep It Current

These files are only valuable if they reflect reality. Update them:

- ✅ Immediately when you discover something
- ✅ After each completed project
- ✅ When a pattern stops working
- ✅ When model performance changes

Don't:

- ❌ Wait until "the end" to update
- ❌ Document hypothetical patterns
- ❌ Keep outdated information

## Compound Effect

The more projects you complete:
- The better your agent definitions become
- The larger your pattern library grows
- The more accurate your model selection
- The faster your new projects start

This is knowledge that builds on itself.
