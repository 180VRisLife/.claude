# /apple - Apple Developer Documentation Lookup

Use the **apple-docs MCP** to search Apple Developer Documentation for: $ARGUMENTS

## Instructions

1. **Search documentation** using `mcp__apple-docs__search_apple_docs`
   - Search for the API, framework, or topic provided
   - Use type filter if the query is specific (documentation, sample)

2. **Get detailed content** if needed using `mcp__apple-docs__get_apple_doc_content`
   - Fetch full documentation for the most relevant result
   - Include platform analysis for cross-platform queries

3. **Present the results**
   - API reference summary with key methods/properties
   - Platform availability (iOS, macOS, visionOS, etc.)
   - Code examples when available
   - Link to the official documentation

## Additional Tools Available

- `search_framework_symbols` - Browse all symbols in a framework
- `get_sample_code` - Find complete sample projects
- `search_wwdc_content` - Search WWDC video transcripts
- `get_platform_compatibility` - Check API availability across platforms

## Examples

```
/apple SwiftUI NavigationStack
/apple UIKit table view diffable data source
/apple Core Data CloudKit sync
/apple Vision Pro immersive spaces
```
