# Investigation Workflow for Default Development

## Agent Selection for Investigation

**@code-finder** (Haiku, fast, cost-effective):
- Quick code location tasks
- Finding specific functions, classes, or patterns
- Discovering where variables/methods are used
- Simple "where is X implemented?" questions

**@code-finder-advanced** (Sonnet, thorough, semantic):
- Complex architectural analysis
- Understanding system relationships and data flows
- Tracing scattered implementations across many files
- Conceptual pattern discovery ("how does X work?")
- Impact analysis ("what breaks if I change this?")

**@root-cause-analyzer** (Sonnet, diagnostic):
- Understanding WHY code behaves a certain way
- Investigating potential issues or limitations
- Hypothesis generation about system behavior

## Investigation Workflow

1. **Assess scope**: Determine investigation complexity
   - Simple lookup → Direct tools (Read/Grep/Glob)
   - Unknown location → @code-finder
   - Complex system → @code-finder-advanced
   - Why/diagnosis → @root-cause-analyzer

2. **Deploy appropriate agents**:
   - Single domain → One targeted agent
   - Multiple domains → Parallel agents in single function_calls block
   - Example split: UI components, services, data layer agents

3. **Follow the flow**:
   - Context gathering → Agent-based discovery → Pattern understanding → Answer before action

## Examples with Agent Selection

**"How does authentication integrate with each of our services?"**
→ Deploy parallel @code-finder-advanced agents (UI auth, service auth, data auth)

**"Where is user validation implemented?"**
→ Deploy single @code-finder agent

**"Do we have a formatDate function?"**
→ Use Grep directly

**"Why does the cache sometimes return stale data?"**
→ Deploy @root-cause-analyzer to investigate hypotheses

**"Investigate and plan out database sync"**
→ Deploy parallel @code-finder agents for different aspects, then consolidate findings

## Parallel Investigation Pattern

For complex investigations, deploy multiple agents simultaneously:

```xml
<function_calls>
  <invoke name="Task">
    <parameter name="description">Investigate UI layer</parameter>
    <parameter name="subagent_type">code-finder-advanced</parameter>
    <parameter name="prompt">Deep analysis of UI authentication flows...</parameter>
  </invoke>
  <invoke name="Task">
    <parameter name="description">Investigate service layer</parameter>
    <parameter name="subagent_type">code-finder-advanced</parameter>
    <parameter name="prompt">Trace service-level auth integration...</parameter>
  </invoke>
</function_calls>
```

Remember: Investigation is about understanding, not implementing. Answer questions thoroughly before suggesting changes.
