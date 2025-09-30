# Claude Prompting Guide for Web Development

## General Principles

### 1. Start with a Role

Always begin by giving Claude a clear role and context. This sets expectations and behavioral patterns.

<example>
<less_effective>
Help me write unit tests for this function.
</less_effective>

<more_effective>
You are an expert test engineer specializing in comprehensive test coverage. Help me write unit tests for this function that cover edge cases, error conditions, and typical usage patterns.
</more_effective>
</example>

### 2. Be Explicit with Instructions

Claude 4 models respond best to clear, specific instructions rather than implicit expectations.

<example>
<less_effective>
Create a data visualization.
</less_effective>

<more_effective>
Create a comprehensive data visualization with:

- Real-time data rendering with interactive charts
- Interactive controls for filtering and navigation
- Responsive design for different screen sizes
- Export functionality for reports
  Include as many relevant features as possible to create a production-ready implementation.
  </more_effective>
  </example>

### 3. Add Context and Motivation

Explain WHY certain behaviors matter - Claude can generalize from explanations.

<example>
<less_effective>
NEVER use unsafe operations in your response.
</less_effective>

<more_effective>
Your response will be deployed in a production app where stability is critical, so avoid unsafe operations that could cause crashes. Use proper error handling and validation instead.
</more_effective>
</example>

### 4. Use Positive Framing

Tell Claude what TO do rather than what NOT to do.

<example>
<less_effective>
Don't use deprecated APIs.
</less_effective>

<more_effective>
Use the latest stable APIs and ensure compatibility with current best practices.
</more_effective>
</example>

### 5. Provide Aligned Examples

Examples powerfully shape behavior - ensure they demonstrate exactly what you want. Wrap your examples with xml example tags.

## Advanced Techniques

### Use XML Tags for Structure

XML tags provide clear boundaries and structure for complex outputs:

<example_prompt>
Analyze this code and provide your response in the following format:

<code_quality>
Assess the overall code quality, patterns, and architecture
</code_quality>

<review>
When performing review, follow these steps:

1. Details...
2. Details...

</review>

<performance_suggestions>
List specific performance improvements
</performance_suggestions>

<refactoring_recommendations>
Suggest refactoring opportunities with code examples
</refactoring_recommendations>
</example_prompt>

You can combine markdown and xml. XML is useful for grouping major sections or large chunks of context together, and markdown is good for emphasis within those sections.

### Chain Complex Tasks

Break multi-step processes into clear phases:

<example>
Phase 1: Research and Analysis
- Examine the existing project structure
- Identify current patterns and conventions
- Document dependencies and constraints

Phase 2: Design and Planning

- Create architecture design based on findings
- Define interfaces and data flow
- Plan implementation sequence

Phase 3: Implementation

- Build core functionality first
- Add features and interactions
- Implement tests alongside components
  </example>

## Long Context Best Practices

Claude's 200K token context window enables handling complex, data-rich projects. Follow these essential strategies:

### 1. Document Placement Strategy

**Put longform data at the top** - Place documents and large inputs (~20K+ tokens) near the beginning of your prompt, with queries and instructions at the end.

<example>
<less_effective>
Analyze these project files and identify architectural improvements:
[20,000 tokens of source code]
[15,000 tokens of documentation]
</less_effective>

<more_effective>
[20,000 tokens of source code]
[15,000 tokens of documentation]

Analyze the project files above. Identify architectural patterns and recommend improvements for best practices.
</more_effective>
</example>

Placing queries at the end can improve response quality by up to 30%, especially with complex multi-file inputs.

### 2. Structure with XML Tags

Organize multiple project files with clear metadata and boundaries:

<example>

<documents>
  <document>
    <source>src/components/DataView.jsx</source>
    <document_content>
      {{COMPONENT_CODE}}
    </document_content>
  </document>
  <document>
    <source>src/services/DataService.js</source>
    <document_content>
      {{SERVICE_CODE}}
    </document_content>
  </document>
  <document>
    <source>src/models/DataModel.js</source>
    <document_content>
      {{MODEL_CODE}}
    </document_content>
  </document>
</documents>

Based on the project files above, provide a comprehensive architecture analysis with specific recommendations.
</example>

### 3. Ground Responses in Quotes

For accuracy in long project tasks, request relevant quotes before analysis:

<example>
You are analyzing project architecture to assist with optimization.

<documents>
  <document index="1">
    <source>src/views/MainView.jsx</source>
    <document_content>
      {{VIEW_CODE}}
    </document_content>
  </document>
  <document index="2">
    <source>src/services/ApiService.js</source>
    <document_content>
      {{API_SERVICE_CODE}}
    </document_content>
  </document>
  <document index="3">
    <source>config/database.json</source>
    <document_content>
      {{DATABASE_CONFIG}}
    </document_content>
  </document>
</documents>

Instructions:

1. First, extract relevant code quotes from the documents that relate to data handling. Place these in <relevant_quotes> tags.
2. Based on these quotes, provide your architecture assessment in <architecture_analysis> tags.
3. List recommended improvements in <recommendations> tags.
   </example>

### 4. Long Context Tips Summary

<long_context_checklist>
✅ **Document Order**

- Large files at the top
- Instructions and queries at the end
- Examples after documents but before final query

✅ **Organization**

- Use XML tags for document boundaries
- Include metadata (source, date, type)
- Number or index multiple files

✅ **Accuracy Techniques**

- Request code quote extraction first
- Ask for citations with responses
- Use step-by-step processing for complex analysis

✅ **Performance Optimization**

- Combine related files when possible
- Remove irrelevant sections if known
- Use clear section markers within documents

</long_context_checklist>

## Tool Usage in Prompts

### Explaining Tool Capabilities

When Claude has access to tools, provide clear guidance on when and how to use them:

- **Define tool purposes** - Explain what each tool category is for
- **Specify preferences** - Indicate which tools to prefer in different situations
- **Encourage parallelization** - Request simultaneous execution when possible
- **Set boundaries** - Clarify which tools require approval vs automatic use

### Example Tool Instructions

<example>
<less_effective>
You have access to various tools. Use them as needed.
</less_effective>

<more_effective>
You have access to file manipulation and search tools for development. When working with multiple files:

- Execute independent operations in parallel for efficiency
- Prefer batch operations over sequential processing
- Verify build success before finalizing
- Clean up temporary artifacts when complete
  </more_effective>
  </example>

### Structuring Tool Workflows

<example>
When defining multi-step processes that involve tools:

<workflow>
  1. Use search and analysis tools to understand the project structure
  2. Create a structured implementation plan based on findings
  3. Implement the solution using appropriate development tools
  4. Validate results with tests and clean up any temporary artifacts
</workflow>

</example>

### Enhance Output Quality

For comprehensive implementations:

Don't hold back. Give it your all. Include as many relevant features and functionality as possible.

For robust solutions:

Please write a high quality, production-ready solution. Implement functionality that works correctly for all valid inputs and contexts. Focus on understanding the requirements and implementing the correct patterns.

## Specialized Use Cases

### UI Generation

Encourage detailed, interactive designs:

Don't hold back. Give it your all.

Additional modifiers:

- "Include as many relevant features and interactions as possible"
- "Add thoughtful details like animations, feedback, and interactive elements"
- "Create an impressive demonstration showcasing development capabilities"
- "Apply design principles: hierarchy, consistency, feedback, and usability"

### General Solution Development

Prevent test-focused hard-coding:

Please write a high quality, production-ready solution. Implement functionality that works correctly for all valid inputs and contexts, not just the test cases. Do not hard-code values or create solutions that only work for specific test scenarios. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the requirements and implementing the correct patterns. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me. The solution should be robust, maintainable, and extendable.

## Output Enhancement Techniques

### Quality Modifiers

Add encouraging language to boost output quality:

- **Basic:** "Create a data dashboard"
- **Enhanced:** "Create a data dashboard. Include as many relevant features and visualizations as possible. Go beyond the basics to create a fully-featured implementation."

### Explicit Feature Requests

- Request animations and interactions explicitly when desired
- Specify exact behaviors rather than assuming Claude will infer them
- Describe expected output formats in detail
- Include quality expectations in instructions

## System Prompt Best Practices

An effective system prompt should:

1. **Start with a clear role**
2. **Use XML tags for organization**
3. **Include specific dos and don'ts**
4. **Provide examples where helpful**
5. **Set clear behavioral expectations**

## Best Practices Summary

### ✅ Do

<best_practices>

- **Start with a role** - Define Claude's expertise and perspective
- **Provide explicit instructions** - Be specific about desired outputs
- **Use positive framing** - Tell what TO do, not what NOT to do
- **Add context and motivation** - Explain why behaviors matter
- **Include aligned examples** - Show exactly what you want
- **Leverage XML tags** - Structure complex outputs clearly
- **Request parallel execution** - Maximize efficiency with concurrent operations
- **Match prompt style** - Align formatting with desired output
- **Chain complex tasks** - Break down into clear phases
- **Use thinking capabilities** - For complex reasoning and planning
  </best_practices>

### ❌ Avoid

<common_mistakes>

- **Negative instructions** - "Don't do X" is less effective than "Do Y"
- **Vague requirements** - Implicit expectations lead to varied results
- **Misaligned examples** - Examples that contradict instructions
- **Sequential operations** - When parallel execution is possible
- **Test-focused coding** - Hard-coding for specific test cases
- **Assuming capabilities** - Not checking framework/API availability
- **Missing context** - Instructions without explanation
- **Overly complex prompts** - When simple, direct prompts work better

 </common_mistakes>

### 🔑 Key Success Factors

<success_factors>

1. **Role Definition** - Clear identity and expertise
2. **Explicit Instructions** - Specific, actionable directives
3. **Contextual Reasoning** - Why behaviors matter
4. **Example Alignment** - Demonstrations match expectations
5. **Structural Clarity** - XML tags and organized format
6. **Iterative Refinement** - Test and improve prompts
7. **Tool Optimization** - Strategic parallel execution
8. **Quality Modifiers** - "Give it your all" for enhanced output

</success_factors>