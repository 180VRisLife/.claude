#!/usr/bin/env python3
"""
Workspace initialization script that detects domain and copies appropriate configuration.
"""
import json
import os
import re
import shutil
import sys
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional, Tuple


def detect_domain(workspace_path: Path) -> str:
    """
    Detect the project domain based on file patterns.
    Returns: 'ios', 'macos', 'visionos', 'webdev', 'default', or other supported domains
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

    # macOS indicators (macOS applications)
    macos_indicators = {
        'strong': [
            ('**/*.xcodeproj', 'Xcode project'),
            ('**/*.xcworkspace', 'Xcode workspace'),
        ],
        'medium': [
            ('**/*.swift', 'Swift files'),
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

    # Stream Deck plugin indicators
    streamdeck_indicators = {
        'strong': [
            ('**/*.sdPlugin', 'Stream Deck plugin folder'),
            ('**/*.sdPlugin/manifest.json', 'Stream Deck manifest'),
        ],
        'medium': [
            ('**/package.json', 'package.json with Stream Deck SDK check'),
            ('**/rollup.config.mjs', 'Rollup config for Stream Deck'),
            ('**/src/**/*.ts', 'TypeScript action files'),
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

    # Check Xcode projects to distinguish macOS from iOS
    xcode_projects = list(workspace_path.glob('**/*.xcodeproj')) + list(workspace_path.glob('**/*.xcworkspace'))

    has_macos_project = False
    has_ios_project = False
    has_macos_frameworks = False
    has_ios_frameworks = False

    if xcode_projects:
        print(f"  ✓ Found Xcode project(s): {len(xcode_projects)} file(s)")

        # Check project files for platform identifiers
        for project in xcode_projects:
            if project.suffix == '.xcodeproj':
                pbxproj = project / 'project.pbxproj'
                if pbxproj.exists():
                    try:
                        content = pbxproj.read_text()

                        # Check for macOS platform identifiers (more comprehensive)
                        if any(indicator in content for indicator in [
                            'SDKROOT = macosx',
                            'MACOSX_DEPLOYMENT_TARGET',
                            '"macOS"',
                            'SUPPORTED_PLATFORMS = macosx',
                            'PRODUCT_BUNDLE_IDENTIFIER.*macos',
                        ]):
                            has_macos_project = True
                            print(f"  ✓ Found macOS-specific project configuration in {project.name}")

                        # Check for iOS platform identifiers
                        if any(indicator in content for indicator in [
                            'SDKROOT = iphoneos',
                            'IPHONEOS_DEPLOYMENT_TARGET',
                            '"iOS"',
                            'SUPPORTED_PLATFORMS = iphoneos',
                        ]):
                            has_ios_project = True
                            print(f"  ✓ Found iOS-specific project configuration in {project.name}")
                    except:
                        pass

        # Check ALL Swift files for framework usage (more thorough than before)
        swift_files = list(workspace_path.glob('**/*.swift'))
        if swift_files:
            print(f"  ✓ Checking {len(swift_files)} Swift file(s) for framework usage...")

            for swift_file in swift_files:
                try:
                    swift_content = swift_file.read_text()

                    # macOS frameworks
                    if any(fw in swift_content for fw in [
                        'import AppKit',
                        'import Cocoa',
                        'NSWindow',
                        'NSView',
                        'NSViewController',
                        'NSApplication'
                    ]):
                        has_macos_frameworks = True

                    # iOS frameworks
                    if any(fw in swift_content for fw in [
                        'import UIKit',
                        'UIViewController',
                        'UIView',
                        'UIApplication',
                        'UIWindow'
                    ]):
                        has_ios_frameworks = True

                    # Early exit if we found both (edge case)
                    if has_macos_frameworks and has_ios_frameworks:
                        break
                except:
                    pass

            if has_macos_frameworks:
                print(f"  ✓ Swift files contain AppKit/Cocoa frameworks (macOS)")
            if has_ios_frameworks:
                print(f"  ✓ Swift files contain UIKit frameworks (iOS)")

        # Decision logic: prioritize framework usage over project config
        # Framework imports are more reliable than pbxproj parsing
        if has_macos_frameworks and not has_ios_frameworks:
            return 'macos'
        elif has_ios_frameworks and not has_macos_frameworks:
            return 'ios'
        elif has_macos_frameworks and has_ios_frameworks:
            # Edge case: multi-platform project - prefer macOS if pbxproj indicates it
            if has_macos_project:
                print(f"  ℹ Multi-platform project detected, prioritizing macOS")
                return 'macos'
            else:
                print(f"  ℹ Multi-platform project detected, prioritizing iOS")
                return 'ios'
        elif has_macos_project and not has_ios_project:
            # Project config says macOS but no framework found - trust the config
            print(f"  ℹ Project configured for macOS (no framework imports found)")
            return 'macos'
        elif has_ios_project and not has_macos_project:
            # Project config says iOS but no framework found - trust the config
            print(f"  ℹ Project configured for iOS (no framework imports found)")
            return 'ios'
        # If we still can't determine, continue to iOS check below

    # Fallback: Check for iOS-specific dependency management (CocoaPods, etc.)
    for pattern, description in ios_indicators['medium']:
        matches = list(workspace_path.glob(pattern))
        if matches and 'Podfile' in pattern:
            print(f"  ✓ Found {description}, assuming iOS")
            return 'ios'

    # Check for strong Stream Deck indicators
    streamdeck_strong_score = 0
    for pattern, description in streamdeck_indicators['strong']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            streamdeck_strong_score += 1
            print(f"  ✓ Found {description}: {len(matches)} file(s)")

    # If we found strong Stream Deck indicators, it's streamdeck
    if streamdeck_strong_score > 0:
        return 'streamdeck'

    # Check for medium Stream Deck indicators
    streamdeck_medium_score = 0
    for pattern, description in streamdeck_indicators['medium']:
        matches = list(workspace_path.glob(pattern))
        if matches:
            # For package.json, check if it contains @elgato/streamdeck
            if 'package.json' in pattern:
                for match in matches:
                    try:
                        content = match.read_text()
                        if '@elgato/streamdeck' in content:
                            streamdeck_medium_score += 2  # Strong indicator
                            print(f"  ✓ Found {description} with @elgato/streamdeck dependency")
                            break
                    except:
                        pass
            else:
                streamdeck_medium_score += 1
                print(f"  ✓ Found {description}")

    # If we have multiple streamdeck indicators, it's likely a Stream Deck plugin
    if streamdeck_medium_score >= 2:
        return 'streamdeck'

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


def load_domain_config(workspace_claude: Path) -> Dict:
    """Load existing domain configuration."""
    domain_file = workspace_claude / "domain.json"
    if domain_file.exists():
        try:
            with open(domain_file, 'r') as f:
                return json.load(f)
        except:
            pass
    return {}


def save_domain_config(workspace_claude: Path, config: Dict):
    """Save domain configuration."""
    domain_file = workspace_claude / "domain.json"
    with open(domain_file, 'w') as f:
        json.dump(config, f, indent=2)


def create_domain_marker(workspace_claude: Path, domain: str, config: Dict = None):
    """Create domain.json marker file with configuration tracking."""
    existing_config = load_domain_config(workspace_claude)

    # Preserve existing configuration state
    domain_data = {
        "domain": domain,
        "initialized": existing_config.get("initialized", datetime.utcnow().isoformat() + "Z"),
        "last_updated": datetime.utcnow().isoformat() + "Z",
        "build_settings_configured": existing_config.get("build_settings_configured", False),
        "debug_icons_generated": existing_config.get("debug_icons_generated", False),
        "template_versions": existing_config.get("template_versions", {}),
    }

    # Merge in new configuration if provided
    if config:
        domain_data.update(config)

    save_domain_config(workspace_claude, domain_data)

    if existing_config:
        print(f"  ✓ Updated domain.json marker")
    else:
        print(f"  ✓ Created domain.json marker")


def check_dependencies() -> Dict[str, bool]:
    """Check for optional Python dependencies."""
    dependencies = {
        'pbxproj': False,
        'PIL': False  # Pillow
    }

    try:
        import pbxproj
        dependencies['pbxproj'] = True
    except ImportError:
        pass

    try:
        from PIL import Image
        dependencies['PIL'] = True
    except ImportError:
        pass

    return dependencies


def setup_gitignore(workspace_path: Path, library_path: Path, domain: str):
    """Set up comprehensive .gitignore from domain template."""
    print(f"\n📝 Setting up .gitignore...")

    gitignore_path = workspace_path / ".gitignore"
    template_path = library_path / "file-templates" / ".gitignore.template"

    # Check if template exists
    if not template_path.exists():
        print(f"  ⚠️  No .gitignore template found for {domain} domain")
        # Fallback: ensure .worktrees/ is ignored
        if not gitignore_path.exists():
            gitignore_path.write_text(".worktrees/\n")
            print(f"  ✓ Created minimal .gitignore with .worktrees/ entry")
        else:
            content = gitignore_path.read_text()
            if ".worktrees" not in content:
                with gitignore_path.open('a') as f:
                    f.write("\n.worktrees/\n")
                print(f"  ✓ Added .worktrees/ to existing .gitignore")
        return

    # Read template
    template_content = template_path.read_text()
    template_lines = set(line.strip() for line in template_content.splitlines() if line.strip() and not line.strip().startswith('#'))

    if not gitignore_path.exists():
        # No existing .gitignore, use template directly
        gitignore_path.write_text(template_content)
        print(f"  ✓ Created .gitignore from {domain} template")
    else:
        # Merge with existing .gitignore
        existing_content = gitignore_path.read_text()
        existing_lines = [line.rstrip() for line in existing_content.splitlines()]
        existing_patterns = set(line.strip() for line in existing_lines if line.strip() and not line.strip().startswith('#'))

        # Find patterns that are in template but not in existing
        new_patterns = template_lines - existing_patterns

        if new_patterns:
            # Append new patterns to existing file
            with gitignore_path.open('a') as f:
                f.write("\n\n# Added by /init-workspace\n")
                for line in template_content.splitlines():
                    stripped = line.strip()
                    if stripped and not stripped.startswith('#'):
                        if stripped in new_patterns:
                            f.write(line + "\n")
                    elif stripped.startswith('#') and any(p in template_content[template_content.index(line):template_content.index(line)+200] for p in new_patterns):
                        # Include comment headers for new sections
                        f.write(line + "\n")
            print(f"  ✓ Merged {len(new_patterns)} new pattern(s) into existing .gitignore")
        else:
            print(f"  ℹ  .gitignore already comprehensive (no new patterns added)")


def ensure_worktree_infrastructure(workspace_path: Path):
    """Set up worktree infrastructure for all domains."""
    print(f"\n📂 Setting up worktree infrastructure...")

    worktrees_dir = workspace_path / ".worktrees"

    # Create .worktrees directory
    worktrees_dir.mkdir(exist_ok=True)
    print(f"  ✓ Created .worktrees/ directory")


def is_xcode_build_settings_configured(workspace_path: Path, domain: str, dependencies: Dict[str, bool]) -> bool:
    """Check if Xcode project already has Debug/Release build settings configured."""
    if domain not in ['ios', 'macos', 'visionos']:
        return False

    if not dependencies.get('pbxproj'):
        return False

    # Find Xcode project
    xcode_projects = list(workspace_path.glob('*.xcodeproj'))
    if not xcode_projects:
        return False

    project_path = xcode_projects[0] / 'project.pbxproj'

    try:
        from pbxproj import XcodeProject
        project = XcodeProject.load(str(project_path))

        debug_bundle_id = None
        release_bundle_id = None
        debug_app_icon = None
        release_app_icon = None

        # Check if Debug and Release have different bundle IDs and app icons
        for config in project.objects.get_configurations_on_targets():
            settings = config.buildSettings
            if config.name == 'Debug':
                debug_bundle_id = settings.get('PRODUCT_BUNDLE_IDENTIFIER')
                debug_app_icon = settings.get('ASSETCATALOG_COMPILER_APPICON_NAME')
            elif config.name == 'Release':
                release_bundle_id = settings.get('PRODUCT_BUNDLE_IDENTIFIER')
                release_app_icon = settings.get('ASSETCATALOG_COMPILER_APPICON_NAME')

        # Consider configured if:
        # 1. Both configs have bundle IDs AND they're different, OR
        # 2. Debug bundle ID has .debug suffix, OR
        # 3. Different app icon names configured
        has_different_bundles = (debug_bundle_id and release_bundle_id and debug_bundle_id != release_bundle_id)
        has_debug_suffix = (debug_bundle_id and '.debug' in debug_bundle_id)
        has_different_icons = (debug_app_icon and release_app_icon and debug_app_icon != release_app_icon)

        return has_different_bundles or has_debug_suffix or has_different_icons

    except Exception:
        return False


def configure_debug_release_build_settings(workspace_path: Path, domain: str, dependencies: Dict[str, bool], workspace_claude: Path) -> bool:
    """Configure separate Debug/Release build settings for Xcode projects. Returns True if configured."""
    if domain not in ['ios', 'macos', 'visionos']:
        return False

    if not dependencies.get('pbxproj'):
        print(f"  ℹ  Skipping build settings configuration (pbxproj not installed)")
        return False

    print(f"\n⚙️  Configuring Debug/Release build settings...")

    # Check if already configured
    if is_xcode_build_settings_configured(workspace_path, domain, dependencies):
        print(f"  ℹ  Build settings already configured (Debug/Release separation detected)")
        print(f"  ℹ  Skipping to preserve existing configuration")
        return True

    # Find Xcode project
    xcode_projects = list(workspace_path.glob('*.xcodeproj'))
    if not xcode_projects:
        print(f"  ℹ  No Xcode project found, skipping build settings configuration")
        return False

    project_path = xcode_projects[0] / 'project.pbxproj'
    project_name = xcode_projects[0].stem

    try:
        from pbxproj import XcodeProject

        project = XcodeProject.load(str(project_path))

        # Get current bundle ID from Release configuration (or create generic one)
        current_bundle_id = None
        try:
            # Try to find existing bundle ID
            for config in project.objects.get_configurations_on_targets():
                if config.name == 'Release':
                    settings = config.buildSettings
                    if 'PRODUCT_BUNDLE_IDENTIFIER' in settings:
                        current_bundle_id = settings['PRODUCT_BUNDLE_IDENTIFIER']
                        break
        except:
            pass

        if not current_bundle_id:
            # Generate generic bundle ID
            current_bundle_id = f"com.{project_name.lower().replace(' ', '')}"
            print(f"  ℹ  No existing bundle ID found, using: {current_bundle_id}")

        # Configure Debug settings
        project.add_flags({
            'PRODUCT_BUNDLE_IDENTIFIER': f'{current_bundle_id}.debug',
            'PRODUCT_NAME': f'{project_name}-Debug',
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon-Debug'
        }, configuration='Debug')

        # Configure Release settings
        project.add_flags({
            'PRODUCT_BUNDLE_IDENTIFIER': current_bundle_id,
            'PRODUCT_NAME': project_name,
            'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon'
        }, configuration='Release')

        # Save changes
        project.save()

        print(f"  ✓ Configured Debug bundle ID: {current_bundle_id}.debug")
        print(f"  ✓ Configured Release bundle ID: {current_bundle_id}")
        print(f"  ✓ Configured product names: {project_name}-Debug / {project_name}")
        print(f"  ✓ Configured app icons: AppIcon-Debug / AppIcon")

        return True

    except ImportError:
        print(f"  ! pbxproj import failed (should not happen)")
        return False
    except Exception as e:
        print(f"  ! Error configuring build settings: {e}")
        print(f"  ! You may need to configure bundle IDs manually in Xcode")
        return False


def setup_debug_icons(workspace_path: Path, domain: str, dependencies: Dict[str, bool]) -> bool:
    """Set up debug app icons using the generate-debug-icon.py script. Returns True if generated."""
    if domain not in ['ios', 'macos', 'visionos']:
        return False

    if not dependencies.get('PIL'):
        print(f"  ℹ  Skipping debug icon generation (Pillow not installed)")
        return False

    print(f"\n🎨 Setting up debug icons...")

    # Find Assets.xcassets
    assets_dirs = list(workspace_path.glob('**/Assets.xcassets'))
    if not assets_dirs:
        print(f"  ℹ  No Assets.xcassets found, skipping icon generation")
        return False

    assets_path = assets_dirs[0]

    # Check if AppIcon-Debug already exists
    debug_icon_path = assets_path / "AppIcon-Debug.appiconset"
    if debug_icon_path.exists():
        print(f"  ℹ  AppIcon-Debug already exists at: {debug_icon_path.relative_to(workspace_path)}")
        print(f"  ℹ  Skipping icon generation to preserve existing icons")
        return True

    print(f"  ✓ Found assets at: {assets_path.relative_to(workspace_path)}")

    # Copy the generate-debug-icon.py script to project's .claude/scripts/
    project_claude_scripts = workspace_path / ".claude" / "scripts"
    project_claude_scripts.mkdir(parents=True, exist_ok=True)

    global_script = Path.home() / ".claude" / "scripts" / "generate-debug-icon.py"
    project_script = project_claude_scripts / "generate-debug-icon.py"

    shutil.copy2(global_script, project_script)
    project_script.chmod(0o755)
    print(f"  ✓ Copied generate-debug-icon.py to .claude/scripts/")

    # Run the script to generate icons
    try:
        result = subprocess.run(
            [sys.executable, str(project_script), str(assets_path)],
            capture_output=True,
            text=True,
            cwd=workspace_path
        )

        if result.returncode == 0:
            # Print script output (indented)
            for line in result.stdout.split('\n'):
                if line.strip():
                    print(f"  {line}")
            return True
        else:
            print(f"  ! Icon generation failed: {result.stderr}")
            print(f"  ! You can run manually: python3 .claude/scripts/generate-debug-icon.py {assets_path}")
            return False

    except Exception as e:
        print(f"  ! Error running icon generation script: {e}")
        print(f"  ! You can run manually: python3 .claude/scripts/generate-debug-icon.py {assets_path}")
        return False


def extract_template_version(content: str) -> Optional[str]:
    """Extract version marker from template content."""
    # Look for version markers like: // Template Version: 1.0
    match = re.search(r'//\s*Template\s+Version:\s*(\S+)', content)
    if match:
        return match.group(1)
    return None


def should_update_template_file(existing_path: Path, template_path: Path) -> Tuple[bool, str]:
    """
    Determine if template file should be updated.
    Returns: (should_update, reason)
    """
    if not existing_path.exists():
        return (True, "new")

    if not template_path.exists():
        return (False, "no_template")

    existing_content = existing_path.read_text()
    template_content = template_path.read_text()

    # Check for version markers
    existing_version = extract_template_version(existing_content)
    template_version = extract_template_version(template_content)

    # If template has version but existing doesn't, it's an old file
    if template_version and not existing_version:
        return (False, "user_customized")  # Preserve user customizations

    # If both have versions, compare them
    if existing_version and template_version:
        if template_version > existing_version:
            return (True, f"update_{existing_version}_to_{template_version}")
        else:
            return (False, "up_to_date")

    # No version markers - assume user may have customized
    return (False, "user_customized")


def merge_template_improvements(existing_path: Path, template_path: Path, project_name: str) -> bool:
    """
    Intelligently merge template improvements while preserving user customizations.
    Returns True if file was updated.
    """
    should_update, reason = should_update_template_file(existing_path, template_path)

    if not should_update:
        if reason == "user_customized":
            print(f"  ℹ  {existing_path.name} exists and may have customizations, preserving")
        elif reason == "up_to_date":
            print(f"  ℹ  {existing_path.name} is up to date")
        return False

    if reason == "new":
        # New file, create from template
        template_content = template_path.read_text()
        content = template_content.replace("{{PROJECT_NAME}}", project_name)
        existing_path.write_text(content)
        print(f"  ✓ Created {existing_path.name}")
        return True
    elif reason.startswith("update_"):
        # Template has newer version - for now, preserve existing
        # In future, could implement smart merging here
        print(f"  ℹ  {existing_path.name} has updates available, but preserving existing to avoid data loss")
        print(f"  💡 Consider manually reviewing template at {template_path}")
        return False

    return False


def create_debug_overlay_template(workspace_path: Path, domain: str, library_path: Path, project_name: str, utilities_dir: Path) -> bool:
    """Create or update DebugOverlay.swift template for the project. Returns True if created/updated."""
    if domain not in ['ios', 'macos', 'visionos']:
        return False

    template_path = library_path / "file-templates" / "DebugOverlay.swift.template"
    if not template_path.exists():
        print(f"  ! DebugOverlay template not found: {template_path}")
        return False

    overlay_path = utilities_dir / "DebugOverlay.swift"
    return merge_template_improvements(overlay_path, template_path, project_name)


def setup_git_info_helper(workspace_path: Path, domain: str, library_path: Path, project_name: str, utilities_dir: Path) -> bool:
    """Create or update GitInfo.swift helper for git state detection. Returns True if created/updated."""
    if domain not in ['ios', 'macos', 'visionos']:
        return False

    template_path = library_path / "file-templates" / "GitInfo.swift.template"
    if not template_path.exists():
        print(f"  ! GitInfo template not found: {template_path}")
        return False

    gitinfo_path = utilities_dir / "GitInfo.swift"
    return merge_template_improvements(gitinfo_path, template_path, project_name)


def setup_debug_logger(domain: str, workspace_path: Path, library_path: Path) -> Dict[str, bool]:
    """
    Set up DebugLogger.swift for macOS and visionOS projects.
    Returns dict tracking what was created/updated.
    """
    results = {
        'debug_logger': False,
        'debug_overlay': False,
        'git_info': False
    }

    # Only applicable for macOS and visionOS
    if domain not in ['macos', 'visionos']:
        return results

    print(f"\n🪵 Setting up debug infrastructure...")

    # Find Xcode project to determine project name
    xcode_projects = list(workspace_path.glob('*.xcodeproj'))
    if not xcode_projects:
        print("  ! No Xcode project found, skipping debug infrastructure setup")
        return results

    # Get project name from first .xcodeproj file
    project_name = xcode_projects[0].stem
    print(f"  ✓ Detected project: {project_name}")

    # Determine subsystem name (reverse domain notation)
    subsystem = f"com.{project_name.lower()}.debug"

    # Find project directory (directory with same name as .xcodeproj without extension)
    project_dir = workspace_path / project_name
    if not project_dir.exists():
        # Try to find any directory that looks like source code
        possible_dirs = [d for d in workspace_path.iterdir()
                        if d.is_dir() and not d.name.startswith('.')]
        if possible_dirs:
            project_dir = possible_dirs[0]
        else:
            print(f"  ! Could not find source directory for {project_name}")
            return results

    # Create Utilities directory
    utilities_dir = project_dir / "Utilities"
    utilities_dir.mkdir(exist_ok=True)
    print(f"  ✓ Created {project_name}/Utilities/")

    # Handle DebugLogger with smart merging
    template_path = library_path / "file-templates" / "DebugLogger.swift.template"
    if template_path.exists():
        logger_path = utilities_dir / "DebugLogger.swift"

        # For DebugLogger, we need to replace both PROJECT_NAME and SUBSYSTEM
        # Use custom logic instead of generic merge_template_improvements
        if logger_path.exists():
            print(f"  ℹ  DebugLogger.swift already exists at {project_name}/Utilities/, preserving")
            results['debug_logger'] = True
        else:
            template_content = template_path.read_text()
            logger_content = template_content.replace("{{PROJECT_NAME}}", project_name)
            logger_content = logger_content.replace("{{SUBSYSTEM}}", subsystem)
            logger_path.write_text(logger_content)
            print(f"  ✓ Created DebugLogger.swift at {project_name}/Utilities/")
            print(f"  ✓ Log file will be: /tmp/{project_name}-Debug.log")
            results['debug_logger'] = True
    else:
        print(f"  ! DebugLogger template not found: {template_path}")

    # Create DebugOverlay and GitInfo templates
    results['debug_overlay'] = create_debug_overlay_template(workspace_path, domain, library_path, project_name, utilities_dir)
    results['git_info'] = setup_git_info_helper(workspace_path, domain, library_path, project_name, utilities_dir)

    return results


def setup_streamdeck_debug(workspace_path: Path, library_path: Path):
    """Set up debug infrastructure for Stream Deck plugins."""
    print(f"\n🎮 Setting up Stream Deck debug infrastructure...")

    # Find package.json to determine plugin name
    package_json = workspace_path / "package.json"
    if not package_json.exists():
        print(f"  ℹ  No package.json found, skipping Stream Deck setup")
        return

    # Read package.json to get plugin name
    import json
    try:
        with open(package_json, 'r') as f:
            pkg_data = json.load(f)
            plugin_name = pkg_data.get('name', 'StreamDeckPlugin')
    except:
        plugin_name = 'StreamDeckPlugin'

    print(f"  ✓ Detected plugin: {plugin_name}")

    # Find src directory
    src_dir = workspace_path / "src"
    if not src_dir.exists():
        src_dir = workspace_path
        print(f"  ℹ  No src/ directory, using project root")

    # Create utils directory
    utils_dir = src_dir / "utils"
    utils_dir.mkdir(exist_ok=True)
    print(f"  ✓ Created utils/ directory")

    # Copy DebugLogger.ts template
    debug_logger_template = library_path / "file-templates" / "DebugLogger.ts.template"
    if debug_logger_template.exists():
        debug_logger_path = utils_dir / "DebugLogger.ts"
        if not debug_logger_path.exists():
            content = debug_logger_template.read_text()
            content = content.replace("{{PLUGIN_NAME}}", plugin_name)
            debug_logger_path.write_text(content)
            print(f"  ✓ Created DebugLogger.ts")
        else:
            print(f"  ℹ  DebugLogger.ts already exists")

    # Copy gitInfo.ts template
    gitinfo_template = library_path / "file-templates" / "gitInfo.ts.template"
    if gitinfo_template.exists():
        gitinfo_path = utils_dir / "gitInfo.ts"
        if not gitinfo_path.exists():
            content = gitinfo_template.read_text()
            content = content.replace("{{PLUGIN_NAME}}", plugin_name)
            gitinfo_path.write_text(content)
            print(f"  ✓ Created gitInfo.ts")
        else:
            print(f"  ℹ  gitInfo.ts already exists")

    # Copy manifest templates to .claude/file-templates for reference
    claude_templates = workspace_path / ".claude" / "file-templates"
    claude_templates.mkdir(parents=True, exist_ok=True)

    for manifest_name in ["manifest.dev.json.template", "manifest.prod.json.template"]:
        manifest_template = library_path / "file-templates" / manifest_name
        if manifest_template.exists():
            dest = claude_templates / manifest_name
            if not dest.exists():
                shutil.copy2(manifest_template, dest)
                print(f"  ✓ Copied {manifest_name} to .claude/file-templates/")


def setup_webdev_debug(workspace_path: Path, library_path: Path, dependencies: Dict[str, bool]):
    """Set up debug infrastructure for webdev (React/Next.js) projects."""
    print(f"\n⚛️  Setting up webdev debug infrastructure...")

    # Find package.json to determine project name
    package_json = workspace_path / "package.json"
    if not package_json.exists():
        print(f"  ℹ  No package.json found, skipping webdev setup")
        return

    # Read package.json to get project name
    import json
    try:
        with open(package_json, 'r') as f:
            pkg_data = json.load(f)
            project_name = pkg_data.get('name', 'webapp')
    except:
        project_name = 'webapp'

    print(f"  ✓ Detected project: {project_name}")

    # Determine directory structure (Next.js App Router vs Pages Router)
    has_app_dir = (workspace_path / "app").exists()
    has_src = (workspace_path / "src").exists()

    if has_src:
        base_dir = workspace_path / "src"
        components_dir = base_dir / "components"
        hooks_dir = base_dir / "hooks"
        lib_dir = base_dir / "lib"
    else:
        base_dir = workspace_path
        components_dir = base_dir / "components"
        hooks_dir = base_dir / "hooks"
        lib_dir = base_dir / "lib"

    # Create directories
    components_dir.mkdir(parents=True, exist_ok=True)
    hooks_dir.mkdir(parents=True, exist_ok=True)
    lib_dir.mkdir(parents=True, exist_ok=True)
    print(f"  ✓ Created component/hook/lib directories")

    # Copy DebugOverlay.tsx template
    overlay_template = library_path / "file-templates" / "DebugOverlay.tsx.template"
    if overlay_template.exists():
        overlay_path = components_dir / "DebugOverlay.tsx"
        if not overlay_path.exists():
            content = overlay_template.read_text()
            content = content.replace("{{PROJECT_NAME}}", project_name)
            overlay_path.write_text(content)
            print(f"  ✓ Created DebugOverlay.tsx")
        else:
            print(f"  ℹ  DebugOverlay.tsx already exists")

    # Copy useGitInfo.ts template
    gitinfo_hook_template = library_path / "file-templates" / "useGitInfo.ts.template"
    if gitinfo_hook_template.exists():
        gitinfo_path = hooks_dir / "useGitInfo.ts"
        if not gitinfo_path.exists():
            content = gitinfo_hook_template.read_text()
            content = content.replace("{{PROJECT_NAME}}", project_name)
            gitinfo_path.write_text(content)
            print(f"  ✓ Created useGitInfo.ts")
        else:
            print(f"  ℹ  useGitInfo.ts already exists")

    # Copy logger.ts template
    logger_template = library_path / "file-templates" / "logger.ts.template"
    if logger_template.exists():
        logger_path = lib_dir / "logger.ts"
        if not logger_path.exists():
            content = logger_template.read_text()
            content = content.replace("{{PROJECT_NAME}}", project_name)
            logger_path.write_text(content)
            print(f"  ✓ Created logger.ts")
        else:
            print(f"  ℹ  logger.ts already exists")

    # Copy .env templates
    for env_file in [".env.development.template", ".env.production.template"]:
        env_template = library_path / "file-templates" / env_file
        if env_template.exists():
            dest = workspace_path / env_file
            if not dest.exists():
                shutil.copy2(env_template, dest)
                print(f"  ✓ Copied {env_file}")

    # Copy scripts to .claude/scripts
    claude_scripts = workspace_path / ".claude" / "scripts"
    claude_scripts.mkdir(parents=True, exist_ok=True)

    # Copy inject-git-info.js script
    inject_script = library_path / "scripts" / "inject-git-info.js"
    if inject_script.exists():
        dest = claude_scripts / "inject-git-info.js"
        shutil.copy2(inject_script, dest)
        dest.chmod(0o755)
        print(f"  ✓ Copied inject-git-info.js to .claude/scripts/")

    # Copy and run generate-debug-favicon.py script if Pillow is available
    if dependencies.get('PIL'):
        favicon_script_src = library_path / "scripts" / "generate-debug-favicon.py"
        if favicon_script_src.exists():
            favicon_script = claude_scripts / "generate-debug-favicon.py"
            shutil.copy2(favicon_script_src, favicon_script)
            favicon_script.chmod(0o755)
            print(f"  ✓ Copied generate-debug-favicon.py to .claude/scripts/")

            # Try to generate debug favicon
            public_dir = workspace_path / "public"
            if public_dir.exists():
                try:
                    result = subprocess.run(
                        [sys.executable, str(favicon_script), str(public_dir)],
                        capture_output=True,
                        text=True,
                        cwd=workspace_path
                    )
                    if result.returncode == 0:
                        for line in result.stdout.split('\n'):
                            if line.strip():
                                print(f"  {line}")
                except Exception as e:
                    print(f"  ℹ  Could not generate debug favicon: {e}")


def setup_default_debug(workspace_path: Path, library_path: Path):
    """Set up debug infrastructure for default/general projects (Python)."""
    print(f"\n🛠️  Setting up default debug infrastructure...")

    # Determine project name
    project_name = workspace_path.name
    print(f"  ✓ Project: {project_name}")

    # Create utils directory
    utils_dir = workspace_path / "utils"
    utils_dir.mkdir(exist_ok=True)
    print(f"  ✓ Created utils/ directory")

    # Copy Python git info helper
    git_info_template = library_path / "file-templates" / "git_info.py.template"
    if git_info_template.exists():
        dest = utils_dir / "git_info.py"
        if not dest.exists():
            content = git_info_template.read_text()
            content = content.replace("{{PROJECT_NAME}}", project_name)
            dest.write_text(content)
            print(f"  ✓ Created git_info.py")
        else:
            print(f"  ℹ  git_info.py already exists")

    # Copy Python debug logger
    logger_template = library_path / "file-templates" / "debug_logger.py.template"
    if logger_template.exists():
        dest = utils_dir / "debug_logger.py"
        if not dest.exists():
            content = logger_template.read_text()
            content = content.replace("{{PROJECT_NAME}}", project_name)
            dest.write_text(content)
            print(f"  ✓ Created debug_logger.py")
        else:
            print(f"  ℹ  debug_logger.py already exists")

    # Copy .env templates
    for env_file in [".env.development.template", ".env.production.template"]:
        env_template = library_path / "file-templates" / env_file
        if env_template.exists():
            dest = workspace_path / env_file
            if not dest.exists():
                shutil.copy2(env_template, dest)
                print(f"  ✓ Copied {env_file}")


def update_claude_md(domain: str, workspace_path: Path, project_name: str):
    """Update CLAUDE.md with DebugLogger documentation."""
    # Only applicable for macOS and visionOS
    if domain not in ['macos', 'visionos']:
        return

    claude_md_path = workspace_path / "CLAUDE.md"
    if not claude_md_path.exists():
        print("  ℹ No CLAUDE.md found, skipping documentation update")
        return

    print(f"\n📝 Updating CLAUDE.md with debugging documentation...")

    # Define domain-specific content
    if domain == 'macos':
        categories = ".app, .ui, .terminal, .services, .appkit, .security, .performance, .network, .general"
        example_category = ".terminal"
    else:  # visionos
        categories = "`.app`, `.ui`, `.services`, `.analytics`, `.downloads`, `.purchases`, `.playback`, `.network`, `.cache`, `.general`"
        example_category = ".services"

    # Generate debugging documentation
    debug_section = f"""### Debugging
- **DebugLogger**: Centralized logging service with automatic DEBUG/RELEASE handling
  - **DEBUG builds**: Writes to `/tmp/{project_name}-Debug.log` (easily accessible for Claude Code)
  - **RELEASE builds**: All methods are no-ops (optimized away by compiler)
  - **No `#if DEBUG` guards needed** - call logging methods anywhere without conditional compilation
  - Log file automatically clears on each app launch (DEBUG only)
  - Template: `DebugLogger.shared.info("🚀 Action completed", category: {example_category})`
  - Categories: {categories}
  - Methods: `log()`, `info()`, `warning()`, `error()`, `separator()`
  - Access log path: `DebugLogger.shared.logPath`
"""

    # Read existing content
    content = claude_md_path.read_text()

    # Pattern to match existing Debugging section (both ## and ### variants)
    pattern = r'(^#{2,3}\s+Debugging\s*\n(?:.*?\n)*?)(?=^#{2,3}\s+|\Z)'

    match = re.search(pattern, content, re.MULTILINE)

    if match:
        # Replace existing debugging section
        content = re.sub(pattern, debug_section + '\n', content, flags=re.MULTILINE)
        print(f"  ✓ Updated existing Debugging section in CLAUDE.md")
    else:
        # Append debugging section before certain markers or at end
        insertion_markers = [
            r'(^#{2,3}\s+Key Technologies)',
            r'(^#{2,3}\s+Important Implementation)',
            r'(^#{2,3}\s+Features)',
            r'(^#{2,3}\s+Common Development)',
        ]

        inserted = False
        for marker in insertion_markers:
            if re.search(marker, content, re.MULTILINE):
                content = re.sub(marker, debug_section + '\n\\1', content, flags=re.MULTILINE)
                inserted = True
                print(f"  ✓ Inserted Debugging section before matching section in CLAUDE.md")
                break

        if not inserted:
            # Append at the end
            content = content.rstrip() + '\n\n' + debug_section
            print(f"  ✓ Appended Debugging section to end of CLAUDE.md")

    # Write updated content
    claude_md_path.write_text(content)


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
        print("\nAvailable domains: ios, macos, visionos, streamdeck, webdev, default")
        sys.exit(1)

    domain = sys.argv[1]
    workspace_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()
    workspace_claude = workspace_path / ".claude"

    # Validate domain
    available_domains = ['ios', 'macos', 'visionos', 'streamdeck', 'webdev', 'default']
    if domain not in available_domains:
        print(f"❌ Error: Invalid domain '{domain}'")
        print(f"   Available domains: {', '.join(available_domains)}")
        sys.exit(1)

    print(f"\n🔍 Initializing workspace: {workspace_path}")
    print(f"📦 Selected domain: {domain}")

    # Check for optional dependencies
    deps = check_dependencies()
    if domain in ['ios', 'macos', 'visionos']:
        print(f"\n🔍 Checking optional dependencies...")
        if not deps['pbxproj']:
            print(f"  ⚠️  pbxproj not installed - Xcode build settings automation will be skipped")
            print(f"     Install with: pip install pbxproj")
        else:
            print(f"  ✓ pbxproj installed - Xcode build settings will be configured")

        if not deps['PIL']:
            print(f"  ⚠️  Pillow not installed - Debug icon generation will be skipped")
            print(f"     Install with: pip install Pillow")
        else:
            print(f"  ✓ Pillow installed - Debug icons will be generated")

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

    # Track configuration state
    config_state = {
        'build_settings_configured': False,
        'debug_icons_generated': False,
        'template_versions': {}
    }

    # Set up comprehensive .gitignore from domain template
    setup_gitignore(workspace_path, library_path, domain)

    # Set up worktree infrastructure (all domains)
    ensure_worktree_infrastructure(workspace_path)

    # Configure Debug/Release build settings for Apple platforms
    build_settings_configured = configure_debug_release_build_settings(workspace_path, domain, deps, workspace_claude)
    config_state['build_settings_configured'] = build_settings_configured

    # Generate debug app icons for Apple platforms
    debug_icons_generated = setup_debug_icons(workspace_path, domain, deps)
    config_state['debug_icons_generated'] = debug_icons_generated

    # Set up DebugLogger, DebugOverlay, and GitInfo for macOS/visionOS projects
    debug_results = setup_debug_logger(domain, workspace_path, library_path)
    if debug_results.get('debug_logger'):
        config_state['template_versions']['DebugLogger'] = '1.0'
    if debug_results.get('debug_overlay'):
        config_state['template_versions']['DebugOverlay'] = '1.0'
    if debug_results.get('git_info'):
        config_state['template_versions']['GitInfo'] = '1.0'

    # Set up Stream Deck debug infrastructure
    if domain == 'streamdeck':
        setup_streamdeck_debug(workspace_path, library_path)

    # Set up webdev debug infrastructure
    if domain == 'webdev':
        setup_webdev_debug(workspace_path, library_path, deps)

    # Set up default debug infrastructure
    if domain == 'default':
        setup_default_debug(workspace_path, library_path)

    # Update CLAUDE.md with debugging documentation
    # Get project name for CLAUDE.md update
    if domain in ['macos', 'visionos']:
        xcode_projects = list(workspace_path.glob('*.xcodeproj'))
        if xcode_projects:
            project_name = xcode_projects[0].stem
            update_claude_md(domain, workspace_path, project_name)

    # Create/update domain marker with configuration state
    print(f"\n✍️  Saving configuration state...")
    create_domain_marker(workspace_claude, domain, config_state)

    # Verify installation
    print(f"\n✅ Verifying installation...")
    if verify_installation(workspace_claude):
        print(f"\n🎉 Workspace initialized successfully with '{domain}' domain!")
        print(f"\n   Configuration files installed to: {workspace_claude}")
        print(f"   You can now use domain-specific commands and agents.")

        # Print configuration summary
        print(f"\n📊 Configuration Summary:")
        if config_state.get('build_settings_configured'):
            print(f"   ✓ Build settings: Configured (Debug/Release separation)")
        if config_state.get('debug_icons_generated'):
            print(f"   ✓ Debug icons: Generated")
        if config_state.get('template_versions'):
            print(f"   ✓ Debug infrastructure: {', '.join(config_state['template_versions'].keys())}")

        # Inform about preserved files
        existing_config = load_domain_config(workspace_claude)
        if existing_config.get('initialized') != existing_config.get('last_updated'):
            print(f"\n   ℹ️  Re-initialization preserved existing customizations")
    else:
        print(f"\n❌ Installation verification failed. Please check the Library folder.")
        sys.exit(1)


if __name__ == "__main__":
    main()