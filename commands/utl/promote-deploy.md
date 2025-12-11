Promote a build by incrementing the build number, committing, merging to the next branch, and pushing.

**Version Convention:** `MAJOR.MINOR.PATCH (BUILD)` — e.g., `1.2.3 (42)` or `1.2.3+42`
- **Version** (MAJOR.MINOR.PATCH): Stays the same unless user requests increment
- **Build** number: Auto-increments each promotion

**Usage:**
- `/utl:promote` - Bump build number, merge to next branch
- `/utl:promote --version patch` - Also increment patch version (1.2.3 → 1.2.4)
- `/utl:promote --version minor` - Increment minor version (1.2.3 → 1.3.0)
- `/utl:promote --version major` - Increment major version (1.2.3 → 2.0.0)
- `/utl:promote --deploy` - Also deploy (for Pi/remote projects)

$ARGUMENTS

---

## Phase 1: Project Detection

Detect project type to determine version file location:

```bash
# Check for project markers
ls -la
```

**Detection rules:**
| Marker | Project Type | Version Source |
|--------|--------------|----------------|
| `*.xcodeproj` or `*.xcworkspace` | iOS/macOS/visionOS | Info.plist or project.pbxproj |
| `package.json` | Node/Web/StreamDeck | package.json `version` field |
| `pyproject.toml` | Python (modern) | pyproject.toml `version` field |
| `setup.py` or `setup.cfg` | Python (legacy) | setup.py/cfg version |
| `Cargo.toml` | Rust | Cargo.toml version |
| `version.txt` | Generic | Plain text file |
| None found | No versioning | Skip version bump, proceed with merge |

**For Xcode projects:**
```bash
# Find Info.plist
find . -name "Info.plist" -not -path "*/Pods/*" -not -path "*/.build/*" 2>/dev/null

# Or check project.pbxproj for MARKETING_VERSION and CURRENT_PROJECT_VERSION
grep -l "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" *.xcodeproj/project.pbxproj 2>/dev/null
```

---

## Phase 2: Branch Strategy

**Determine current and target branches:**

```bash
# Current branch
current=$(git rev-parse --abbrev-ref HEAD)

# Check which branches exist
git branch --list main master staging develop development
```

**Promotion paths:**
| Current Branch | Target Branch | Notes |
|----------------|---------------|-------|
| `develop` / `development` | `staging` (if exists) or `main` | Standard dev flow |
| `staging` | `main` / `master` | Pre-release to release |
| `main` / `master` | (none - already at top) | Warn user |
| Feature branch | `develop` (if exists) or `main` | Feature completion |

**If on `main`/`master` with no higher branch:**
```
⚠️ Already on main branch - no promotion target.
Did you mean to create a release tag instead?
```

---

## Phase 3: Version Bump

### Parse Current Version

**For Xcode (project.pbxproj):**
```bash
# Extract current values
grep "MARKETING_VERSION" *.xcodeproj/project.pbxproj | head -1
grep "CURRENT_PROJECT_VERSION" *.xcodeproj/project.pbxproj | head -1
```
- `MARKETING_VERSION` = Version (1.2.3)
- `CURRENT_PROJECT_VERSION` = Build number (42)

**For package.json:**
```bash
grep '"version"' package.json
```
- Format: `"version": "1.2.3"` (build number may be separate or appended)

**For Python:**
```bash
grep -E "^version\s*=" pyproject.toml
# or
grep "__version__" */__init__.py
```

### Increment Build Number

**Default behavior:** Increment build number only
- `1.2.3 (41)` → `1.2.3 (42)`
- Build resets to 1 if version changes

**If `--version` flag provided:**
| Flag | Before | After |
|------|--------|-------|
| `--version patch` | 1.2.3 (41) | 1.2.4 (1) |
| `--version minor` | 1.2.3 (41) | 1.3.0 (1) |
| `--version major` | 1.2.3 (41) | 2.0.0 (1) |

### Apply Changes

**For Xcode:**
```bash
# Update build number in all targets
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $new_build;/g" *.xcodeproj/project.pbxproj

# If version changed
sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = $new_version;/g" *.xcodeproj/project.pbxproj
```

**For package.json:**
Use Edit tool to update the version field.

**For Python:**
Use Edit tool to update version in pyproject.toml or __init__.py.

**If no version file found:**
Skip this phase and proceed directly to merge. Report:
```
ℹ️ No version file detected - proceeding with merge only.
```

---

## Phase 4: Commit & Merge

### Commit Version Bump

**Only if version was changed:**
```bash
git add -A
git commit -m "chore(release): bump build to $new_version ($new_build)"
```

### Merge to Target Branch

```bash
# Fetch latest
git fetch origin

# Switch to target branch
git checkout $target_branch
git pull origin $target_branch

# Merge current branch (no fast-forward to preserve history)
git merge $source_branch --no-ff -m "Merge $source_branch: v$new_version ($new_build)"

# Push both branches
git push origin $target_branch
git checkout $source_branch
git push origin $source_branch
```

**If merge conflicts:**
```
❌ Merge conflict detected!

Conflicting files:
- path/to/file1
- path/to/file2

Please resolve conflicts manually and run /utl:promote again.
```

---

## Phase 5: Deployment (Optional)

**Only runs if `--deploy` flag is present or project is detected as Pi/remote.**

**Pi Detection:**
- `deploy.sh` or `deploy-pi.sh` exists
- `ansible/` directory exists
- `.pi-deploy` config file exists
- `fabric.py` or `fabfile.py` exists

**If deployment detected/requested:**

```bash
# Look for deployment script
if [ -f "./deploy.sh" ]; then
  ./deploy.sh
elif [ -f "./deploy-pi.sh" ]; then
  ./deploy-pi.sh
elif [ -f "fabfile.py" ]; then
  fab deploy
fi
```

**Report:**
```
🚀 Deploying to remote...
[deployment output]
```

---

## Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Build Promoted!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: $old_version → $new_version
Build:   $old_build → $new_build

Branch Flow: $source_branch → $target_branch

Commits pushed:
  • $source_branch (origin)
  • $target_branch (origin)

[If deployed]
🚀 Deployed to remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Edge Cases

**No versioning system:** Proceed with merge only, skip version bump.

**Already up to date:**
```
ℹ️ $target_branch is already up to date with $source_branch.
No promotion needed.
```

**Uncommitted changes:**
```
⚠️ You have uncommitted changes. Please commit or stash them first.
Run /utl:git-commit to commit your changes.
```

**Remote ahead of local:**
```
⚠️ Remote $target_branch has commits not in local.
Pulling latest before merge...
```
