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
- GitHub Organization: `cato-networks-IT` (EMU — Enterprise Managed Users)
- ADO Organization: `uipathcato` / Project: `uipath`
- Local machine: macOS, zsh shell
- Workspace: `/Users/osher.rachamim/Documents/myscriptingwork-main`

## Company Infrastructure (Cato Networks)
- **Network Security**: Cato Networks SASE platform — ALL outbound traffic is routed through Cato
- **SSL Inspection**: Cato intercepts and re-signs HTTPS traffic using its own Root CA ("Cato Networks Root CA")
  - macOS Keychain trusts the Cato Root CA → browsers work fine
  - Python/CLI tools do NOT trust macOS Keychain → must manually configure CA bundle
  - Fix: export Cato cert + combine with system certs → `REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem`
  - Affected tools: `az` CLI, `gh` CLI, `curl`, Python `requests`, `pip`, any HTTP client
- **Identity**: Azure AD (Entra ID) is the IDP — all users managed via extensionAttributes
  - `extensionAttribute4` = employment type + team (used for dynamic group rules)
  - `extensionAttribute6` = offboarding flag (null = active employee)
  - `extensionAttribute7` = manual group override (set to group name to force-add user)
- **GitHub**: Enterprise Managed Users (EMU) — users provisioned via SCIM from Azure AD
  - Users cannot create personal accounts in the org — fully managed by IDP
  - Teams must be linked to Azure AD IDP groups for automatic membership sync
- **Device Management**: Jamf (macOS), Intune (Windows)
- **Automation**: Workato for business automation, UIPath for RPA

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
- Phase 1 (Azure AD groups): Script working ✅ — 1 group test passed in PRODUCTION, ready for full 288 run
  - SSL fix: Cato Root CA exported to ~/corp-root-ca.pem, combined with system certs at /tmp/combined-ca-bundle.pem
  - Script auto-builds the combined CA bundle at startup
  - 4 groups already created manually: AG-GitHub-W-catod, AG-GitHub-W-pbs, AG-GitHub-W-server, AG-GitHub-W-playcato
  - 1 group created by script test: AG-GitHub-W-platform
- Phase 2 (SCIM sync): Planned
- Phase 3 (GitHub Teams): Planned
- Phase 4 (Repo permissions): Planned

## Key Files
- Script: `Azure Cloud Shell/create groups/create-AG-Git-.sh`
- Data: `Azure Cloud Shell/create groups/azure.csv` (288 groups with descriptions)
- Reports: `Azure Cloud Shell/create groups/reports/`
- Skill: `.cursor/skills/azure-dynamic-groups/SKILL.md`
