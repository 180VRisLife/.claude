#!/usr/bin/env python3
"""
Spatial performance validation hook for VisionOS development.
Checks for expensive 3D operations, validates texture sizes,
monitors entity counts, and checks for memory leaks in spatial contexts.
"""

import json
import os
import sys
import re
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Set
import subprocess

# Configure logging
LOG_FILE = "/tmp/claude_spatial_performance.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename=LOG_FILE,
    filemode='a'
)

class SpatialPerformanceChecker:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.swift_files: List[Path] = []
        self.asset_files: List[Path] = []
        self.performance_issues: List[Dict] = []
        self.warnings: List[str] = []

        # Performance thresholds
        self.max_entities_per_scene = 1000
        self.max_texture_size_mb = 4.0
        self.max_polygon_count = 100000

    def _find_project_root(self) -> Path:
        """Find the project root by looking for .xcodeproj or Package.swift."""
        current = Path.cwd()
        while current != current.parent:
            if any(current.glob("*.xcodeproj")) or (current / "Package.swift").exists():
                return current
            current = current.parent
        return Path.cwd()

    def _get_file_size_mb(self, file_path: Path) -> float:
        """Get file size in megabytes."""
        try:
            return file_path.stat().st_size / (1024 * 1024)
        except Exception as e:
            logging.error(f"Error getting file size for {file_path}: {e}")
            return 0.0

    def discover_files(self):
        """Discover relevant files in the project."""
        logging.info("Discovering project files for performance analysis...")

        # Find Swift files
        self.swift_files = list(self.project_root.rglob("*.swift"))

        # Find asset files
        asset_extensions = ['.reality', '.usdz', '.jpg', '.jpeg', '.png', '.heic', '.hdr']
        self.asset_files = []
        for ext in asset_extensions:
            self.asset_files.extend(self.project_root.rglob(f"*{ext}"))

        logging.info(f"Found {len(self.swift_files)} Swift files")
        logging.info(f"Found {len(self.asset_files)} asset files")

    def check_expensive_operations(self) -> List[Dict]:
        """Check for expensive 3D operations in Swift code."""
        print("🔍 Checking for expensive 3D operations...")

        expensive_patterns = [
            (r'\.raycast\(', 'Raycast operations can be expensive'),
            (r'\.physics\.', 'Physics calculations can impact performance'),
            (r'Timer\.scheduledTimer|Timer\.publish', 'High-frequency timers can cause performance issues'),
            (r'\.onReceive.*Timer', 'Timer-based updates should be optimized'),
            (r'forEach.*Entity', 'Entity iteration in loops can be expensive'),
            (r'\.children\.forEach', 'Child entity iteration should be minimized'),
            (r'\.scene\.anchors\.forEach', 'Anchor iteration can be costly'),
            (r'updateEntity.*every', 'Frequent entity updates should be batched'),
        ]

        expensive_operations = []

        for swift_file in self.swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                for i, line in enumerate(lines, 1):
                    for pattern, message in expensive_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            expensive_operations.append({
                                'file': swift_file.relative_to(self.project_root),
                                'line': i,
                                'code': line.strip(),
                                'issue': message,
                                'severity': 'warning'
                            })

            except Exception as e:
                logging.error(f"Error analyzing {swift_file}: {e}")

        return expensive_operations

    def validate_texture_sizes(self) -> List[Dict]:
        """Validate texture sizes for performance."""
        print("🖼️  Validating texture sizes...")

        texture_issues = []
        image_extensions = {'.jpg', '.jpeg', '.png', '.heic', '.hdr'}

        for asset_file in self.asset_files:
            if asset_file.suffix.lower() in image_extensions:
                file_size_mb = self._get_file_size_mb(asset_file)

                if file_size_mb > self.max_texture_size_mb:
                    texture_issues.append({
                        'file': asset_file.relative_to(self.project_root),
                        'size_mb': round(file_size_mb, 2),
                        'max_size_mb': self.max_texture_size_mb,
                        'issue': f'Texture size {file_size_mb:.1f}MB exceeds recommended {self.max_texture_size_mb}MB',
                        'severity': 'warning' if file_size_mb < self.max_texture_size_mb * 2 else 'error'
                    })

        return texture_issues

    def monitor_entity_counts(self) -> List[Dict]:
        """Monitor entity counts in Swift code."""
        print("🎯 Monitoring entity counts...")

        entity_issues = []
        entity_creation_patterns = [
            r'ModelEntity\(',
            r'Entity\(\)',
            r'\.load.*Entity',
            r'Entity\.load',
            r'addChild\(',
            r'scene\.addAnchor',
        ]

        for swift_file in self.swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                entity_count = 0
                loop_entity_creation = False

                for i, line in enumerate(lines, 1):
                    # Check for entity creation in loops
                    if re.search(r'for\s+.*in|while|forEach', line, re.IGNORECASE):
                        # Check next few lines for entity creation
                        for j in range(i, min(i + 10, len(lines))):
                            if j < len(lines):
                                for pattern in entity_creation_patterns:
                                    if re.search(pattern, lines[j], re.IGNORECASE):
                                        loop_entity_creation = True
                                        entity_issues.append({
                                            'file': swift_file.relative_to(self.project_root),
                                            'line': j + 1,
                                            'code': lines[j].strip(),
                                            'issue': 'Entity creation inside loop can cause performance issues',
                                            'severity': 'warning'
                                        })
                                        break

                    # Count potential entity creations
                    for pattern in entity_creation_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            entity_count += 1

                # Warn if too many entities in single file
                if entity_count > 50:
                    entity_issues.append({
                        'file': swift_file.relative_to(self.project_root),
                        'line': 1,
                        'code': f'~{entity_count} entity operations detected',
                        'issue': f'High entity count ({entity_count}) may impact performance',
                        'severity': 'info'
                    })

            except Exception as e:
                logging.error(f"Error analyzing entity counts in {swift_file}: {e}")

        return entity_issues

    def check_memory_leaks(self) -> List[Dict]:
        """Check for potential memory leaks in spatial contexts."""
        print("🧠 Checking for potential memory leaks...")

        memory_issues = []
        leak_patterns = [
            (r'\.observe\(.*\)', 'Observation without proper cleanup can cause leaks'),
            (r'NotificationCenter\..*addObserver', 'NotificationCenter observers should be removed'),
            (r'Timer\..*repeats:\s*true', 'Repeating timers should be invalidated'),
            (r'@State.*Entity', 'Storing entities in @State can cause memory issues'),
            (r'@StateObject.*Session', 'Session objects should be properly managed'),
            (r'strong self', 'Strong self references can create retain cycles'),
            (r'\.sink\(', 'Combine sinks should store cancellables'),
        ]

        for swift_file in self.swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')

                # Check for proper cleanup methods
                has_cleanup = any(
                    re.search(r'deinit|onDisappear|\.onReceive.*\.cancel|removeObserver|invalidate', line)
                    for line in lines
                )

                for i, line in enumerate(lines, 1):
                    for pattern, message in leak_patterns:
                        if re.search(pattern, line, re.IGNORECASE):
                            severity = 'warning'
                            if not has_cleanup and any(word in pattern for word in ['observe', 'addObserver', 'Timer']):
                                severity = 'error'

                            memory_issues.append({
                                'file': swift_file.relative_to(self.project_root),
                                'line': i,
                                'code': line.strip(),
                                'issue': message,
                                'severity': severity,
                                'suggestion': 'Ensure proper cleanup in deinit or onDisappear'
                            })

            except Exception as e:
                logging.error(f"Error checking memory leaks in {swift_file}: {e}")

        return memory_issues

    def analyze_project_structure(self) -> List[Dict]:
        """Analyze overall project structure for performance implications."""
        print("🏗️  Analyzing project structure...")

        structure_issues = []

        # Check for too many reality files
        reality_files = [f for f in self.asset_files if f.suffix == '.reality']
        if len(reality_files) > 10:
            structure_issues.append({
                'file': Path('Project Structure'),
                'line': 1,
                'code': f'{len(reality_files)} reality files',
                'issue': f'Large number of reality files ({len(reality_files)}) may impact loading performance',
                'severity': 'info',
                'suggestion': 'Consider consolidating reality files or lazy loading'
            })

        # Check total asset size
        total_asset_size = sum(self._get_file_size_mb(f) for f in self.asset_files)
        if total_asset_size > 50:  # 50MB threshold
            structure_issues.append({
                'file': Path('Project Assets'),
                'line': 1,
                'code': f'{total_asset_size:.1f}MB total assets',
                'issue': f'Large asset bundle ({total_asset_size:.1f}MB) may impact app launch time',
                'severity': 'warning',
                'suggestion': 'Consider asset optimization or streaming'
            })

        return structure_issues

    def generate_report(self, all_issues: List[Dict]) -> str:
        """Generate a performance report."""
        if not all_issues:
            return "✅ No spatial performance issues detected"

        # Group issues by severity
        errors = [issue for issue in all_issues if issue.get('severity') == 'error']
        warnings = [issue for issue in all_issues if issue.get('severity') == 'warning']
        info = [issue for issue in all_issues if issue.get('severity') == 'info']

        report_lines = []

        if errors:
            report_lines.append(f"❌ {len(errors)} performance errors:")
            for issue in errors[:5]:  # Show first 5 errors
                report_lines.append(f"   {issue['file']}:{issue['line']} - {issue['issue']}")

        if warnings:
            report_lines.append(f"⚠️  {len(warnings)} performance warnings:")
            for issue in warnings[:3]:  # Show first 3 warnings
                report_lines.append(f"   {issue['file']}:{issue['line']} - {issue['issue']}")

        if info:
            report_lines.append(f"ℹ️  {len(info)} performance suggestions:")
            for issue in info[:2]:  # Show first 2 info items
                report_lines.append(f"   {issue['file']}:{issue['line']} - {issue['issue']}")

        return "\n".join(report_lines)

    def run_performance_check(self) -> bool:
        """Run the complete performance check."""
        print("⚡ Running spatial performance analysis...")
        logging.info("Starting spatial performance check")

        try:
            self.discover_files()

            if not self.swift_files:
                print("ℹ️  No Swift files found in project")
                return True

            all_issues = []

            # Run all checks
            all_issues.extend(self.check_expensive_operations())
            all_issues.extend(self.validate_texture_sizes())
            all_issues.extend(self.monitor_entity_counts())
            all_issues.extend(self.check_memory_leaks())
            all_issues.extend(self.analyze_project_structure())

            # Generate and print report
            report = self.generate_report(all_issues)
            print("\n📊 Spatial Performance Report:")
            print(report)

            # Return True if no errors, False if there are errors
            has_errors = any(issue.get('severity') == 'error' for issue in all_issues)

            if not has_errors:
                print("\n🎉 Spatial performance check completed successfully")
                return True
            else:
                print("\n⚠️  Spatial performance check found issues that need attention")
                return False

        except Exception as e:
            logging.exception("Error during spatial performance check")
            print(f"❌ Spatial performance check failed: {e}")
            return False

def main():
    """Main entry point for the hook."""
    try:
        # Check if this is being called as a hook
        if len(sys.argv) > 1 and sys.argv[1] == "--hook":
            try:
                hook_input = json.load(sys.stdin)
                logging.info(f"Hook called with: {hook_input}")
            except json.JSONDecodeError:
                logging.warning("Invalid JSON input, running standalone")

        # Run the performance check
        checker = SpatialPerformanceChecker()
        success = checker.run_performance_check()

        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        print("\n⏹️  Spatial performance check interrupted")
        sys.exit(1)
    except Exception as e:
        logging.exception("Unexpected error in spatial performance check")
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()