Implement user authentication and ID management system for VisionOS app, including spatial user identification, biometric integration, and mixed reality user context following the planning documentation:

$ARGUMENTS

**Agent to use:** `@ios-authentication-developer`

**Overview:**
You are implementing comprehensive user authentication for a VisionOS application, including traditional authentication methods adapted for spatial computing, biometric authentication using VisionOS capabilities, and spatial user identification and management.

**VisionOS Authentication Considerations:**

1. **Spatial User Context:**
   - Handle multiple user scenarios in shared spaces
   - Implement spatial user identification and switching
   - Consider eye tracking for user verification (where privacy-compliant)
   - Manage authentication state across different app modes

2. **VisionOS Biometrics:**
   - Integrate with system-level biometric authentication
   - Handle authentication in immersive vs. windowed modes
   - Implement secure authentication UI for spatial context
   - Consider privacy implications of biometric data

3. **Mixed Reality Privacy:**
   - Handle authentication without exposing credentials in mixed reality
   - Implement secure input methods for passwords
   - Respect user privacy during authentication flows
   - Consider shared device scenarios

**Implementation Requirements:**

1. **Read the planning documents** first to understand:
   - Required authentication methods and flows
   - User management and profile requirements
   - Integration with existing services and APIs
   - Security and privacy requirements

2. **Study existing patterns** in the codebase:
   - Look for existing user management implementations
   - Check for API integration and networking patterns
   - Review data persistence and security patterns
   - Identify analytics and tracking integration points

3. **Authentication Architecture:**
   - Create `AuthenticationManager` singleton
   - Implement multiple authentication providers
   - Set up secure token storage using Keychain
   - Handle authentication state management

4. **Core Authentication Methods:**
   - Implement email/password authentication
   - Add social login options (Sign in with Apple, Google, etc.)
   - Integrate biometric authentication (Face ID, Touch ID equivalent)
   - Support guest/anonymous user modes

5. **VisionOS-Specific Features:**
   - Implement spatial authentication UI components
   - Handle authentication in different immersion levels
   - Add secure text input for spatial context
   - Manage multi-user scenarios and user switching

6. **User Management:**
   - Create user profile management system
   - Implement user preferences and settings
   - Add user data synchronization across devices
   - Handle user deletion and data privacy

7. **Security Implementation:**
   - Use secure token storage with Keychain
   - Implement proper session management
   - Add token refresh and validation
   - Handle authentication errors and edge cases

8. **Integration Points:**
   - Connect with analytics for user identification
   - Integrate with push notifications for user targeting
   - Support StoreKit for purchase attribution
   - Enable CloudKit user identification

**Key Files to Create/Modify:**
- `AuthenticationManager.swift` - Main auth coordinator
- `User.swift` - User model and data management
- `AuthenticationView.swift` - Spatial login UI components
- `BiometricAuthenticator.swift` - Biometric authentication handling
- `TokenManager.swift` - Secure token storage and management
- `UserProfileManager.swift` - User profile and preferences
- Integration with existing app architecture and services

**Authentication Flows:**
- **First Launch:** User registration and onboarding
- **Login:** Email/password, social, and biometric options
- **Guest Mode:** Anonymous user with upgrade options
- **User Switching:** Multi-user support for shared devices
- **Password Reset:** Secure password recovery flow
- **Account Linking:** Connect multiple authentication methods

**VisionOS-Specific UI/UX:**
- Spatial login forms with secure input
- Biometric authentication prompts
- User switching interface for shared spaces
- Privacy-conscious authentication flows
- Comfortable authentication positioning

**Testing Requirements:**
- Test all authentication flows in VisionOS Simulator
- Verify token security and storage
- Test multi-user scenarios and switching
- Validate biometric authentication integration
- Test error handling and edge cases

**Security Considerations:**
- Secure credential storage using Keychain
- Implement proper session timeout
- Handle authentication token refresh
- Protect against common security vulnerabilities
- Comply with VisionOS privacy guidelines

**Deliverables:**
- Complete authentication system
- VisionOS-optimized authentication UI
- Secure user management and profiles
- Multi-user support for spatial computing
- Integration with app services and analytics

Before completing, run a build check to ensure no compilation errors in the files you modified.