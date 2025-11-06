I want to define a new Stream Deck plugin feature, eventually resulting in a `.docs/plans/[feature-name]/requirements.md` file. This requirements document should follow the template in `$CLAUDE_HOME/file-templates/requirements.template.md`. Your job is to help me clarify what needs to be built from a user perspective.

Please provide a high-level description of the feature you want to implement:

(Once you provide the feature description, I'll investigate the codebase and ask clarifying questions to help define the requirements.)

## Process

### 1. Initial Research
Start by familiarizing yourself with the feature. Use 1-3 agents (more for complex features) _in parallel_ to investigate the codebase and gather the context you need to understand the current state.

This research should identify:
- Existing similar Actions, Property Inspectors, or event handlers
- Relevant plugin files and manifest structure
- Current implementation approaches (SDK patterns, event handling)

### 2. Ask Clarifying Questions
Focus on understanding WHAT needs to be built, not HOW to build it (technical details come in `/2-architecture`).

**Focus areas:**
- **User experience**: What the user sees on Stream Deck buttons, interacts with in Property Inspector, and expects
- **Functional requirements**: What capabilities the plugin must provide
- **Scope boundaries**: What's included vs excluded from this feature

**Important rules:**
- Ask about what the user mentioned, not speculative features
- If the user didn't mention error handling, edge cases, or advanced features, DON'T ask about them
- Keep questions focused on the core feature described
- Don't over-plan - this is a medium-scope feature, not enterprise software
- Be efficient - 3-5 clarifying questions maximum

**Don't ask about:**
- Technical implementation details (save for `/2-architecture`)
- Error handling unless the user specifically mentioned it
- Edge cases unless critical to understanding scope
- "What about X?" speculative additions

### 3. Checkpoint Before Writing
Once you have enough information, summarize your understanding:

"Here's what I understand about this Stream Deck plugin feature:
- [Summary of user flow]
- [Key functional requirements]
- [Scope boundaries]

Is this complete, or is there anything important I'm missing?"

Wait for user confirmation before proceeding.

### 4. Write Requirements Document
Create `.docs/plans/[feature-name]/requirements.md` using the template at `$CLAUDE_HOME/file-templates/requirements.template.md`.

The document should be:
- **Non-technical**: Focus on what, not how
- **User-focused**: Describe from the Stream Deck user's perspective
- **Actionable**: Clear enough for a developer to understand what to build
- **Complete**: Include all relevant plugin files at the bottom for context

### 5. Final Check
After writing, present the requirements document and ask:
"Does this accurately capture what you want to build?"

Allow the user to request revisions before considering it complete.

Important notes:
- Backwards compatibility is not a concern - breaking changes are okay
- Don't assume things the user hasn't told you - ask instead
- If uncertain, it's better to ask one clarifying question than guess wrong
- If you need more context, pause to use @code-finder or @code-finder-advanced agents

Upon completion, inform the user:
"Requirements complete. Run `/2-architecture` next to define the technical approach."
