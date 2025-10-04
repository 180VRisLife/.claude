#!/usr/bin/env python3
"""
Workspace initialization script that detects domain and copies appropriate configuration.
"""
import json
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional, Tuple


def detect_domain(workspace_path: Path) -> str:
    """
    Detect the project domain based on file patterns.
    Returns: 'ios', 'visionos', 'webdev', 'default', or other supported domains
    """
    # iOS indicators (standard iOS apps without visionOS)
    ios_indicators = {
        'strong': [
            ('**/*.xcodeproj', 'Xcode project'),
            ('**/*.xcworkspace', 'Xcode workspace'),
        ],
        'medium': [
            ('**/*.swift', 'Swift files'),
            ('**/Podfile', 'CocoaPods dependency file'),
            ('**/Package.swift', 'Swift Package Manager'),
        ]
    }

    # VisionOS indicators (must be specific to avoid false positives)
    visionos_indicators = {
        'strong': [
            ('**/*.xcodeproj', 'Xcode project'),
            ('**/*.xcworkspace', 'Xcode workspace'),
            ('**/RealityKitContent/**', 'RealityKit content'),
        ],
        'medium': [
            ('**/*.swift', 'Swift files with framework checks'),
        ]
    }

    # Web Development indicators (React/Next.js focused)
    webdev_indicators = {
        'strong': [
            ('**/next.config.js', 'Next.js config'),
            ('**/next.config.ts', 'Next.js config (TS)'),
            ('**/next.config.mjs', 'Next.js config (ESM)'),
            ('**/app/**/page.tsx', 'Next.js App Router'),
            ('**/app/**/layout.tsx', 'Next.js layouts'),
        ],
        'medium': [
            ('**/package.json', 'package.json with React check'),
            ('**/tsconfig.json', 'TypeScript config'),
            ('**/tailwind.config.js', 'Tailwind CSS'),
            ('**/tailwind.config.ts', 'Tailwind CSS (TS)'),
        ]
    }

    # Default domain indicators
    default_indicators = [
        ('**/*.js', 'JavaScript'),
        ('**/*.jsx', 'JSX'),
        ('**/*.ts', 'TypeScript'),
        ('**/*.tsx', 'TSX'),
        ('**/*.py', 'Python'),
        ('**/*.java', 'Java'),
        ('**/*.go', 'Go'),
        ('**/*.rs', 'Rust'),
        ('**/package.json', 'Node.js project'),
        ('**/requirements.txt', 'Python project'),
        ('**/Cargo.toml', 'Rust project'),
        ('**/go.mod', 'Go project'),
    ]

    # Check for strong visionOS indicators first (more specific than iOS)
    for pattern, description in visionos_indicators['strong']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            # Check for RealityKitContent which is visionOS-specific
            if 'RealityKitContent' in pattern:
                print(f"  ✓ Found {description}: {len(matches)} file(s)")
                return 'visionos'

            # For Xcode projects, need to check Swift files for visionOS frameworks
            print(f"  ✓ Found {description}: {len(matches)} file(s)")
            swift_files = list(workspace_path.glob('**/*.swift'))
            if swift_files:
                # Sample Swift files to check for visionOS frameworks
                has_visionos_frameworks = False
                has_ios_frameworks = False
                for swift_file in swift_files[:10]:
                    try:
                        content = swift_file.read_text()
                        if any(fw in content for fw in ['import RealityKit', 'WindowGroup { ImmersiveSpace']):
                            has_visionos_frameworks = True
                            break
                        if any(fw in content for fw in ['import UIKit', 'UIViewController', 'UIView']):
                            has_ios_frameworks = True
                    except:
                        pass

                if has_visionos_frameworks:
                    print(f"  ✓ Swift files contain visionOS frameworks")
                    return 'visionos'
                elif has_ios_frameworks:
                    # Break out to check iOS indicators
                    break

    # Check for iOS indicators (standard iOS without visionOS)
    ios_strong_score = 0
    for pattern, description in ios_indicators['strong']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            ios_strong_score += 1
            print(f"  ✓ Found {description}: {len(matches)} file(s)")

    # If we found Xcode projects, check for iOS-specific indicators
    if ios_strong_score > 0:
        swift_files = list(workspace_path.glob('**/*.swift'))
        if swift_files:
            # Check for iOS frameworks (UIKit, SwiftUI without visionOS)
            has_ios_frameworks = False
            for swift_file in swift_files[:10]:
                try:
                    content = swift_file.read_text()
                    if any(fw in content for fw in ['import UIKit', 'UIViewController', 'import SwiftUI']):
                        has_ios_frameworks = True
                        print(f"  ✓ Swift files contain iOS frameworks")
                        break
                except:
                    pass

            if has_ios_frameworks:
                return 'ios'

        # Check for iOS-specific dependency management
        for pattern, description in ios_indicators['medium']:
            matches = list(workspace_path.glob(pattern))
            if matches:
                print(f"  ✓ Found {description}")
                return 'ios'

    # Check for strong Web Development indicators (Next.js/React)
    webdev_strong_score = 0
    for pattern, description in webdev_indicators['strong']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            webdev_strong_score += 1
            print(f"  ✓ Found {description}: {len(matches)} file(s)")

    # If we found strong Next.js indicators, it's webdev
    if webdev_strong_score > 0:
        return 'webdev'

    # Check for medium Web Development indicators
    webdev_medium_score = 0
    for pattern, description in webdev_indicators['medium']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            # For package.json, check if it contains React
            if 'package.json' in pattern:
                for match in matches:
                    try:
                        content = match.read_text()
                        if 'react' in content.lower() or 'next' in content.lower():
                            webdev_medium_score += 2  # Strong indicator
                            print(f"  ✓ Found {description} with React/Next.js")
                            break
                    except:
                        pass
            else:
                webdev_medium_score += 1
                print(f"  ✓ Found {description}")

    # If we have multiple webdev indicators, it's likely a web project
    if webdev_medium_score >= 2:
        return 'webdev'

    # Check for default domain indicators
    default_score = 0
    found_indicators = []
    for pattern, description in default_indicators:
        matches = list(workspace_path.glob(pattern))
        if matches:
            default_score += 1
            found_indicators.append(f"{description} ({len(matches)} files)")

    if default_score > 0:
        print(f"  ✓ Found default domain indicators:")
        for indicator in found_indicators[:3]:  # Show top 3
            print(f"    - {indicator}")
        return 'default'

    # If nothing detected, default to 'default' domain
    print("  ! No clear domain indicators found, defaulting to 'default' domain")
    return 'default'


def get_existing_domain(workspace_path: Path) -> Optional[str]:
    """Check if workspace is already initialized and return current domain."""
    domain_file = workspace_path / ".claude" / "domain.json"
    if domain_file.exists():
        try:
            with open(domain_file, 'r') as f:
                data = json.load(f)
                return data.get('domain')
        except:
            pass
    return None


def preserve_user_settings(workspace_claude: Path) -> Dict:
    """Extract user customizations from existing settings.local.json"""
    settings_file = workspace_claude / "settings.local.json"
    if not settings_file.exists():
        return {}

    try:
        with open(settings_file, 'r') as f:
            settings = json.load(f)

        # Preserve non-domain-specific customizations
        preserved = {}

        # Keep custom permissions if any
        if 'permissions' in settings:
            preserved['permissions'] = settings['permissions']

        # Keep any custom fields not related to domain
        for key in settings:
            if key not in ['hooks', 'outputStyle', 'permissions']:
                preserved[key] = settings[key]

        return preserved
    except:
        return {}


def clean_domain_files(workspace_claude: Path):
    """Remove existing domain-specific files."""
    folders_to_remove = ['agents', 'commands', 'file-templates', 'guides', 'hooks', 'output-styles']

    for folder in folders_to_remove:
        folder_path = workspace_claude / folder
        if folder_path.exists():
            shutil.rmtree(folder_path)
            print(f"  ✓ Removed old {folder}/")


def copy_domain_files(source_domain: Path, workspace_claude: Path):
    """Copy all domain files from Library to workspace."""
    folders = ['agents', 'commands', 'file-templates', 'guides', 'hooks', 'output-styles']

    for folder in folders:
        source = source_domain / folder
        dest = workspace_claude / folder

        if source.exists():
            shutil.copytree(source, dest)
            file_count = len(list(dest.rglob('*')))
            print(f"  ✓ Copied {folder}/ ({file_count} files)")


def merge_settings(domain_settings_template: Path, workspace_claude: Path, preserved: Dict):
    """Merge domain settings template with preserved user customizations."""
    if not domain_settings_template.exists():
        print("  ! Warning: No domain settings template found")
        return

    with open(domain_settings_template, 'r') as f:
        settings = json.load(f)

    # Merge preserved customizations
    for key, value in preserved.items():
        if key == 'permissions':
            # Merge permissions carefully
            if 'permissions' in settings:
                for perm_type in ['allow', 'deny', 'ask']:
                    if perm_type in value:
                        settings['permissions'][perm_type] = list(set(
                            settings['permissions'].get(perm_type, []) + value[perm_type]
                        ))
            else:
                settings['permissions'] = value
        else:
            settings[key] = value

    # Write merged settings
    settings_file = workspace_claude / "settings.local.json"
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)

    print(f"  ✓ Created settings.local.json")


def create_domain_marker(workspace_claude: Path, domain: str):
    """Create domain.json marker file."""
    domain_data = {
        "domain": domain,
        "initialized": datetime.utcnow().isoformat() + "Z"
    }

    domain_file = workspace_claude / "domain.json"
    with open(domain_file, 'w') as f:
        json.dump(domain_data, f, indent=2)

    print(f"  ✓ Created domain.json marker")


def verify_installation(workspace_claude: Path) -> bool:
    """Verify that all required files were copied."""
    required_folders = ['agents', 'commands']

    for folder in required_folders:
        folder_path = workspace_claude / folder
        if not folder_path.exists() or not list(folder_path.rglob('*.md')):
            print(f"  ✗ Error: {folder}/ is missing or empty")
            return False

    print(f"  ✓ Installation verified")
    return True


def main():
    # Parse command line arguments
    if len(sys.argv) < 2:
        print("Usage: python3 init-workspace.py <domain> [workspace_path]")
        print("\nAvailable domains: ios, visionos, webdev, default")
        sys.exit(1)

    domain = sys.argv[1]
    workspace_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()
    workspace_claude = workspace_path / ".claude"

    # Validate domain
    available_domains = ['ios', 'visionos', 'webdev', 'default']
    if domain not in available_domains:
        print(f"❌ Error: Invalid domain '{domain}'")
        print(f"   Available domains: {', '.join(available_domains)}")
        sys.exit(1)

    print(f"\n🔍 Initializing workspace: {workspace_path}")
    print(f"📦 Selected domain: {domain}")

    # Check existing initialization
    existing_domain = get_existing_domain(workspace_path)
    if existing_domain:
        print(f"\n⚠️  Workspace already initialized with domain: {existing_domain}")
        if existing_domain != domain:
            print(f"   Re-initializing from {existing_domain} to {domain}")

    # Create .claude directory if it doesn't exist
    workspace_claude.mkdir(exist_ok=True)

    # Preserve user customizations
    print(f"\n💾 Preserving user customizations...")
    preserved = preserve_user_settings(workspace_claude)
    if preserved:
        print(f"  ✓ Preserved {len(preserved)} custom setting(s)")
    else:
        print(f"  ✓ No existing customizations to preserve")

    # Clean existing domain files
    print(f"\n🧹 Cleaning existing domain files...")
    clean_domain_files(workspace_claude)

    # Copy domain files from Library
    print(f"\n📦 Installing {domain} domain configuration...")
    library_path = Path.home() / ".claude" / "library" / domain

    if not library_path.exists():
        print(f"❌ Error: Domain library not found at {library_path}")
        sys.exit(1)

    copy_domain_files(library_path, workspace_claude)

    # Merge settings
    print(f"\n⚙️  Configuring settings...")
    domain_settings_template = library_path / "settings.local.template.json"
    merge_settings(domain_settings_template, workspace_claude, preserved)

    # Create domain marker
    print(f"\n✍️  Creating domain marker...")
    create_domain_marker(workspace_claude, domain)

    # Verify installation
    print(f"\n✅ Verifying installation...")
    if verify_installation(workspace_claude):
        print(f"\n🎉 Workspace initialized successfully with '{domain}' domain!")
        print(f"\n   Configuration files installed to: {workspace_claude}")
        print(f"   You can now use domain-specific commands and agents.")
    else:
        print(f"\n❌ Installation verification failed. Please check the Library folder.")
        sys.exit(1)


if __name__ == "__main__":
    main()