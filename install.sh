#!/usr/bin/env bash
#
# install.sh — install / update the Figma design-to-code skill suite for Claude Code.
#
# Usage:
#   ./install.sh                 # install for the current user (~/.claude/skills)
#   ./install.sh --update        # update installed suite skills to the latest (no prompts)
#   ./install.sh --check         # report installed vs latest version, then exit
#   ./install.sh --project       # install into ./.claude/skills (this project only)
#   ./install.sh --dir <path>    # install into a custom skills directory
#   ./install.sh --force         # overwrite existing skills without prompting
#   ./install.sh --uninstall     # remove the eleven skills from the target
#
# Remote one-liners (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/Peeradonte48/product-design-skill/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --update    # update to the latest
#   curl -fsSL .../install.sh | bash -s -- --check     # check for updates, change nothing
#
set -euo pipefail

REPO="Peeradonte48/product-design-skill"
BRANCH="main"
TARBALL="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH}"
MANIFEST_NAME=".product-design-skill.version"
SKILLS=(
  "implement-figma-design"
  "figjam-to-use-case-narrative"
  "use-case-narrative-to-prototype"
  "figma-design-to-working-prototype"
  "figjam-sitemap-to-spec"
  "page-to-figma"
  "critique-figma-design"
  "verify-design-match"
  "harden-doc"
  "biz-review"
  "spec-to-brief"
)

# --- arg parsing -----------------------------------------------------------
TARGET=""
FORCE=0
UNINSTALL=0
UPDATE=0
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project)   TARGET="$(pwd)/.claude/skills"; shift ;;
    --dir)       TARGET="${2:?--dir needs a path}"; shift 2 ;;
    --force)     FORCE=1; shift ;;
    --update)    UPDATE=1; FORCE=1; shift ;;
    --check)     CHECK=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[ -n "$TARGET" ] || TARGET="${HOME}/.claude/skills"
MANIFEST="${TARGET}/${MANIFEST_NAME}"

say() { printf '  %s\n' "$1"; }
contains() { local n="$1"; shift; local x; for x in "$@"; do [ "$x" = "$n" ] && return 0; done; return 1; }
installed_version() { [ -f "$MANIFEST" ] && (grep '^version=' "$MANIFEST" 2>/dev/null | head -1 | cut -d= -f2-) || true; }

# --- locate the skills/ source ---------------------------------------------
# Use the local checkout if this script sits next to a skills/ dir; otherwise
# download a tarball of the repo and use the skills/ dir inside it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CLEANUP=""
trap '[ -n "$CLEANUP" ] && rm -rf "$CLEANUP"' EXIT

if [ -d "${SCRIPT_DIR}/skills" ]; then
  SRC="${SCRIPT_DIR}/skills"
  MODE="local"
else
  MODE="remote"
  TMP="$(mktemp -d)"
  CLEANUP="$TMP"
  echo "Downloading ${REPO}@${BRANCH}…"
  curl -fsSL "$TARBALL" | tar -xzf - -C "$TMP"
  SRC="$(echo "$TMP"/*/skills)"   # extracted dir is REPO-BRANCH/
  if [ ! -d "$SRC" ]; then
    echo "Could not find skills/ in the downloaded archive." >&2
    exit 1
  fi
fi

# Latest version ships as a VERSION file at the repo root (next to skills/).
LATEST="$(cat "$(dirname "$SRC")/VERSION" 2>/dev/null | head -1 | tr -d '[:space:]' || true)"
[ -n "$LATEST" ] || LATEST="unknown"

# --- check (read-only; report and exit) ------------------------------------
if [ "$CHECK" -eq 1 ]; then
  inst="$(installed_version)"
  echo "product-design-skill — version check (${TARGET})"
  if [ -z "$inst" ]; then
    say "installed: (none detected, or installed before versioning)"
  else
    say "installed: ${inst}"
  fi
  say "latest:    ${LATEST}"
  if [ -n "$inst" ] && [ "$inst" = "$LATEST" ]; then
    say "✓ up to date"
  else
    say "↑ update available — run:"
    say "  curl -fsSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh | bash -s -- --update"
  fi
  exit 0
fi

# --- uninstall -------------------------------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
  echo "Removing skills from: ${TARGET}"
  for s in "${SKILLS[@]}"; do
    if [ -d "${TARGET}/${s}" ]; then
      rm -rf "${TARGET:?}/${s}"; say "removed ${s}"
    else
      say "skip   ${s} (not installed)"
    fi
  done
  [ -f "$MANIFEST" ] && rm -f "$MANIFEST" && say "removed version manifest"
  echo "Done."; exit 0
fi

# --- install / update ------------------------------------------------------
if [ "$UPDATE" -eq 1 ]; then
  echo "Updating Figma skill suite (${MODE}) → ${LATEST}  into: ${TARGET}"
  prev="$(installed_version)"; [ -n "$prev" ] && say "(was ${prev})"
else
  echo "Installing Figma skill suite (${MODE}) → ${LATEST}  into: ${TARGET}"
fi
mkdir -p "${TARGET}"

added=0; updated=0; unchanged=0; removed=0
for s in "${SKILLS[@]}"; do
  src="${SRC}/${s}"; dest="${TARGET}/${s}"
  if [ ! -d "$src" ]; then
    say "skip   ${s} (missing in source)"; continue
  fi
  if [ -d "$dest" ]; then
    if [ "$UPDATE" -eq 1 ]; then
      # only touch skills whose content actually changed
      if diff -rq -x '.DS_Store' "$src" "$dest" >/dev/null 2>&1; then
        say "unchanged ${s}"; unchanged=$((unchanged+1)); continue
      fi
    elif [ "$FORCE" -ne 1 ]; then
      printf '  %s already exists. Overwrite? [y/N] ' "$s"
      read -r ans </dev/tty || ans="n"
      case "$ans" in [yY]*) ;; *) say "skip   ${s}"; continue ;; esac
    fi
    rm -rf "$dest"; mkdir -p "$dest"; cp -R "${src}/." "$dest/"
    find "$dest" -name '.DS_Store' -type f -delete 2>/dev/null || true
    say "updated ${s}"; updated=$((updated+1))
  else
    mkdir -p "$dest"; cp -R "${src}/." "$dest/"
    find "$dest" -name '.DS_Store' -type f -delete 2>/dev/null || true
    say "installed ${s}"; added=$((added+1))
  fi
done

# --- prune skills removed upstream (update only, only ones we installed) ----
if [ "$UPDATE" -eq 1 ] && [ -f "$MANIFEST" ]; then
  old_skills="$(grep '^skills=' "$MANIFEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  for os in $old_skills; do
    if ! contains "$os" "${SKILLS[@]}" && [ -d "${TARGET}/${os}" ]; then
      rm -rf "${TARGET:?}/${os}"; say "removed ${os} (no longer in suite)"; removed=$((removed+1))
    fi
  done
fi

# --- write version manifest ------------------------------------------------
{
  echo "version=${LATEST}"
  echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  echo "skills=${SKILLS[*]}"
} > "$MANIFEST"

echo
if [ "$UPDATE" -eq 1 ]; then
  echo "Updated to ${LATEST}: ${added} added, ${updated} updated, ${unchanged} unchanged, ${removed} removed."
else
  echo "Installed ${LATEST}."
fi
echo "Restart Claude Code (or run /doctor) so it picks up the changes."
echo "Check for updates anytime:  curl -fsSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh | bash -s -- --check"
if [ "$UPDATE" -ne 1 ]; then
  echo "Invoke a skill by sharing a Figma/FigJam link, or type its name, e.g.:"
  echo "  implement-figma-design  •  figjam-to-use-case-narrative  •  use-case-narrative-to-prototype"
  echo "  figma-design-to-working-prototype  •  figjam-sitemap-to-spec  •  page-to-figma  •  spec-to-brief"
  echo "Run the command-only skills:  /critique-figma-design  •  /verify-design-match  •  /harden-doc <doc>  •  /biz-review <doc>"
fi
