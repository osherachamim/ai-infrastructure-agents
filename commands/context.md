# Project Context

## Project Overview
This project automates the full lifecycle of GitHub organization access management using Azure AD as the Identity Provider (IDP). The goal is to sync Azure AD dynamic groups to GitHub, create GitHub Teams based on those IDP groups, and assign repository permissions to teams automatically.

## Problem Statement
Managing GitHub access manually is not scalable. Users are already managed in Azure AD with dynamic group membership rules based on attributes (department, team, employment type). This project bridges Azure AD and GitHub so that access to repositories follows the same rules as the organization's identity management.

## High-Level Flow

```
Azure AD Dynamic Groups
        ↓
   GitHub EMU (SAML/SCIM sync)
        ↓
   GitHub Teams (IDP-linked)
        ↓
   Repository Permissions
```

## Phase 1 — Azure AD Dynamic Groups
**Status:** In progress

- Create 288 Azure AD dynamic security groups (`AG-GitHub-W-<reponame>`)
- Groups use `extensionAttribute4` (employment type + team) for auto-membership
- Groups use `extensionAttribute7` for manual override per user
- Groups are mail-disabled security groups (no mailbox)
- Script: `Azure Cloud Shell/create groups/create-AG-Git-.sh`
- Data: `Azure Cloud Shell/create groups/azure.csv`
- Reports: `Azure Cloud Shell/create groups/reports/`

### Group Naming Convention
```
AG-GitHub-W-<reponame>
```
- `AG`  = Azure AD Group
- `GitHub` = Purpose (GitHub access)
- `W`   = Write permission
- `<reponame>` = Exact GitHub repository name (lowercase)

### Membership Rule Pattern
Each group has two membership conditions joined by OR:
1. **Auto-match** — based on `extensionAttribute4` (employment type + team membership)
2. **Manual override** — `extensionAttribute7 -contains "AG-GitHub-W-<reponame>"`

## Phase 2 — GitHub EMU SAML/SCIM Sync
**Status:** Planned

- Azure AD groups are synced to GitHub Enterprise Managed Users (EMU) via SCIM
- Each Azure AD group becomes available as an IDP group in GitHub
- Users provisioned automatically when they match the dynamic rule

## Phase 3 — GitHub Teams Creation
**Status:** Planned

- Create GitHub Teams inside the `cato-networks-IT` organization
- Each team is linked to the corresponding Azure AD IDP group
- Team naming mirrors the Azure AD group name
- Members are managed automatically via IDP sync (no manual team membership)

## Phase 4 — Repository Permissions
**Status:** Planned

- Assign each GitHub Team **Write** permission to its corresponding repository
- One team per repository (matching the `AG-GitHub-W-<reponame>` pattern)
- Permission level: Write (push, pull, create branches)
- Repositories: migrated from Azure DevOps to GitHub (`cato-networks-IT` org)

## Key Files

| File | Purpose |
|---|---|
| `Azure Cloud Shell/create groups/create-AG-Git-.sh` | Script to bulk-create Azure AD dynamic groups |
| `Azure Cloud Shell/create groups/azure.csv` | 288 groups with names, descriptions, and membership rules |
| `Azure Cloud Shell/create groups/reports/` | CSV reports generated after each run |
| `Github Migration/migrate_repo_bulk.sh` | Migrate repos from Azure DevOps to GitHub |
| `Github Migration/rename-repos.sh` | Rename repos with `AgenticAi_` prefix |
| `.cursor/skills/azure-dynamic-groups/SKILL.md` | AI skill for Azure dynamic group scripts |

## Infrastructure

| Component | Value |
|---|---|
| Azure AD Tenant | Cato Networks |
| GitHub Organization | `cato-networks-IT` |
| GitHub Type | Enterprise Managed Users (EMU) |
| Auth to Azure | `az login` (device code for corporate proxy) |
| Auth to GitHub | `gh` CLI with PAT (`GH_PAT`) |
| ADO Organization | `uipathcato` |
| ADO Project | `uipath` |

## Important Notes
- Corporate proxy uses self-signed certificate → use `az login --use-device-code`
- All Azure AD groups are **mail-disabled security groups**
- Dynamic membership requires **Azure AD Premium P1 or P2**
- Script is idempotent — safe to re-run, skips existing groups
- Repository renames use prefix `AgenticAi_` before the original repo name
