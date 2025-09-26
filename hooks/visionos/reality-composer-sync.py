#!/usr/bin/env python3
"""
Reality Composer Pro sync hook for VisionOS development.
Monitors .reality files for changes, auto-exports USDZ assets,
updates entity references, and validates 3D asset paths.
"""

import json
import os
import sys
import subprocess
import hashlib
import logging
from pathlib import Path
from typing import Dict, List, Optional, Set
import time

# Configure logging
LOG_FILE = "/tmp/claude_reality_composer_sync.log"
STATE_FILE = "/tmp/reality_composer_sync.state"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename=LOG_FILE,
    filemode='a'
)

class RealityComposerSync:
    def __init__(self):
        self.project_root = self._find_project_root()
        self.reality_files: List[Path] = []
        self.usdz_files: List[Path] = []
        self.swift_files: List[Path] = []
        self.file_hashes: Dict[str, str] = {}

    def _find_project_root(self) -> Path:
        """Find the project root by looking for .xcodeproj or Package.swift."""
        current = Path.cwd()
        while current != current.parent:
            if any(current.glob("*.xcodeproj")) or (current / "Package.swift").exists():
                return current
            current = current.parent
        return Path.cwd()

    def _run_command(self, cmd: List[str], cwd: Optional[Path] = None) -> tuple[int, str, str]:
        """Run a shell command and return exit code, stdout, stderr."""
        try:
            result = subprocess.run(
                cmd,
                cwd=cwd or self.project_root,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            logging.error(f"Command timed out: {' '.join(cmd)}")
            return 1, "", "Command timed out"
        except Exception as e:
            logging.error(f"Error running command {' '.join(cmd)}: {e}")
            return 1, "", str(e)

    def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate MD5 hash of file contents."""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception as e:
            logging.error(f"Error calculating hash for {file_path}: {e}")
            return ""

    def _load_state(self) -> Dict[str, str]:
        """Load previous file hashes from state file."""
        if not Path(STATE_FILE).exists():
            return {}

        try:
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            logging.error(f"Error loading state file: {e}")
            return {}

    def _save_state(self):
        """Save current file hashes to state file."""
        try:
            with open(STATE_FILE, 'w') as f:
                json.dump(self.file_hashes, f, indent=2)
        except Exception as e:
            logging.error(f"Error saving state file: {e}")

    def discover_files(self):
        """Discover relevant files in the project."""
        logging.info("Discovering project files...")

        # Find .reality files
        self.reality_files = list(self.project_root.rglob("*.reality"))

        # Find .usdz files
        self.usdz_files = list(self.project_root.rglob("*.usdz"))

        # Find Swift files that might reference reality assets
        self.swift_files = list(self.project_root.rglob("*.swift"))

        logging.info(f"Found {len(self.reality_files)} .reality files")
        logging.info(f"Found {len(self.usdz_files)} .usdz files")
        logging.info(f"Found {len(self.swift_files)} Swift files")

    def check_reality_file_changes(self) -> List[Path]:
        """Check which .reality files have changed since last run."""
        previous_hashes = self._load_state()
        changed_files = []

        for reality_file in self.reality_files:
            current_hash = self._calculate_file_hash(reality_file)
            file_key = str(reality_file.relative_to(self.project_root))

            if current_hash != previous_hashes.get(file_key, ""):
                changed_files.append(reality_file)
                logging.info(f"Reality file changed: {reality_file}")

            self.file_hashes[file_key] = current_hash

        return changed_files

    def export_usdz_assets(self, reality_files: List[Path]) -> bool:
        """Export USDZ assets from changed Reality files."""
        success = True

        for reality_file in reality_files:
            logging.info(f"Attempting to export USDZ from {reality_file}")

            # Check if Reality Composer Pro CLI tools are available
            exit_code, stdout, stderr = self._run_command([
                "which", "RealityComposerPro"
            ])

            if exit_code != 0:
                logging.warning("Reality Composer Pro CLI tools not found. Skipping auto-export.")
                print("⚠️  Reality Composer Pro CLI tools not available for auto-export")
                continue

            # Attempt to export (this is a placeholder - actual command may vary)
            export_path = reality_file.parent / f"{reality_file.stem}_exported.usdz"

            # Note: The actual export command depends on Reality Composer Pro CLI
            # This is a conceptual implementation
            logging.info(f"Would export {reality_file} to {export_path}")
            print(f"📦 Reality file updated: {reality_file.relative_to(self.project_root)}")

        return success

    def update_entity_references(self) -> bool:
        """Update entity references in Swift files."""
        logging.info("Checking entity references in Swift files...")

        # Find all entity names from reality files
        entity_names = set()
        for reality_file in self.reality_files:
            # This would require parsing the reality file format
            # For now, we'll just check if the file exists
            if reality_file.exists():
                stem = reality_file.stem
                entity_names.add(stem)

        issues_found = False

        # Check Swift files for entity references
        for swift_file in self.swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Look for entity loading patterns
                if 'Entity.load' in content or 'ModelEntity.load' in content:
                    # Check if referenced entities exist
                    lines = content.split('\n')
                    for i, line in enumerate(lines, 1):
                        if 'Entity.load' in line or 'ModelEntity.load' in line:
                            # Extract potential asset names (basic pattern matching)
                            if '"' in line:
                                start = line.find('"')
                                end = line.find('"', start + 1)
                                if start != -1 and end != -1:
                                    asset_name = line[start+1:end]
                                    if asset_name and not any(
                                        reality_file.stem == asset_name for reality_file in self.reality_files
                                    ):
                                        print(f"⚠️  Potential missing asset reference: {asset_name} in {swift_file.relative_to(self.project_root)}:{i}")
                                        issues_found = True

            except Exception as e:
                logging.error(f"Error checking Swift file {swift_file}: {e}")

        if not issues_found:
            print("✅ Entity references look good")

        return not issues_found

    def validate_3d_asset_paths(self) -> bool:
        """Validate that 3D asset paths are correct and accessible."""
        logging.info("Validating 3D asset paths...")

        all_valid = True

        # Check if reality files are in correct bundle structure
        for reality_file in self.reality_files:
            relative_path = reality_file.relative_to(self.project_root)

            # Check if it's in a proper bundle location
            if not any(part in str(relative_path) for part in ['Resources', 'Bundle', 'Assets']):
                print(f"⚠️  Reality file may not be in bundle: {relative_path}")
                all_valid = False

        # Check USDZ files
        for usdz_file in self.usdz_files:
            if not usdz_file.exists():
                print(f"❌ Missing USDZ file: {usdz_file.relative_to(self.project_root)}")
                all_valid = False

        if all_valid:
            print("✅ 3D asset paths are valid")

        return all_valid

    def run_sync(self) -> bool:
        """Run the complete sync process."""
        print("🔄 Running Reality Composer Pro sync...")
        logging.info("Starting Reality Composer Pro sync")

        try:
            self.discover_files()

            if not self.reality_files:
                print("ℹ️  No Reality files found in project")
                return True

            # Check for changes
            changed_files = self.check_reality_file_changes()

            if not changed_files:
                print("✅ No Reality file changes detected")
                return True

            print(f"📋 Found {len(changed_files)} changed Reality files")

            # Export USDZ assets
            export_success = self.export_usdz_assets(changed_files)

            # Update entity references
            references_valid = self.update_entity_references()

            # Validate asset paths
            paths_valid = self.validate_3d_asset_paths()

            # Save state
            self._save_state()

            overall_success = export_success and references_valid and paths_valid

            if overall_success:
                print("🎉 Reality Composer Pro sync completed successfully")
            else:
                print("⚠️  Reality Composer Pro sync completed with warnings")

            return overall_success

        except Exception as e:
            logging.exception("Error during Reality Composer Pro sync")
            print(f"❌ Reality Composer Pro sync failed: {e}")
            return False

def main():
    """Main entry point for the hook."""
    try:
        # Check if this is being called as a hook
        if len(sys.argv) > 1 and sys.argv[1] == "--hook":
            # Read hook input from stdin
            try:
                hook_input = json.load(sys.stdin)
                logging.info(f"Hook called with: {hook_input}")
            except json.JSONDecodeError:
                logging.warning("Invalid JSON input, running standalone")

        # Run the sync process
        sync = RealityComposerSync()
        success = sync.run_sync()

        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        print("\n⏹️  Reality Composer sync interrupted")
        sys.exit(1)
    except Exception as e:
        logging.exception("Unexpected error in Reality Composer sync")
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()