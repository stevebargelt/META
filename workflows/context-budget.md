# Context Budget

Proactive context management to avoid hitting token limits mid-task.

## Zones

| Zone | Heuristic | Action |
|------|-----------|--------|
| Green | 0-40% — fewer than ~15 files loaded, early-to-mid session | Normal work. Load files as needed. |
| Yellow | 40-50% — 15+ files loaded or 30+ turns, conversation feels long | Stop loading new files. Write `.handoff.md`. Suggest reset. |
| Red | 50%+ — model slowing down, forgetting earlier context, warnings | Immediately write `.handoff.md` and reset. |

## Estimating Budget

Models can't see their own token count. Use these heuristics:

- **File count:** Each file read adds ~100-500 lines of context. After ~15 files, assume Yellow.
- **Turn count:** After ~30 back-and-forth turns, assume Yellow.
- **Behavioral signals:** Slower responses, forgetting earlier decisions, repeating questions = Red.
- **Large files:** A single 500+ line file counts as 2-3 files for budget purposes.

## What Belongs in Context vs. On Disk

**Always load:**
- `.handoff.md` (if resuming)
- Project `AGENTS.md`
- Files actively being edited

**Load on demand:**
- Files referenced in handoff Key Files section
- Pattern files from META/patterns/
- Test files when writing tests

**Never bulk-load:**
- Full architecture docs (reference specific sections)
- All pattern files
- Git history
- Entire directories

## Checkpointing

Assess context budget after each discrete unit of work (feature, bug fix, review pass). If in Yellow:

1. Write `.handoff.md` per `prompts/handoff-template.md`
2. Commit current work
3. Suggest reset to user

Don't wait for Red. Yellow is the action zone.
