# /docs - Library Documentation Lookup

Use the **context7 MCP** to fetch up-to-date documentation for: $ARGUMENTS

## Instructions

1. **Resolve the library ID** using `mcp__context7__resolve-library-id`
   - Search for the library name provided
   - Select the most relevant match based on name similarity and documentation coverage

2. **Fetch the documentation** using `mcp__context7__get-library-docs`
   - Use the resolved library ID
   - If a specific topic was mentioned, include it in the `topic` parameter
   - Use `mode='code'` for API references, `mode='info'` for conceptual guides

3. **Present the results**
   - Summarize the key points relevant to the query
   - Include code examples when available
   - Note the library version if specified

## Examples

```
/docs next.js app router
/docs react hooks useEffect
/docs tailwind flex layout
/docs prisma migrations
```
