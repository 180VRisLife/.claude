# Creation Templates

Copy-pastable prompts for extending the system with new features or domains.

## New Feature Prompt

Use this to add a specialist agent for a new feature type within an existing domain.

```
Add a new feature for [FEATURE_NAME] within the [DOMAIN_NAME] domain that [FEATURE_DESCRIPTION e.g., "enables users to export their data in multiple formats"].

CRITICAL STRUCTURE REQUIREMENT:
- BEFORE creating ANY file, you MUST first Read the corresponding default example from library/default/agents/specialist/
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/base parts with the new specialist-specific content
- Keep ALL formatting, sections, subsections, and organizational patterns identical

Steps:
1. Create specialist agent in library: ~/.claude/library/[domain]/agents/specialist/[specialist-name].md
2. Research the specified feature's best practices for the domain's development thoroughly on the internet
3. For the specialist file you create:
   a. FIRST read a corresponding default specialist agent from library/default/agents/specialist/ as your exact template
   b. Maintain the EXACT same structure, headers, and organization
   c. Replace ONLY the default-specific technical content with specialist-specific content
   d. Keep the same level of detail and documentation style
4. Build comprehensive documentation that covers all aspects of implementing the specified feature while maintaining consistency with existing domain patterns
5. Review guide files to determine if this specialist agent should be mentioned:
   a. Read library/[domain]/guides/implementation.md - Consider adding to "Feature Development" section if this is a common feature type
   b. Read library/[domain]/guides/parallel.md - Consider adding to examples if this agent is commonly used in parallel
   c. Read library/[domain]/guides/always-active/foundation.md - Consider adding to "Domain specialists" if this is a primary specialist
   d. Note: Only update guide files if the agent represents a significant, frequently-used feature type. Most specialists don't require guide updates.

File structure:
- Specialist agents: agents/specialist/[specialist-name].md (e.g., agents/specialist/backend-feature.md, agents/specialist/shareplay-feature.md)

Start by researching best practices for the specified feature in the given domain, then create the feature documentation by reading a default feature template immediately before creating the domain-specific version.
```

## New Domain Prompt

Use this to create an entirely new development domain (e.g., a new platform or framework).

```
Create a new development domain for [DOMAIN_NAME] in Claude's Library that [DOMAIN_DESCRIPTION e.g., "supports building scalable web applications with React"].

CRITICAL INSTRUCTIONS:
- Do NOT create any files unless explicitly listed below (no README, no extra documentation)
- BEFORE creating ANY file or folder, you MUST first Read the corresponding default example from library/default/
- The structure must be EXACTLY the same as the default version
- ONLY replace the specific default/core parts with the new domain equivalents
- Be EXTREMELY skeptical about making changes - when in doubt, keep it identical to default

Steps:
1. Create a new domain folder in library: ~/.claude/library/[domain]/
2. Create subfolders: agents, claude-md-includes, commands, file-templates, guides, hooks
3. For EACH file you create:
   a. FIRST read the corresponding library/default/ file to use as your EXACT template
   b. Analyze what needs changing:
      - File Templates: Need MINIMAL changes (often just domain name references)
      - Agents/Features: Need MAJOR content changes BUT exact same structure
      - Commands/Hooks: Need moderate changes, keep the same logic flow
   c. Maintain EXACTLY the same:
      - File and folder naming patterns
      - Section headers and organization
      - Documentation depth and style
      - Code structure and patterns
   d. Replace ONLY the default-specific technical content
4. Research the specified domain's development best practices thoroughly on the internet
5. Create a settings.local.template.json matching the structure in library/default/settings.local.template.json
6. Preserve flat folder structure (all files directly in their respective top-level folders)
7. Update ~/.claude/scripts/init-workspace.py to add detection logic for the new domain:
   a. Read the script to understand the detection pattern
   b. Add domain indicators (strong and medium) following the existing pattern
   c. Add detection logic in the correct priority order
   d. Ensure package.json/config file checks are domain-specific

Agent Requirements:
- Create ALL 5 base agents (code-finder, code-finder-advanced, implementor, library-docs-writer, root-cause-analyzer)
- Create EXACTLY 3 specialist agents that represent the most important/common features for this domain
- Specialist agents should cover distinct aspects of the domain (e.g., frontend/backend/fullstack or different framework capabilities)

File structure conventions:
- agents/base/: code-finder.md, code-finder-advanced.md, implementor.md, library-docs-writer.md, root-cause-analyzer.md
- agents/specialist/: [name1].md, [name2].md, [name3].md
- commands/: 1-requirements.md, 2-architecture.md, 3-priority.md, 4-parallelization.md, 5-execution.md, brainstorm.md, debug.md, deep-research.md, implement.md, investigate.md, plan.md
- hooks/: workflow-orchestrator.py, parallel.py
- file-templates/: requirements.template.md, architecture.template.md, priority.template.md, parallelization.template.md, feature-doc.template.md
- guides/: always-active/foundation.md, planning.md, brainstorming.md, deep-research.md, debug.md, investigation.md, implementation.md, parallel.md

Start by researching best practices for the specified domain's development, then systematically create each folder by:
1. Reading the library/default/ equivalent
2. Creating the exact same structure in library/[domain]/
3. For each file: Read default version → Create domain version with identical structure
4. Update init-workspace.py with detection logic

VALIDATION: After each file creation, verify that someone could do a side-by-side comparison with the library/default/ version and see the EXACT same structure with only domain-specific terms changed.
```

**After creating the domain:** Test it by running `/0-workspace` in a project of that type.
