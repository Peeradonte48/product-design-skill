#!/usr/bin/env bash
#
# install.sh — install the Figma design-to-code skill suite for Claude Code.
#
# Usage:
#   ./install.sh                 # install for the current user (~/.claude/skills)
#   ./install.sh --project       # install into ./.claude/skills (this project only)
#   ./install.sh --dir <path>    # install into a custom skills directory
#   ./install.sh --force         # overwrite existing skills without prompting
#   ./install.sh --uninstall     # remove the seven skills from the target
#
# Remote one-liner (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/Peeradonte48/FIGMA-IMPLEMENT/main/install.sh | bash
#
set -euo pipefail

REPO="Peeradonte48/FIGMA-IMPLEMENT"
BRANCH="main"
TARBALL="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH}"
SKILLS=(
  "implement-figma-design"
  "figjam-to-use-case-narrative"
  "use-case-narrative-to-prototype"
  "figjam-sitemap-to-spec"
  "page-to-figma"
  "harden-doc"
  "biz-review"
)

# --- arg parsing -----------------------------------------------------------
TARGET=""
FORCE=0
UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project)   TARGET="$(pwd)/.claude/skills"; shift ;;
    --dir)       TARGET="${2:?--dir needs a path}"; shift 2 ;;
    --force)     FORCE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[ -n "$TARGET" ] || TARGET="${HOME}/.claude/skills"

say() { printf '  %s\n' "$1"; }

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
  echo "Done."; exit 0
fi

# --- install ---------------------------------------------------------------
echo "Installing Figma skill suite (${MODE}) into: ${TARGET}"
mkdir -p "${TARGET}"

for s in "${SKILLS[@]}"; do
  dest="${TARGET}/${s}"
  if [ ! -d "${SRC}/${s}" ]; then
    say "skip   ${s} (missing in source)"; continue
  fi
  if [ -d "$dest" ] && [ "$FORCE" -ne 1 ]; then
    printf '  %s already exists. Overwrite? [y/N] ' "$s"
    read -r ans </dev/tty || ans="n"
    case "$ans" in [yY]*) ;; *) say "skip   ${s}"; continue ;; esac
  fi
  rm -rf "$dest"; mkdir -p "$dest"
  cp -R "${SRC}/${s}/." "$dest/"
  # Never ship macOS cruft into a user's skills dir.
  find "$dest" -name '.DS_Store' -type f -delete 2>/dev/null || true
  say "installed ${s}"
done

echo
echo "Done. Restart Claude Code (or run /doctor) so it picks up the new skills."
echo "Invoke a skill by sharing a Figma/FigJam link, or type its name, e.g.:"
echo "  implement-figma-design  •  figjam-to-use-case-narrative  •  use-case-narrative-to-prototype  •  figjam-sitemap-to-spec  •  page-to-figma"
echo "Run the two doc-review skills as commands:  /harden-doc <doc>  •  /biz-review <doc>"
