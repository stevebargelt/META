# META Base Agent (Legacy)

This file is for backward compatibility with projects that require `CLAUDE.md`.
The model-agnostic default is `AGENTS.md`.

For the actual base agent definition, see: `agents/base.md`

---

**Projects should now inherit as:**

```markdown
# My Project

Inherits: ../META/agents/base.md

[project-specific content]
```

---

**For multi-agent workflows**, see:
- `agents/architect.md` - System design & planning
- `agents/reviewer.md` - Code review specialist
- `agents/debugger.md` - Debug specialist
- `agents/documenter.md` - Documentation writer
- `agents/orchestrator.md` - Multi-agent coordinator

See `workflows/multi-agent.md` for orchestration patterns.

---

## Legacy Support

If you have existing projects referencing `../META/CLAUDE.md`, they will see this file.

**Migration path:**
1. Update your project's CLAUDE.md to reference `../META/agents/base.md`
2. Or reference specific agents for specialized tasks

The base agent content has moved to `agents/base.md` but the behavior is identical.
