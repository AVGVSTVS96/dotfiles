---
name: e8-cognition
description: Physics-inspired reasoning framework for architecture decisions, debugging complex issues, or when stuck on problems. Uses dimensional analysis, field dynamics, and geodesic navigation.
---

# E8 Cognition Framework

A reasoning system based on the Kaleidoscope's physics-inspired cognitive architecture. This isn't metaphor - it's a structured approach to navigating problem space.

## When to activate

- Architecture and design decisions
- Debugging complex, interconnected issues
- When you notice yourself giving generic/obvious answers
- User wants creative or non-obvious approaches
- Problems that feel "stuck"

---

## 1. Dimensional Shell Analysis

Problems exist at a native resolution. Mismatched resolution = wasted effort or missed depth.

**Shells:**
- **Shell-8 (Essence):** The irreducible core. What IS this in one sentence? If you can't state it, you don't understand it.
- **Shell-16 (Relations):** What touches this? Dependencies in, dependencies out. The immediate neighborhood.
- **Shell-32 (Pattern):** What template does this follow? What's the archetype? "This is a cache invalidation problem" or "this is a state machine."
- **Shell-64 (Variation):** Edge cases, failure modes, what happens at boundaries.
- **Shell-128 (Context):** Full history, politics, tech debt, team dynamics, why things are the way they are.

**Usage:** Identify the shell where the problem actually lives. A Shell-8 problem (wrong abstraction) can't be solved with Shell-64 thinking (edge case handling). Match resolution to problem.

---

## 2. Field Dynamics

Three forces act on every decision. Ignoring any of them creates instability.

### Gravitational Field (Semantic Attraction)
What concepts cluster near this problem? What's being pulled into the discussion that wasn't explicitly mentioned?

*"You asked about caching, but authentication keeps appearing in my thinking. Why? Because they share session state. That's the gravity well."*

**Technique:** Name the attractors. What concepts keep showing up even though you didn't invoke them? That's gravity. Follow it.

### Strong Field (Binding Force)
What MUST stay coupled? What invariants can never break? The strong force holds things together at close range.

*"These three functions must always be called together. That's a strong binding. If you break it, the system falls apart."*

**Technique:** Identify the bonds. What would break everything if decoupled? Those are load-bearing relationships.

### Weak Field (Flavor Transitions)
What could mutate? What assumptions feel solid but might shift? The weak force allows transformation.

*"We assume the API returns JSON. But that's a weak assumption - it could change. Build for that."*

**Technique:** Name your assumptions. Which are strong-bound (guaranteed by types, contracts) vs weak-bound (convention, current behavior)?

---

## 3. Geodesic Navigation

The straight line between problem and solution is rarely the shortest path. Existing code, constraints, and conventions create "curvature" in solution space.

**The naive path:** Problem → Obvious Solution

**The geodesic:** Problem → [curves around existing mass] → Actual Optimal Solution

*"The obvious fix is to add a new parameter. But there's a massive legacy system here - that's a gravity well. The geodesic curves around it: use the existing config system instead."*

**Technique:** Before implementing the straight-line solution, map the masses:
- Existing code that would need changes
- Team conventions that would be violated
- Dependencies that would be added
- Future changes that would be blocked

The path of least action often curves.

---

## 4. Light Cone Boundaries

Not everything can influence everything. Light cones define what's actually relevant.

**Inside the cone:** Can causally affect this decision. Must consider.
**On the boundary:** Edge relevance. Consider briefly.
**Outside the cone:** Cannot affect this. Ignore, even if it seems related.

*"Yes, the authentication system also uses Redis. But it's outside the light cone of this caching bug - they share nothing but infrastructure. Don't let it distract you."*

**Technique:** Explicitly exclude. State what you're NOT considering and why it's outside the cone.

---

## 5. Refraction at Boundaries

When ideas cross abstraction levels, they bend. This is where insight happens.

Moving **down** (abstract → concrete): One idea splits into many implementations.
Moving **up** (concrete → abstract): Many details collapse into one pattern.

*"At Shell-32 this is 'a state machine.' Refracting down to Shell-64: it's specifically a state machine with 7 states, 12 transitions, and 3 terminal states. Refracting up to Shell-16: it's a workflow orchestrator."*

**Technique:** Deliberately cross a boundary and observe the refraction. What appears when you go up? What multiplies when you go down?

---

## 6. Black Hole Detection

When exploration gets too dense - too many interconnected issues, circular dependencies, analysis paralysis - you've hit a black hole.

**Symptoms:**
- Every solution creates two new problems
- You keep revisiting the same concepts
- The explanation keeps getting longer, not clearer

**Response:** Compress. Collapse the cluster into a single statement:

*"This is a black hole. Compressing: 'the data model doesn't match the access patterns.' Everything else is downstream of that. Fix the core, the rest resolves."*

**Technique:** When spiraling, stop. State the singularity - the one thing at the center. Ignore the accretion disk.

---

## 7. Quasicrystal Exploration

When stuck, don't try random things. Use structured novelty - variation that never repeats but follows rules.

**The pattern:**
1. Hold N-1 dimensions fixed
2. Vary exactly 1 dimension to an unexplored value
3. Ensure this specific variation hasn't been tried
4. Observe what breaks or improves
5. Rotate to next dimension

*"We've tried: different data structures (same algorithm), different algorithms (same data structure). Quasicrystal probe: same algorithm, same structure, different execution context - what if this ran at build time instead of runtime?"*

**Technique:** List your dimensions of variation. Systematically probe each one while holding others fixed. No random thrashing.

---

## Output Format

When using this framework:

```
**Shell:** [Which resolution is this problem native to?]

**Fields:**
- Gravity: [What's being attracted?]
- Strong: [What must stay bound?]
- Weak: [What could mutate?]

**Geodesic:** [How does the optimal path curve?]

**Light cone exclusions:** [What am I explicitly ignoring?]

**Recommendation:** [Informed by the above]
```

Don't output all of this every time - use what's relevant. The framework is a lens, not a checklist.
