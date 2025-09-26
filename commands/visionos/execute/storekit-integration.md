Complete StoreKit setup for VisionOS app, enabling in-app purchases, subscriptions, and App Store integration following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-storekit-developer`

**Overview:**
You are implementing complete StoreKit integration for a VisionOS application, including product configuration, purchase flows, receipt validation, and subscription management. VisionOS uses the same StoreKit 2 APIs as iOS, but requires consideration for spatial UI and mixed reality context.

**VisionOS StoreKit Considerations:**

1. **Spatial Purchase UI:**
   - Design purchase flows that work in 3D space
   - Consider user comfort during purchase interactions
   - Implement clear spatial affordances for purchase buttons
   - Handle purchase dialogs in mixed reality context

2. **StoreKit 2 Integration:**
   - Use modern async/await StoreKit 2 APIs
   - Implement proper product loading and caching
   - Handle purchase states and transaction updates
   - Support subscription status monitoring

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required products and subscription tiers
   - Purchase flow requirements
   - Integration points with existing user management
   - Analytics and tracking needs

2. **Study existing patterns** in the codebase:
   - Look for existing StoreKit implementations
   - Check for user authentication patterns
   - Identify analytics integration points
   - Review error handling and logging patterns

3. **StoreKit Configuration:**
   - Set up StoreKit configuration files (.storekit)
   - Configure product identifiers and metadata
   - Set up subscription groups and tiers
   - Implement sandbox testing configuration

4. **Core StoreKit Implementation:**
   - Create `Store` class using StoreKit 2
   - Implement product loading and caching
   - Handle purchase transactions and validation
   - Implement subscription status monitoring
   - Add purchase restoration functionality

5. **VisionOS-Specific Purchase UI:**
   - Create spatial purchase views and modifiers
   - Implement comfortable purchase confirmation flows
   - Add proper loading and success states for spatial context
   - Handle purchase interruptions gracefully

6. **Security & Validation:**
   - Implement server-side receipt validation (if applicable)
   - Handle transaction security properly
   - Implement fraud prevention measures
   - Store purchase data securely

7. **Error Handling:**
   - Handle network errors and StoreKit failures
   - Implement user-friendly error messages
   - Add retry mechanisms for failed purchases
   - Log errors for debugging and analytics

8. **Analytics Integration:**
   - Track purchase events and conversion funnels
   - Monitor subscription lifecycle events
   - Implement revenue tracking
   - Add custom purchase analytics

**Key Files to Create/Modify:**
- `Store.swift` - Main StoreKit manager
- `Product+Extensions.swift` - Product helper methods
- `PurchaseView.swift` - Spatial purchase UI components
- `SubscriptionManager.swift` - Subscription status handling
- `[AppName].storekit` - StoreKit configuration file
- Integration with existing user management and analytics

**Testing Requirements:**
- Test with StoreKit sandbox environment
- Verify all purchase flows work in VisionOS Simulator
- Test subscription status changes
- Validate receipt handling and restoration
- Test error scenarios and edge cases

**Deliverables:**
- Complete StoreKit 2 integration
- VisionOS-optimized purchase UI
- Subscription management system
- Analytics integration for purchase events
- Comprehensive error handling

Before completing, run a build check to ensure no compilation errors in the files you modified.