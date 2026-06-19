---
description: Update the product-design-skill suite to the latest version
allowed-tools: Bash(curl:*)
---

Run the product-design-skill updater below. It fetches the latest `install.sh`
from GitHub and overwrites only the skills (and commands) that changed in
`~/.claude/`. After it finishes, report the one-line summary it prints, then
remind me to restart Claude Code (or run `/doctor`) so the running session picks
up the updated files.

! curl -fsSL https://raw.githubusercontent.com/Peeradonte48/product-design-skill/main/install.sh | bash -s -- --update
