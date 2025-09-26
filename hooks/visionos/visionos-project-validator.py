#!/usr/bin/env python3
"""
VisionOS project validation hook.
Verifies Info.plist spatial requirements, checks entitlements for VisionOS features,
validates minimum deployment target, and ensures proper framework linkage.
"""

import json
import os
import sys
import plistlib
import logging
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Any

# Configure logging
LOG_FILE = "/tmp/claude_visionos_validator.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename=LOG_FILE,
    filemode='a'
)

class VisionOSProjectValidator:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.validation_errors: List[Dict] = []
        self.validation_warnings: List[Dict] = []
        self.validation_info: List[Dict] = []

        # VisionOS requirements
        self.min_deployment_target = "1.0"
        self.required_frameworks = {
            'RealityKit', 'ARKit', 'SwiftUI'
        }
        self.recommended_frameworks = {
            'AVFoundation', 'CoreHaptics', 'Spatial'
        }

    def _find_project_root(self) -> Path:
        """Find the project root by looking for .xcodeproj or Package.swift."""
        current = Path.cwd()
        while current != current.parent:
            if any(current.glob("*.xcodeproj")) or (current / "Package.swift").exists():
                return current
            current = current.parent
        return Path.cwd()

    def _find_info_plist(self) -> Optional[Path]:
        """Find the main Info.plist file."""
        # Common Info.plist locations
        possible_paths = [
            self.project_root / "Info.plist",
            *self.project_root.rglob("**/Info.plist"),
        ]

        # Filter out test and framework Info.plists
        for path in possible_paths:
            if path.exists() and not any(
                exclude in str(path).lower()
                for exclude in ['test', 'framework', '.framework', 'pods', 'carthage']
            ):
                return path
        return None

    def _find_entitlements_file(self) -> Optional[Path]:
        """Find the entitlements file."""
        entitlement_files = list(self.project_root.rglob("*.entitlements"))
        return entitlement_files[0] if entitlement_files else None

    def _read_plist(self, plist_path: Path) -> Optional[Dict]:
        """Read and parse a plist file."""
        try:
            with open(plist_path, 'rb') as f:
                return plistlib.load(f)
        except Exception as e:
            logging.error(f"Error reading plist {plist_path}: {e}")
            return None

    def _find_project_file(self) -> Optional[Path]:
        """Find the .xcodeproj file."""
        xcodeproj_files = list(self.project_root.glob("*.xcodeproj"))
        return xcodeproj_files[0] if xcodeproj_files else None

    def _find_package_swift(self) -> Optional[Path]:
        """Find Package.swift file."""
        package_file = self.project_root / "Package.swift"
        return package_file if package_file.exists() else None

    def validate_info_plist_spatial_requirements(self) -> bool:
        """Validate Info.plist for spatial requirements."""
        print("📋 Validating Info.plist spatial requirements...")

        info_plist = self._find_info_plist()
        if not info_plist:
            self.validation_errors.append({
                'file': 'Info.plist',
                'issue': 'Info.plist not found',
                'severity': 'error',
                'suggestion': 'Create Info.plist with VisionOS spatial requirements'
            })
            return False

        plist_data = self._read_plist(info_plist)
        if not plist_data:
            self.validation_errors.append({
                'file': str(info_plist.relative_to(self.project_root)),
                'issue': 'Could not read Info.plist',
                'severity': 'error'
            })
            return False

        # Check for VisionOS-specific keys
        required_keys = {
            'UIApplicationSupportsMultipleScenes': True,
            'UISceneConfigurations': 'required for VisionOS scenes'
        }

        recommended_keys = {
            'NSCameraUsageDescription': 'Required for spatial tracking',
            'NSLocationWhenInUseUsageDescription': 'May be needed for world tracking',
        }

        # Check required keys
        for key, expected in required_keys.items():
            if key not in plist_data:
                self.validation_errors.append({
                    'file': str(info_plist.relative_to(self.project_root)),
                    'issue': f'Missing required key: {key}',
                    'severity': 'error',
                    'suggestion': f'Add {key} = {expected}'
                })

        # Check recommended keys
        for key, purpose in recommended_keys.items():
            if key not in plist_data:
                self.validation_warnings.append({
                    'file': str(info_plist.relative_to(self.project_root)),
                    'issue': f'Missing recommended key: {key}',
                    'severity': 'warning',
                    'suggestion': f'Consider adding {key} - {purpose}'
                })

        # Check for VisionOS scene configuration
        if 'UISceneConfigurations' in plist_data:
            scene_config = plist_data['UISceneConfigurations']
            if isinstance(scene_config, dict):
                # Look for WindowGroup or ImmersiveSpace configurations
                has_spatial_scenes = False
                for config_type, configs in scene_config.items():
                    if isinstance(configs, list):
                        for config in configs:
                            if isinstance(config, dict):
                                class_name = config.get('UISceneClassName', '')
                                if 'WindowGroup' in class_name or 'ImmersiveSpace' in class_name:
                                    has_spatial_scenes = True

                if not has_spatial_scenes:
                    self.validation_warnings.append({
                        'file': str(info_plist.relative_to(self.project_root)),
                        'issue': 'No spatial scene configurations detected',
                        'severity': 'warning',
                        'suggestion': 'Configure WindowGroup or ImmersiveSpace scenes'
                    })

        return len([e for e in self.validation_errors if e.get('file') == str(info_plist.relative_to(self.project_root))]) == 0

    def validate_entitlements(self) -> bool:
        """Check entitlements for VisionOS features."""
        print("🔐 Validating VisionOS entitlements...")

        entitlements_file = self._find_entitlements_file()
        if not entitlements_file:
            self.validation_warnings.append({
                'file': 'Entitlements',
                'issue': 'No entitlements file found',
                'severity': 'warning',
                'suggestion': 'Create entitlements file for VisionOS capabilities'
            })
            return True  # Not required, but recommended

        entitlements = self._read_plist(entitlements_file)
        if not entitlements:
            self.validation_errors.append({
                'file': str(entitlements_file.relative_to(self.project_root)),
                'issue': 'Could not read entitlements file',
                'severity': 'error'
            })
            return False

        # VisionOS-specific entitlements
        visionos_entitlements = {
            'com.apple.developer.arkit': 'Required for spatial tracking',
            'com.apple.developer.reality-composer-pro': 'Required for Reality Composer Pro assets',
        }

        optional_entitlements = {
            'com.apple.developer.networking.wifi-info': 'May be needed for network-based spatial features',
            'com.apple.developer.location.when-in-use': 'Required for location-based spatial experiences',
        }

        # Check for VisionOS entitlements
        for entitlement, purpose in visionos_entitlements.items():
            if entitlement not in entitlements:
                self.validation_warnings.append({
                    'file': str(entitlements_file.relative_to(self.project_root)),
                    'issue': f'Missing entitlement: {entitlement}',
                    'severity': 'warning',
                    'suggestion': f'Add {entitlement} - {purpose}'
                })

        # Check for optional entitlements usage
        for entitlement, purpose in optional_entitlements.items():
            if entitlement in entitlements:
                self.validation_info.append({
                    'file': str(entitlements_file.relative_to(self.project_root)),
                    'issue': f'Using optional entitlement: {entitlement}',
                    'severity': 'info',
                    'note': purpose
                })

        return True

    def validate_deployment_target(self) -> bool:
        """Validate minimum deployment target for VisionOS."""
        print("🎯 Validating deployment target...")

        # Check Package.swift for SPM projects
        package_swift = self._find_package_swift()
        if package_swift:
            return self._validate_package_swift_target(package_swift)

        # Check Xcode project
        project_file = self._find_project_file()
        if project_file:
            return self._validate_xcode_project_target(project_file)

        self.validation_warnings.append({
            'file': 'Project Configuration',
            'issue': 'Could not find project configuration files',
            'severity': 'warning',
            'suggestion': 'Ensure Package.swift or .xcodeproj exists'
        })
        return True

    def _validate_package_swift_target(self, package_file: Path) -> bool:
        """Validate deployment target in Package.swift."""
        try:
            with open(package_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Look for platforms specification
            platforms_match = re.search(r'platforms:\s*\[(.*?)\]', content, re.DOTALL)
            if platforms_match:
                platforms_content = platforms_match.group(1)

                # Check for visionOS platform
                visionos_match = re.search(r'\.visionOS\(["\']?(\d+\.\d+)["\']?\)', platforms_content)
                if visionos_match:
                    version = visionos_match.group(1)
                    if self._compare_versions(version, self.min_deployment_target) < 0:
                        self.validation_errors.append({
                            'file': str(package_file.relative_to(self.project_root)),
                            'issue': f'VisionOS deployment target {version} below minimum {self.min_deployment_target}',
                            'severity': 'error',
                            'suggestion': f'Update to .visionOS("{self.min_deployment_target}") or higher'
                        })
                        return False
                    else:
                        self.validation_info.append({
                            'file': str(package_file.relative_to(self.project_root)),
                            'issue': f'VisionOS deployment target: {version}',
                            'severity': 'info'
                        })
                else:
                    self.validation_warnings.append({
                        'file': str(package_file.relative_to(self.project_root)),
                        'issue': 'VisionOS platform not specified',
                        'severity': 'warning',
                        'suggestion': f'Add .visionOS("{self.min_deployment_target}") to platforms'
                    })
            else:
                self.validation_warnings.append({
                    'file': str(package_file.relative_to(self.project_root)),
                    'issue': 'No platforms specified',
                    'severity': 'warning',
                    'suggestion': 'Add platforms array with VisionOS support'
                })

        except Exception as e:
            logging.error(f"Error reading Package.swift: {e}")
            self.validation_errors.append({
                'file': str(package_file.relative_to(self.project_root)),
                'issue': f'Error reading Package.swift: {e}',
                'severity': 'error'
            })
            return False

        return True

    def _validate_xcode_project_target(self, project_file: Path) -> bool:
        """Validate deployment target in Xcode project."""
        # This would require parsing .xcodeproj/project.pbxproj
        # For now, we'll just check if the file exists
        pbxproj_file = project_file / "project.pbxproj"
        if pbxproj_file.exists():
            self.validation_info.append({
                'file': str(project_file.relative_to(self.project_root)),
                'issue': 'Xcode project found - manually verify VisionOS deployment target',
                'severity': 'info',
                'suggestion': f'Ensure XROS_DEPLOYMENT_TARGET >= {self.min_deployment_target}'
            })
        return True

    def _compare_versions(self, v1: str, v2: str) -> int:
        """Compare two version strings. Returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2."""
        def version_tuple(v):
            return tuple(map(int, (v.split("."))))

        v1_tuple = version_tuple(v1)
        v2_tuple = version_tuple(v2)

        if v1_tuple < v2_tuple:
            return -1
        elif v1_tuple > v2_tuple:
            return 1
        else:
            return 0

    def validate_framework_linkage(self) -> bool:
        """Ensure proper framework linkage for VisionOS."""
        print("🔗 Validating framework linkage...")

        # Check Package.swift dependencies
        package_swift = self._find_package_swift()
        if package_swift:
            return self._validate_package_dependencies(package_swift)

        # For Xcode projects, check import statements in Swift files
        return self._validate_swift_imports()

    def _validate_package_dependencies(self, package_file: Path) -> bool:
        """Validate dependencies in Package.swift."""
        try:
            with open(package_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check for VisionOS frameworks in dependencies or targets
            has_realitykit = 'RealityKit' in content
            has_arkit = 'ARKit' in content
            has_swiftui = 'SwiftUI' in content

            if not has_realitykit:
                self.validation_warnings.append({
                    'file': str(package_file.relative_to(self.project_root)),
                    'issue': 'RealityKit not found in Package.swift',
                    'severity': 'warning',
                    'suggestion': 'Add RealityKit framework for spatial rendering'
                })

            if not has_arkit:
                self.validation_warnings.append({
                    'file': str(package_file.relative_to(self.project_root)),
                    'issue': 'ARKit not found in Package.swift',
                    'severity': 'warning',
                    'suggestion': 'Add ARKit framework for spatial tracking'
                })

        except Exception as e:
            logging.error(f"Error validating Package.swift dependencies: {e}")
            return False

        return True

    def _validate_swift_imports(self) -> bool:
        """Validate framework imports in Swift files."""
        swift_files = list(self.project_root.rglob("*.swift"))

        if not swift_files:
            return True

        all_imports = set()
        files_with_spatial_code = []

        # Analyze imports and spatial code usage
        for swift_file in swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Extract imports
                imports = re.findall(r'import\s+(\w+)', content)
                all_imports.update(imports)

                # Check for spatial code patterns
                spatial_patterns = [
                    r'RealityView', r'ImmersiveSpace', r'WindowGroup.*immersive',
                    r'Entity', r'ModelEntity', r'ARSession', r'WorldTrackingProvider'
                ]

                if any(re.search(pattern, content) for pattern in spatial_patterns):
                    files_with_spatial_code.append(swift_file)

            except Exception as e:
                logging.error(f"Error analyzing Swift file {swift_file}: {e}")

        # Check if required frameworks are imported when spatial code is present
        if files_with_spatial_code:
            missing_frameworks = self.required_frameworks - all_imports

            for framework in missing_frameworks:
                self.validation_warnings.append({
                    'file': 'Swift Files',
                    'issue': f'Missing import {framework} but spatial code detected',
                    'severity': 'warning',
                    'suggestion': f'Add "import {framework}" to relevant Swift files'
                })

            # Report on recommended frameworks
            present_recommended = self.recommended_frameworks & all_imports
            if present_recommended:
                self.validation_info.append({
                    'file': 'Swift Files',
                    'issue': f'Using recommended frameworks: {", ".join(present_recommended)}',
                    'severity': 'info'
                })

        return True

    def generate_validation_report(self) -> str:
        """Generate a validation report."""
        all_issues = self.validation_errors + self.validation_warnings + self.validation_info

        if not all_issues:
            return "✅ VisionOS project validation passed with no issues"

        errors = self.validation_errors
        warnings = self.validation_warnings
        info_items = self.validation_info

        report_lines = []

        if errors:
            report_lines.append(f"❌ {len(errors)} validation errors:")
            for error in errors:
                report_lines.append(f"   {error['file']} - {error['issue']}")
                if error.get('suggestion'):
                    report_lines.append(f"      💡 {error['suggestion']}")

        if warnings:
            report_lines.append(f"⚠️  {len(warnings)} validation warnings:")
            for warning in warnings:
                report_lines.append(f"   {warning['file']} - {warning['issue']}")
                if warning.get('suggestion'):
                    report_lines.append(f"      💡 {warning['suggestion']}")

        if info_items:
            report_lines.append(f"ℹ️  {len(info_items)} validation info:")
            for info in info_items:
                report_lines.append(f"   {info['file']} - {info['issue']}")

        return "\n".join(report_lines)

    def run_validation(self) -> bool:
        """Run the complete VisionOS project validation."""
        print("🔍 Running VisionOS project validation...")
        logging.info("Starting VisionOS project validation")

        try:
            # Run all validation checks
            plist_valid = self.validate_info_plist_spatial_requirements()
            entitlements_valid = self.validate_entitlements()
            target_valid = self.validate_deployment_target()
            frameworks_valid = self.validate_framework_linkage()

            # Generate and print report
            report = self.generate_validation_report()
            print("\n📊 VisionOS Project Validation Report:")
            print(report)

            # Overall success if no errors
            has_errors = len(self.validation_errors) > 0
            overall_success = not has_errors

            if overall_success:
                print("\n🎉 VisionOS project validation completed successfully")
            else:
                print("\n⚠️  VisionOS project validation found errors that need to be fixed")

            return overall_success

        except Exception as e:
            logging.exception("Error during VisionOS project validation")
            print(f"❌ VisionOS project validation failed: {e}")
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

        # Run the validation
        validator = VisionOSProjectValidator()
        success = validator.run_validation()

        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        print("\n⏹️  VisionOS project validation interrupted")
        sys.exit(1)
    except Exception as e:
        logging.exception("Unexpected error in VisionOS project validation")
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()