# META Base Agent Config

This file is the model-agnostic entrypoint for projects.

For the actual base agent definition, see: `agents/base.md`

---

**Projects should inherit as:**

```markdown
# My Project

Inherits: ../META/agents/base.md

[project-specific content]
```

---

**For multi-agent workflows**, see:
- `agents/product-manager.md` - PRD + scope definition
- `agents/architect.md` - System design & planning
- `agents/reviewer.md` - Code review specialist
- `agents/debugger.md` - Debug specialist
- `agents/documenter.md` - Documentation writer
- `agents/orchestrator.md` - Multi-agent coordinator

See `workflows/multi-agent.md` for orchestration patterns.

---

## Tool-Specific Notes

If your tool expects a specific filename (e.g., `CLAUDE.md`), use that file
name and keep the content identical to this file. The behavior is the same.

