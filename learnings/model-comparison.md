# Model Comparison

Track which AI models excel at which tasks based on real project experience.

**Last Updated:** 2026-01-28

## Model Overview

| Model | Context | Strengths | Weaknesses | Cost |
|-------|---------|-----------|------------|------|
| Claude Sonnet 4.5 | 200k | Architecture, review, writing | [TBD] | $$$ |
| Claude Opus 4.5 | 200k | Complex reasoning | [TBD] | $$$$ |
| GPT-4 Turbo | 128k | Debugging, broad knowledge | [TBD] | $$$ |
| GPT-4o | 128k | Speed, multimodal | [TBD] | $$ |
| Gemini 1.5 Pro | 1M+ | Massive context | [TBD] | $$ |

## Task Performance Matrix

**Rating:** ⭐⭐⭐ Excellent | ⭐⭐ Good | ⭐ Adequate

### Architecture & Design

| Model | Rating | Notes |
|-------|--------|-------|
| Claude Sonnet | ⭐⭐⭐ | Excellent at trade-off analysis, system thinking |
| Claude Opus | ⭐⭐⭐ | Even better for complex systems |
| GPT-4 Turbo | ⭐⭐ | Solid but less nuanced on trade-offs |
| GPT-4o | ⭐⭐ | Fast but sometimes misses edge cases |
| Gemini | ⭐⭐ | Good with large context for understanding existing systems |

### Code Implementation

| Model | Rating | Notes |
|-------|--------|-------|
| Claude Sonnet | ⭐⭐⭐ | Clean, maintainable code |
| GPT-4 Turbo | ⭐⭐⭐ | Very capable, good across languages |
| GPT-4o | ⭐⭐ | Fast but occasionally cuts corners |
| Gemini | ⭐⭐ | Competent but less consistent |

### Code Review

| Model | Rating | Notes |
|-------|--------|-------|
| Claude Sonnet | ⭐⭐⭐ | Thorough security review, finds subtle issues |
| GPT-4 Turbo | ⭐⭐⭐ | Good pattern recognition |
| Claude Opus | ⭐⭐⭐ | Most thorough but slower/expensive |
| GPT-4o | ⭐⭐ | Quick pass but misses some issues |

### Debugging

| Model | Rating | Notes |
|-------|--------|-------|
| GPT-4 Turbo | ⭐⭐⭐ | Excellent at analyzing stack traces |
| Claude Sonnet | ⭐⭐ | Systematic but sometimes slower to isolate |
| GPT-4o | ⭐⭐ | Fast iteration for simple bugs |

### Documentation

| Model | Rating | Notes |
|-------|--------|-------|
| Claude Sonnet | ⭐⭐⭐ | Concise, clear writing |
| GPT-4 Turbo | ⭐⭐ | Good but can be verbose |
| GPT-4o | ⭐⭐ | Quick docs but sometimes misses details |

### Refactoring

| Model | Rating | Notes |
|-------|--------|-------|
| Claude Sonnet | ⭐⭐⭐ | Preserves intent well |
| Claude Opus | ⭐⭐⭐ | Best for complex refactors |
| GPT-4 Turbo | ⭐⭐ | Capable but occasionally changes behavior |

## Best Model for Scenario

### Speed-Critical Tasks
**Winner:** GPT-4o
**Use when:** Quick iterations, simple tasks, prototyping

### Quality-Critical Tasks
**Winner:** Claude Opus 4.5
**Use when:** Production code, complex systems, security-sensitive

### Balanced Quality/Speed
**Winner:** Claude Sonnet 4.5
**Use when:** Most day-to-day development (default choice)

### Large Codebase Understanding
**Winner:** Gemini 1.5 Pro
**Use when:** Need to understand/refactor massive codebases

### Cost-Sensitive Projects
**Winner:** GPT-4o
**Use when:** Budget constraints, non-critical code

## Model Switching Strategies

### When to Switch Models

1. **Claude → GPT**
   - Debugging complex traces (GPT better at stack analysis)
   - Need faster iteration cycles
   - Hit Claude API rate limits

2. **GPT → Claude**
   - Need better security review
   - Architecture decisions requiring trade-off analysis
   - Code quality is paramount

3. **Either → Gemini**
   - Massive codebase context needed
   - Long-running context sessions
   - Multi-file refactoring

### How to Switch Models

1. **Summarize context** from current session
2. **Extract key decisions** made so far
3. **Provide new model** with summary + specific task
4. **Reference patterns** from META for consistency

See `workflows/model-switching.md` for detailed process.

## Project-Specific Findings

### test-app - 2026-01-27
- **Claude** excelled at PRD/architecture planning but hit usage limits mid‑pipeline.
- **Codex** completed implementation/testing steps after switching, but required sandbox write access for tests (Vitest temp dirs).

*Add new entries here as you complete projects*

## Anti-Patterns Discovered

### Don't

- ❌ Use GPT-4o for security reviews (misses issues)
- ❌ Use Claude for rapid debugging iteration (slower)
- ❌ Switch models mid-implementation (loses context)
- ❌ Use Opus for simple tasks (unnecessary cost)

### Do

- ✅ Use Claude Sonnet as default
- ✅ Switch to GPT-4 for debugging
- ✅ Use Opus for critical/complex work
- ✅ Use 4o for prototyping/exploration

## Update Process

After each project retrospective:

1. Review model usage from project
2. Update ratings based on real experience
3. Add specific findings to project section
4. Revise recommendations if patterns change

**Guideline:** Update this after every 2-3 completed projects or when you notice a clear pattern shift.
