Implement comprehensive cache system for VisionOS app, including 3D asset caching, spatial data management, and memory-efficient content storage following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-caching-developer`

**Overview:**
You are implementing a sophisticated caching system optimized for VisionOS applications, handling both traditional app data and spatial computing specific content like 3D models, textures, spatial anchors, and immersive media while respecting VisionOS memory constraints.

**VisionOS Caching Considerations:**

1. **3D Asset Management:**
   - Cache USDZ models, textures, and materials efficiently
   - Implement progressive loading for large 3D assets
   - Manage Reality Composer scenes and entities
   - Handle spatial audio files and immersive content

2. **Memory Constraints:**
   - VisionOS has strict memory limitations compared to iOS
   - Implement aggressive cache eviction policies
   - Use memory-mapped files for large assets
   - Monitor thermal state and adjust caching behavior

3. **Spatial Data Caching:**
   - Cache spatial anchor data and world tracking information
   - Store user's spatial preferences and positioning
   - Handle SharePlay session data caching
   - Manage mixed reality object placement data

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required cache types and content
   - Performance and memory requirements
   - Integration with existing data management
   - Analytics and monitoring needs

2. **Study existing patterns** in the codebase:
   - Look for existing caching implementations
   - Check for data model and persistence patterns
   - Review memory management and optimization approaches
   - Identify performance-critical data flows

3. **Core Cache Architecture:**
   - Create `CacheManager` singleton with multiple cache layers
   - Implement memory cache for frequently accessed data
   - Set up disk cache for persistent storage
   - Add network cache for API responses and media

4. **VisionOS-Optimized Caching:**
   - Implement 3D asset cache with format-specific handling
   - Create spatial data cache for anchors and positioning
   - Add immersive media cache for videos and spatial audio
   - Implement progressive loading for large assets

5. **Cache Policies & Eviction:**
   - Implement LRU (Least Recently Used) eviction
   - Add size-based cache limits with thermal awareness
   - Create time-based expiration for network data
   - Implement priority-based caching for critical assets

6. **Memory Management:**
   - Monitor memory usage and pressure
   - Implement automatic cache clearing on memory warnings
   - Use weak references and proper cleanup
   - Add memory profiling and debugging tools

7. **Performance Optimization:**
   - Implement async/await for cache operations
   - Add background queue processing
   - Use concurrent access with proper synchronization
   - Implement cache preloading strategies

8. **Persistence & Storage:**
   - Use Core Data or SQLite for cache metadata
   - Implement file system organization
   - Add cache integrity checking
   - Handle app updates and cache migration

**Key Files to Create/Modify:**
- `CacheManager.swift` - Main cache coordinator
- `AssetCache.swift` - 3D asset specific caching
- `SpatialCache.swift` - Spatial data caching
- `MemoryCache.swift` - In-memory cache implementation
- `DiskCache.swift` - Persistent disk cache
- `CachePolicy.swift` - Eviction and retention policies
- Integration with existing data models and network layers

**Cache Types to Implement:**
- **3D Assets:** USDZ models, textures, materials, Reality Composer scenes
- **Spatial Data:** Anchors, world tracking, user positioning, spatial preferences
- **Media Content:** Images, videos, spatial audio, immersive content
- **API Responses:** Network data, user content, configuration data
- **User Data:** Preferences, settings, authentication tokens

**VisionOS-Specific Features:**
- Thermal-aware cache management
- Progressive 3D asset loading
- Spatial anchor persistence
- SharePlay data synchronization
- Mixed reality object caching
- Immersive experience data

**Testing Requirements:**
- Test cache performance under memory pressure
- Verify 3D asset loading and caching
- Test cache eviction policies
- Validate data persistence across app launches
- Test concurrent access and thread safety

**Performance Metrics:**
- Cache hit/miss ratios
- Memory usage monitoring
- Asset loading times
- Thermal impact assessment
- Storage efficiency metrics

**Deliverables:**
- Multi-layered cache architecture
- VisionOS-optimized asset caching
- Memory-efficient cache policies
- Comprehensive cache monitoring
- Integration with existing app architecture

Before completing, run a build check to ensure no compilation errors in the files you modified.