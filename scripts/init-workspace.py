#!/usr/bin/env python3
"""
Simplified workspace initialization script.
Sets up domain-specific infrastructure (templates, scripts).
Agents, commands, guides, and hooks are now global in ~/.claude/
"""
import json
import os
import re
import shutil
import sys
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional


def detect_domain(workspace_path: Path) -> str:
    """
    Detect the project domain based on file patterns.
    Returns: 'ios', 'macos', 'visionos', 'webdev', 'streamdeck', or 'default'
    """
    # Check for visionOS first (RealityKit content is definitive)
    if list(workspace_path.glob('**/RealityKitContent/**')):
        print(f"  ✓ Found RealityKit content (visionOS)")
        return 'visionos'

    # Check Swift files for visionOS frameworks
    swift_files = list(workspace_path.glob('**/*.swift'))[:10]
    for sf in swift_files:
        try:
            content = sf.read_text()
            if any(fw in content for fw in ['import RealityKit', 'ImmersiveSpace']):
                print(f"  ✓ Found visionOS frameworks")
                return 'visionos'
        except:
            pass

    # Check for Xcode projects
    xcode_projects = list(workspace_path.glob('**/*.xcodeproj'))
    if xcode_projects:
        # Check for macOS vs iOS
        for project in xcode_projects:
            pbxproj = project / 'project.pbxproj'
            if pbxproj.exists():
                try:
                    content = pbxproj.read_text()
                    if 'SDKROOT = macosx' in content or 'MACOSX_DEPLOYMENT_TARGET' in content:
                        print(f"  ✓ Found macOS project")
                        return 'macos'
                    if 'SDKROOT = iphoneos' in content or 'IPHONEOS_DEPLOYMENT_TARGET' in content:
                        print(f"  ✓ Found iOS project")
                        return 'ios'
                except:
                    pass

        # Check Swift files for framework usage
        for sf in swift_files:
            try:
                content = sf.read_text()
                if any(fw in content for fw in ['import AppKit', 'import Cocoa', 'NSWindow']):
                    print(f"  ✓ Found AppKit/Cocoa (macOS)")
                    return 'macos'
                if any(fw in content for fw in ['import UIKit', 'UIViewController']):
                    print(f"  ✓ Found UIKit (iOS)")
                    return 'ios'
            except:
                pass

    # Check for Stream Deck plugin
    if list(workspace_path.glob('**/*.sdPlugin')) or list(workspace_path.glob('**/manifest.json')):
        package_json = workspace_path / 'package.json'
        if package_json.exists():
            try:
                if '@elgato/streamdeck' in package_json.read_text():
                    print(f"  ✓ Found Stream Deck plugin")
                    return 'streamdeck'
            except:
                pass

    # Check for Next.js/React
    nextjs_configs = ['next.config.js', 'next.config.ts', 'next.config.mjs']
    for config in nextjs_configs:
        if (workspace_path / config).exists():
            print(f"  ✓ Found Next.js project")
            return 'webdev'

    package_json = workspace_path / 'package.json'
    if package_json.exists():
        try:
            content = package_json.read_text().lower()
            if 'react' in content or 'next' in content:
                print(f"  ✓ Found React/Next.js in package.json")
                return 'webdev'
        except:
            pass

    print(f"  ℹ No specific domain detected, using default")
    return 'default'


def check_dependencies() -> Dict[str, bool]:
    """Check for optional Python dependencies."""
    deps = {'pbxproj': False, 'PIL': False}
    try:
        import pbxproj
        deps['pbxproj'] = True
    except ImportError:
        pass
    try:
        from PIL import Image
        deps['PIL'] = True
    except ImportError:
        pass
    return deps


def setup_gitignore(workspace_path: Path, library_path: Path):
    """Set up .gitignore from domain template."""
    template = library_path / 'file-templates' / '.gitignore.template'
    gitignore = workspace_path / '.gitignore'

    if not template.exists():
        # Ensure .worktrees is ignored
        if gitignore.exists():
            content = gitignore.read_text()
            if '.worktrees' not in content:
                with gitignore.open('a') as f:
                    f.write('\n.worktrees/\n')
        else:
            gitignore.write_text('.worktrees/\n')
        return

    template_content = template.read_text()
    template_lines = set(l.strip() for l in template_content.splitlines() if l.strip() and not l.startswith('#'))

    if not gitignore.exists():
        gitignore.write_text(template_content)
        print(f"  ✓ Created .gitignore from template")
    else:
        existing = set(l.strip() for l in gitignore.read_text().splitlines() if l.strip() and not l.startswith('#'))
        new_patterns = template_lines - existing
        if new_patterns:
            with gitignore.open('a') as f:
                f.write('\n# Added by /0-workspace\n')
                for line in template_content.splitlines():
                    if line.strip() in new_patterns:
                        f.write(line + '\n')
            print(f"  ✓ Added {len(new_patterns)} patterns to .gitignore")
        else:
            print(f"  ℹ .gitignore already up to date")


def ensure_worktree_infrastructure(workspace_path: Path):
    """Create .worktrees directory."""
    worktrees = workspace_path / '.worktrees'
    worktrees.mkdir(exist_ok=True)
    print(f"  ✓ Ensured .worktrees/ directory")


def setup_domain_infrastructure(workspace_path: Path, domain: str, library_path: Path, deps: Dict[str, bool]):
    """Set up domain-specific infrastructure."""
    print(f"\n🔧 Setting up {domain} infrastructure...")

    if domain in ['ios', 'macos', 'visionos']:
        setup_swift_infrastructure(workspace_path, domain, library_path)
    elif domain == 'webdev':
        setup_webdev_infrastructure(workspace_path, library_path, deps)
    elif domain == 'streamdeck':
        setup_streamdeck_infrastructure(workspace_path, library_path)
    elif domain == 'default':
        setup_default_infrastructure(workspace_path, library_path)


def setup_swift_infrastructure(workspace_path: Path, domain: str, library_path: Path):
    """Set up Swift infrastructure for iOS/macOS/visionOS."""
    # Find project name from Xcode project
    xcode_projects = list(workspace_path.glob('*.xcodeproj'))
    if not xcode_projects:
        print(f"  ℹ No Xcode project found")
        return

    project_name = xcode_projects[0].stem
    project_dir = workspace_path / project_name

    if not project_dir.exists():
        # Try first source directory
        dirs = [d for d in workspace_path.iterdir() if d.is_dir() and not d.name.startswith('.')]
        project_dir = dirs[0] if dirs else workspace_path

    utilities_dir = project_dir / 'Utilities'
    utilities_dir.mkdir(exist_ok=True)

    # Copy templates
    templates = ['DebugOverlay.swift.template', 'GitInfo.swift.template']
    if domain in ['macos', 'visionos']:
        templates.append('DebugLogger.swift.template')

    for template_name in templates:
        template = library_path / 'file-templates' / template_name
        if template.exists():
            dest_name = template_name.replace('.template', '')
            dest = utilities_dir / dest_name
            if not dest.exists():
                content = template.read_text()
                content = content.replace('{{PROJECT_NAME}}', project_name)
                content = content.replace('{{SUBSYSTEM}}', f'com.{project_name.lower()}.debug')
                dest.write_text(content)
                print(f"  ✓ Created {dest_name}")
            else:
                print(f"  ℹ {dest_name} already exists")


def setup_webdev_infrastructure(workspace_path: Path, library_path: Path, deps: Dict[str, bool]):
    """Set up webdev infrastructure."""
    package_json = workspace_path / 'package.json'
    project_name = 'webapp'
    if package_json.exists():
        try:
            project_name = json.loads(package_json.read_text()).get('name', 'webapp')
        except:
            pass

    has_src = (workspace_path / 'src').exists()
    base = workspace_path / 'src' if has_src else workspace_path

    components_dir = base / 'components'
    hooks_dir = base / 'hooks'
    lib_dir = base / 'lib'

    for d in [components_dir, hooks_dir, lib_dir]:
        d.mkdir(parents=True, exist_ok=True)

    templates = [
        ('DebugOverlay.tsx.template', components_dir / 'DebugOverlay.tsx'),
        ('useGitInfo.ts.template', hooks_dir / 'useGitInfo.ts'),
        ('logger.ts.template', lib_dir / 'logger.ts'),
    ]

    for template_name, dest in templates:
        template = library_path / 'file-templates' / template_name
        if template.exists() and not dest.exists():
            content = template.read_text().replace('{{PROJECT_NAME}}', project_name)
            dest.write_text(content)
            print(f"  ✓ Created {dest.name}")


def setup_streamdeck_infrastructure(workspace_path: Path, library_path: Path):
    """Set up Stream Deck infrastructure."""
    package_json = workspace_path / 'package.json'
    plugin_name = 'StreamDeckPlugin'
    if package_json.exists():
        try:
            plugin_name = json.loads(package_json.read_text()).get('name', plugin_name)
        except:
            pass

    src_dir = workspace_path / 'src'
    utils_dir = (src_dir if src_dir.exists() else workspace_path) / 'utils'
    utils_dir.mkdir(exist_ok=True)

    templates = [
        ('DebugLogger.ts.template', 'DebugLogger.ts'),
        ('gitInfo.ts.template', 'gitInfo.ts'),
    ]

    for template_name, dest_name in templates:
        template = library_path / 'file-templates' / template_name
        dest = utils_dir / dest_name
        if template.exists() and not dest.exists():
            content = template.read_text().replace('{{PLUGIN_NAME}}', plugin_name)
            dest.write_text(content)
            print(f"  ✓ Created {dest_name}")


def setup_default_infrastructure(workspace_path: Path, library_path: Path):
    """Set up default (Python) infrastructure."""
    project_name = workspace_path.name
    utils_dir = workspace_path / 'utils'
    utils_dir.mkdir(exist_ok=True)

    templates = [
        ('git_info.py.template', 'git_info.py'),
        ('debug_logger.py.template', 'debug_logger.py'),
    ]

    for template_name, dest_name in templates:
        template = library_path / 'file-templates' / template_name
        dest = utils_dir / dest_name
        if template.exists() and not dest.exists():
            content = template.read_text().replace('{{PROJECT_NAME}}', project_name)
            dest.write_text(content)
            print(f"  ✓ Created {dest_name}")


def save_domain_marker(workspace_claude: Path, domain: str):
    """Save domain.json marker file."""
    domain_file = workspace_claude / 'domain.json'
    data = {
        'domain': domain,
        'initialized': datetime.utcnow().isoformat() + 'Z',
        'last_updated': datetime.utcnow().isoformat() + 'Z',
    }
    domain_file.write_text(json.dumps(data, indent=2))
    print(f"  ✓ Saved domain.json marker")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 init-workspace.py <domain> [workspace_path]")
        print("\nDomains: ios, macos, visionos, streamdeck, webdev, default")
        sys.exit(1)

    domain = sys.argv[1]
    workspace_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.cwd()
    workspace_claude = workspace_path / '.claude'

    valid_domains = ['ios', 'macos', 'visionos', 'streamdeck', 'webdev', 'default']
    if domain not in valid_domains:
        print(f"❌ Invalid domain: {domain}")
        print(f"   Valid: {', '.join(valid_domains)}")
        sys.exit(1)

    print(f"\n🔍 Initializing workspace: {workspace_path}")
    print(f"📦 Domain: {domain}")

    deps = check_dependencies()
    library_path = Path.home() / '.claude' / 'library' / domain

    if not library_path.exists():
        print(f"❌ Library not found: {library_path}")
        sys.exit(1)

    # Create .claude directory
    workspace_claude.mkdir(exist_ok=True)

    # Set up infrastructure
    print(f"\n📝 Setting up infrastructure...")
    setup_gitignore(workspace_path, library_path)
    ensure_worktree_infrastructure(workspace_path)

    # Set up domain-specific infrastructure
    setup_domain_infrastructure(workspace_path, domain, library_path, deps)

    # Save domain marker
    print(f"\n✍️ Saving configuration...")
    save_domain_marker(workspace_claude, domain)

    print(f"\n🎉 Workspace initialized with '{domain}' domain!")
    print(f"\n   Domain infrastructure installed")
    print(f"   Base agents available at ~/.claude/agents/base/")
    print(f"   Workflow commands available at ~/.claude/commands/")


if __name__ == "__main__":
    main()
