Perform comprehensive memory profiling and analysis for VisionOS spatial applications, including 3D asset memory usage, spatial rendering overhead, and mixed reality performance optimization following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-performance-analyst`

**Overview:**
You are conducting in-depth memory profiling and performance analysis specifically for VisionOS applications, focusing on spatial computing memory patterns, 3D rendering overhead, multi-volume resource usage, and mixed reality performance characteristics that are unique to spatial computing platforms.

**VisionOS Memory Analysis Considerations:**

1. **Spatial Computing Memory Patterns:**
   - 3D asset memory usage (USDZ models, textures, materials)
   - RealityKit entity and component memory overhead
   - Spatial rendering buffer allocation and management
   - Multi-volume memory distribution and sharing

2. **VisionOS Memory Constraints:**
   - Stricter memory limits compared to iOS devices
   - Thermal throttling impact on memory allocation
   - Shared resource management across multiple volumes
   - Mixed reality context switching overhead

3. **Performance-Critical Areas:**
   - Real-time 3D rendering and spatial tracking
   - SharePlay synchronization and multi-user data
   - Eye tracking and hand tracking processing
   - Immersive experience transitions and state changes

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Specific features and components to analyze
   - Performance requirements and benchmarks
   - Critical user workflows and memory-intensive operations
   - Known performance bottlenecks or concerns

2. **Study existing patterns** in the codebase:
   - Identify memory-intensive components and features
   - Review 3D asset usage and management patterns
   - Analyze spatial rendering and RealityKit usage
   - Examine caching systems and data persistence

3. **Memory Profiling Setup:**
   - Configure Xcode Instruments for VisionOS memory analysis
   - Set up custom memory profiling points and markers
   - Prepare test scenarios for comprehensive analysis
   - Configure automated memory monitoring and alerts

4. **Comprehensive Memory Analysis:**
   - Profile memory usage across different app states and features
   - Analyze 3D asset loading and caching patterns
   - Monitor memory distribution across multiple volumes
   - Track memory leaks and retention cycles

5. **VisionOS-Specific Analysis:**
   - Analyze spatial rendering memory overhead
   - Profile RealityKit entity memory usage
   - Monitor multi-volume resource allocation
   - Track eye tracking and hand tracking memory impact

6. **Performance Bottleneck Identification:**
   - Identify memory hotspots and allocation patterns
   - Analyze garbage collection and memory pressure events
   - Profile memory fragmentation and allocation efficiency
   - Monitor thermal throttling impact on performance

7. **Optimization Recommendations:**
   - Provide specific memory optimization strategies
   - Recommend 3D asset optimization techniques
   - Suggest caching improvements and memory management
   - Identify opportunities for resource sharing and pooling

8. **Continuous Monitoring:**
   - Set up automated memory monitoring and alerting
   - Create memory regression testing framework
   - Implement memory usage dashboards and reporting
   - Establish memory performance benchmarks

**Key Analysis Areas:**

**3D Asset Memory Usage:**
- USDZ model loading and retention patterns
- Texture memory allocation and compression
- Material and shader memory overhead
- Reality Composer scene memory usage

**Spatial Rendering Analysis:**
- RealityKit entity memory consumption
- Spatial tracking data memory usage
- 3D rendering buffer allocation patterns
- Multi-volume rendering overhead

**Feature-Specific Profiling:**
- SharePlay synchronization memory usage
- Authentication and user data memory patterns
- Analytics and logging memory overhead
- Push notification and caching memory impact

**Memory Tools & Commands:**
```bash
# Memory profiling with Instruments
xcrun xctrace record --template "Allocations" --launch -- /path/to/YourApp.app

# Memory leak detection
xcrun leaks --atExit -- /path/to/YourApp.app

# Memory usage monitoring
xcrun xctrace record --template "VM Tracker" --launch -- /path/to/YourApp.app

# Custom memory analysis
instruments -t "Allocations" -D trace_output.trace YourApp.app
```

**Performance Metrics to Track:**
- Peak memory usage across different app states
- Memory allocation and deallocation patterns
- 3D asset memory efficiency ratios
- Multi-volume memory distribution
- Memory pressure event frequency
- Garbage collection impact on frame rates

**Analysis Deliverables:**
- Comprehensive memory usage profile and analysis report
- 3D asset memory optimization recommendations
- VisionOS-specific performance tuning suggestions
- Memory regression testing framework
- Continuous monitoring and alerting setup

**Memory Optimization Strategies:**
- 3D asset Level-of-Detail (LOD) implementation
- Efficient texture compression and streaming
- Smart caching policies for spatial content
- Resource pooling for frequently used components
- Memory-mapped file usage for large assets

**Critical Memory Scenarios:**
- App launch and initialization memory patterns
- Multiple volume creation and management
- Intensive 3D rendering and animation sequences
- SharePlay session memory overhead
- Background processing and cache management

**Reporting & Documentation:**
- Detailed memory analysis reports with visualizations
- Performance regression tracking and alerts
- Memory optimization implementation guides
- Best practices documentation for VisionOS memory management

Before completing, ensure all memory analysis is thorough and actionable recommendations are provided for development team implementation.