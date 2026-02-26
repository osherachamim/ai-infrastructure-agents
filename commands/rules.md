# Project Rules

## Rules
- Always run `--dry-run` first before any real execution
- Always run `az account show` to verify the correct Azure tenant before any `az` command
- Always run `gh auth status` to verify org before any `gh` command
- Never bulk-delete resources — delete one at a time and verify
- Test new scripts on 1 resource first before running on all

## AI Behavior Rules
- Only use information from actual files in this project — never invent code or configs
- Always read the file before editing it
- Verify file paths exist before referencing them
- When unsure — ask, don't guess
- Base all suggestions on existing patterns in the codebase
- State clearly when something is not found rather than making it up

## Scripting Rules
- Never hardcode secrets, tokens, or passwords — use environment variables
- Always add `set -euo pipefail` in bash scripts
- Always add login check at the start of scripts (`az account show` / `gh auth status`)
- Always add a `--dry-run` flag to any bulk-operation script

## Azure AD Rules
- All groups follow naming convention
- Groups must be mail-disabled security groups
- Dynamic membership requires Azure AD Premium P1 or P2
- Use `az login --use-device-code` for corporate proxy environments
- Always verify group was created with `az ad group show` after creation

## GitHub Rules
- Teams must be linked to Azure AD IDP groups for SCIM sync
- Default repo permission for  groups is `push` (Write)
- Use `gh api` for team and IDP group operations (not supported by `gh team` directly)
