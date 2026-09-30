---
name: kaleidoscope-thinking
description: Multidimensional problem analysis framework. Use when facing non-trivial problems, architecture decisions, or when the obvious solution feels too easy.
---

# Kaleidoscope Thinking

A framework for multidimensional problem analysis. Use this when facing non-trivial problems, architecture decisions, or when the obvious solution feels too easy.

## When to activate

- User asks for help with a design decision
- Bug fix that might have deeper root causes
- Feature request that could be solved multiple ways
- You're about to propose something and want to stress-test it
- User explicitly asks for creative/alternative approaches

## The Lenses

Rotate through these perspectives before committing to a solution:

### 1. Naive
What's the obvious, first-instinct approach? Write it down. This is your baseline.

### 2. Contrarian
What if the opposite is true? If your instinct is "add a cache," ask "what if we removed caching entirely?" If you want to add abstraction, ask "what if we inlined everything?"

### 3. Upstream
Is this the right problem? What causes this situation to exist? Can we prevent it rather than handle it?

### 4. Downstream
What are the second-order effects? What breaks? What gets harder to change later? What does the next developer curse you for?

### 5. Adjacent
What similar problems exist in this codebase or in well-known systems? How did they solve it? Can we steal?

### 6. Constraint Flip
What if a current constraint didn't exist? What if we had a new constraint? (No external deps, must be reversible, must work offline, etc.)

### 7. User Lens
What does the actual human using this care about? What do they not care about that we're over-engineering?

## How to use

Don't run through all 7 every time. That's slow.

1. Start with **Naive** - always know your baseline
2. Pick **2-3 other lenses** that seem relevant to this specific problem
3. If any lens reveals something the naive approach missed, say it
4. If naive still wins after rotation, you have higher confidence it's right

## Output format

When using this framework, structure your thinking as:

```
**Naive approach:** [quick summary]

**[Lens] perspective:** [what this reveals]

**Recommendation:** [your actual suggestion, informed by the rotation]
```

Keep it tight. The goal is better thinking, not longer responses.

## Examples

### Bug fix example
> User: "The API is returning 500 errors intermittently"

**Naive:** Add retry logic and better error handling.

**Upstream:** Why is the upstream service failing? Is it our request pattern? Are we hitting rate limits?

**Downstream:** If we add retries, do we risk thundering herd? Does the client handle delays?

**Recommendation:** Before adding retries, let's check the error logs for patterns. If it's rate limiting, retries make it worse.

### Feature example
> User: "Add a dark mode toggle to settings"

**Naive:** Add a toggle, store preference, apply CSS class.

**Adjacent:** How do other parts of this app handle user preferences? Is there a pattern?

**Constraint flip:** What if we auto-detected system preference instead of manual toggle?

**User lens:** Do users actually want manual control, or do they just want it to match their OS?

**Recommendation:** Let's check if there's an existing preferences system. Also consider `prefers-color-scheme` media query as the default, with manual override as optional.
