# User Information

## Role
- Infrastructure & Cloud Engineer at Cato Networks

## Current Project
- Syncing Azure AD dynamic groups → GitHub EMU organization
- Creating GitHub Teams linked to IDP groups
- Assigning repository permissions to teams
- Full project context: see `.cursor/commands/context.md`

## Environment
- Azure AD Tenant: Cato Networks (corporate proxy — use `az login --use-device-code`)
- GitHub Organization:  (EMU — Enterprise Managed Users)
- Local machine: macOS, zsh shell
- Workspace: `myscript`


## Preferences
- Always explain what a command does before running it
- Always dry-run before real execution — this is PRODUCTION
- Before EVERY real run: show pre-run verification summary and ask for explicit "YES" approval
- Prefer Python scripts over bash when CSV/data parsing is involved
- Keep scripts idempotent and safe to re-run
- Save reports to `reports/` folder with timestamps
- Use `az login --use-device-code` for Azure authentication (corporate proxy)
- Always show logged-in account + tenant ID before running any az command

## Progress So Far
- Phase 1 (Azure AD groups): Script working 
- Phase 2 (SCIM sync): Planned
- Phase 3 (GitHub Teams): Planned
- Phase 4 (Repo permissions): Planned`
