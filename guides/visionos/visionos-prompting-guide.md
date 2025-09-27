# Claude Prompting Guide for visionOS Development

## General Principles

### 1. Start with a Role

Always begin by giving Claude a clear role and context. This sets expectations and behavioral patterns.

<example>
<less_effective>
Help me write unit tests for this ARKit function.
</less_effective>

<more_effective>
You are an expert visionOS test engineer specializing in comprehensive test coverage for spatial computing applications. Help me write unit tests for this ARKit function that cover edge cases, tracking failures, and typical usage patterns.
</more_effective>
</example>

### 2. Be Explicit with Instructions

Claude 4 models respond best to clear, specific instructions rather than implicit expectations.

<example>
<less_effective>
Create a spatial data visualization.
</less_effective>

<more_effective>
Create a comprehensive spatial data visualization with:

- Real-time 3D data rendering using RealityKit
- Interactive gesture controls for manipulation and navigation
- Responsive design for different window sizes and immersion levels
- Export functionality for spatial screenshots
  Include as many relevant spatial features as possible to create a production-ready implementation.
  </more_effective>
  </example>

### 3. Add Context and Motivation

Explain WHY certain behaviors matter - Claude can generalize from explanations.

<example>
<less_effective>
NEVER use force unwrapping in your response.
</less_effective>

<more_effective>
Your response will be deployed in a production visionOS app where crashes are unacceptable, so avoid force unwrapping since it can cause immediate app termination. Use proper optional handling or guard statements instead.
</more_effective>
</example>

### 4. Use Positive Framing

Tell Claude what TO do rather than what NOT to do.

<example>
<less_effective>
Don't use deprecated ARKit APIs.
</less_effective>

<more_effective>
Use the latest ARKit APIs available in visionOS 2.0 and ensure compatibility with current spatial tracking capabilities.
</more_effective>
</example>

### 5. Provide Aligned Examples

Examples powerfully shape behavior - ensure they demonstrate exactly what you want. Wrap your examples with xml example tags.

## Advanced Techniques

### Use XML Tags for Structure

XML tags provide clear boundaries and structure for complex outputs:

<example_prompt>
Analyze this visionOS code and provide your response in the following format:

<code_quality>
Assess the overall Swift code quality, patterns, and spatial computing architecture
</code_quality>

<spatial_review>
When performing spatial computing review, follow these steps:

1. Details...
2. Details...

</spatial_review>

<performance_suggestions>
List specific performance improvements for spatial applications
</performance_suggestions>

<spatial_refactoring_recommendations>
Suggest refactoring opportunities with Swift code examples
</spatial_refactoring_recommendations>
</example_prompt>

You can combine markdown and xml. XML is useful for grouping major sections or large chunks of context together, and markdown is good for emphasis within those sections.

### Chain Complex Tasks

Break multi-step spatial computing processes into clear phases:

<example>
Phase 1: Research and Analysis
- Examine the existing visionOS project structure
- Identify current spatial patterns and conventions
- Document ARKit/RealityKit dependencies and constraints

Phase 2: Design and Planning

- Create spatial architecture design based on findings
- Define protocols and data flow for 3D content
- Plan implementation sequence

Phase 3: Implementation

- Build core spatial functionality first
- Add gesture handling and spatial interactions
- Implement tests alongside spatial components
  </example>

## Long Context Best Practices

Claude's 200K token context window enables handling complex, data-rich visionOS projects. Follow these essential strategies:

### 1. Document Placement Strategy

**Put longform data at the top** - Place documents and large inputs (~20K+ tokens) near the beginning of your prompt, with queries and instructions at the end.

<example>
<less_effective>
Analyze these visionOS project files and identify architectural improvements:
[20,000 tokens of Swift source code]
[15,000 tokens of Reality Composer Pro assets]
</less_effective>

<more_effective>
[20,000 tokens of Swift source code]
[15,000 tokens of Reality Composer Pro assets]

Analyze the visionOS project files above. Identify architectural patterns and recommend improvements for spatial computing best practices.
</more_effective>
</example>

Placing queries at the end can improve response quality by up to 30%, especially with complex multi-file inputs.

### 2. Structure with XML Tags

Organize multiple visionOS project files with clear metadata and boundaries:

<example>

<documents>
  <document>
    <source>Sources/Views/SpatialView.swift</source>
    <document_content>
      {{SWIFTUI_SPATIAL_CODE}}
    </document_content>
  </document>
  <document>
    <source>Sources/Managers/ARSessionManager.swift</source>
    <document_content>
      {{ARKIT_MANAGER_CODE}}
    </document_content>
  </document>
  <document>
    <source>Sources/Models/SpatialAnchor.swift</source>
    <document_content>
      {{CORE_DATA_MODEL_CODE}}
    </document_content>
  </document>
</documents>

Based on the visionOS project files above, provide a comprehensive spatial architecture analysis with specific recommendations.
</example>

### 3. Ground Responses in Quotes

For accuracy in long visionOS project tasks, request relevant quotes before analysis:

<example>
You are analyzing visionOS project architecture to assist with spatial computing optimization.

<documents>
  <document index="1">
    <source>Sources/Views/ImmersiveView.swift</source>
    <document_content>
      {{IMMERSIVE_VIEW_CODE}}
    </document_content>
  </document>
  <document index="2">
    <source>Sources/Services/SpatialDataService.swift</source>
    <document_content>
      {{SPATIAL_DATA_SERVICE_CODE}}
    </document_content>
  </document>
  <document index="3">
    <source>Reality Composer Pro/SpatialScene.rcproject</source>
    <document_content>
      {{REALITY_COMPOSER_DATA}}
    </document_content>
  </document>
</documents>

Instructions:

1. First, extract relevant code quotes from the documents that relate to spatial data handling. Place these in <relevant_quotes> tags.
2. Based on these quotes, provide your spatial architecture assessment in <architecture_analysis> tags.
3. List recommended improvements in <recommendations> tags.
   </example>

### 4. Long Context Tips Summary

<long_context_checklist>
✅ **Document Order**

- Large Swift files at the top
- Instructions and queries at the end
- Examples after documents but before final query

✅ **Organization**

- Use XML tags for document boundaries
- Include metadata (source, date, type)
- Number or index multiple Swift files

✅ **Accuracy Techniques**

- Request code quote extraction first
- Ask for citations with responses
- Use step-by-step processing for complex spatial analysis

✅ **Performance Optimization**

- Combine related Swift files when possible
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
You have access to file manipulation and search tools for visionOS development. When working with multiple Swift files:

- Execute independent operations in parallel for efficiency
- Prefer batch operations over sequential processing
- Verify Xcode build success before finalizing
- Clean up temporary artifacts when complete
  </more_effective>
  </example>

### Structuring Tool Workflows

<example>
When defining multi-step spatial computing processes that involve tools:

<workflow>
  1. Use search and analysis tools to understand the visionOS project structure
  2. Create a structured implementation plan based on findings
  3. Implement the solution using appropriate Swift development tools
  4. Validate results with Xcode build and clean up any temporary artifacts
</workflow>

</example>

### Enhance Output Quality

For comprehensive visionOS implementations:

Don't hold back. Give it your all. Include as many relevant spatial computing features and interactions as possible.

For robust spatial solutions:

Please write a high quality, production-ready visionOS solution. Implement spatial functionality that works correctly for all valid inputs and spatial contexts. Focus on understanding the spatial computing requirements and implementing the correct SwiftUI/RealityKit patterns.

## Specialized Use Cases

### visionOS UI Generation

Encourage detailed, interactive spatial designs:

Don't hold back. Give it your all.

Additional modifiers:

- "Include as many relevant spatial features and interactions as possible"
- "Add thoughtful details like depth transitions, spatial audio feedback, and immersive interactions"
- "Create an impressive demonstration showcasing visionOS development capabilities"
- "Apply spatial design principles: hierarchy, depth, presence, and natural interaction"

### General Solution Development

Prevent test-focused hard-coding:

Please write a high quality, production-ready visionOS solution. Implement spatial functionality that works correctly for all valid inputs and spatial contexts, not just the test cases. Do not hard-code values or create solutions that only work for specific test scenarios. Instead, implement the actual spatial logic that solves the problem generally.

Focus on understanding the visionOS requirements and implementing the correct SwiftUI/RealityKit patterns. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows Apple's spatial computing guidelines and Swift best practices.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me. The solution should be robust, maintainable, and extendable for spatial computing applications.

## Output Enhancement Techniques

### Quality Modifiers

Add encouraging language to boost output quality:

- **Basic:** "Create a spatial data dashboard"
- **Enhanced:** "Create a spatial data dashboard. Include as many relevant visionOS features and interactions as possible. Go beyond the basics to create a fully-featured spatial computing implementation."

### Explicit Feature Requests

- Request spatial animations and interactions explicitly when desired
- Specify exact spatial behaviors rather than assuming Claude will infer them
- Describe expected output formats in detail
- Include spatial quality expectations in instructions

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

- **Start with a role** - Define Claude's expertise and visionOS perspective
- **Provide explicit instructions** - Be specific about desired spatial outputs
- **Use positive framing** - Tell what TO do, not what NOT to do
- **Add context and motivation** - Explain why spatial behaviors matter
- **Include aligned examples** - Show exactly what you want
- **Leverage XML tags** - Structure complex outputs clearly
- **Request parallel execution** - Maximize efficiency with concurrent operations
- **Match prompt style** - Align formatting with desired output
- **Chain complex tasks** - Break down into clear phases
- **Use thinking capabilities** - For complex spatial reasoning and planning
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

1. **Role Definition** - Clear identity and visionOS expertise
2. **Explicit Instructions** - Specific, actionable spatial directives
3. **Contextual Reasoning** - Why spatial behaviors matter
4. **Example Alignment** - Demonstrations match expectations
5. **Structural Clarity** - XML tags and organized format
6. **Iterative Refinement** - Test and improve prompts
7. **Tool Optimization** - Strategic parallel execution
8. **Quality Modifiers** - "Give it your all" for enhanced spatial output

</success_factors>
