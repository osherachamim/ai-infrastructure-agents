# Azure AD → GitHub Access Management Automation

> **Owner:** Infrastructure & Cloud Engineering — Cato Networks  
> **Status:** Phase 1 ✅ Complete | Phase 2-4 🚧 Planned

---

## Overview

This project automates the full lifecycle of GitHub organization access management using **Azure AD as the Identity Provider (IDP)**. Instead of managing GitHub access manually, this automation bridges Azure AD dynamic groups with GitHub EMU teams and repository permissions — ensuring access follows the same rules as the organization's identity management.

---

## Problem Statement

Managing GitHub repository access manually is not scalable:
- 288+ repositories migrated from Azure DevOps
- Hundreds of engineers across multiple teams
- Users already have team/employment data in Azure AD (`extensionAttribute4`)
- Manual access = errors, delays, and security gaps

**Solution:** Automate the full flow from Azure AD → GitHub using IDP sync and dynamic group membership rules.

---

## High-Level Architecture

```
Azure AD Users
(extensionAttribute4 = team + employment type)
          │
          ▼
Azure AD Dynamic Security Groups
(AG-GitHub-W-<reponame>)
          │
          ▼
GitHub EMU — SAML/SCIM Sync
          │
          ▼
GitHub Teams (IDP-linked)
          │
          ▼
Repository Permissions (Write)
```

---

## Project Phases

| Phase | Description | Status |
|---|---|---|
| **1** | Create Azure AD Dynamic Groups | ✅ Complete — 288 groups created |
| **2** | GitHub EMU SAML/SCIM Sync | 🚧 Planned |
| **3** | Create GitHub Teams linked to IDP groups | 🚧 Planned |
| **4** | Assign repo permissions to teams | 🚧 Planned |

---

## Phase 1 — Azure AD Dynamic Groups ✅

### What Was Done

Created **288 Azure AD mail-disabled security groups** using a Python script that reads from a CSV file and calls the Microsoft Graph API.

### Group Naming Convention

```
AG-GitHub-W-<reponame>
```

| Part | Meaning |
|---|---|
| `AG` | Azure AD Group |
| `GitHub` | Purpose — GitHub access |
| `W` | Write permission |
| `<reponame>` | Exact GitHub repository name (lowercase) |

**Example:** `AG-GitHub-W-catod` → Write access to the `catod` repository

### Membership Rule Pattern

Each group uses a two-condition OR rule:

```
(Auto-match based on extensionAttribute4 team membership)
OR
(user.extensionAttribute7 -contains "AG-GitHub-W-<reponame>")
```

| Attribute | Purpose |
|---|---|
| `extensionAttribute4` | Employment type + team (auto-membership) |
| `extensionAttribute6` | Offboarding flag — `null` = active employee |
| `extensionAttribute7` | Manual override — set to group name to force-add user |

### Scripts

#### `Azure Cloud Shell/create groups/create-AG-Git-.sh`

Main Python script to bulk-create Azure AD dynamic groups.

**Features:**
- Auto `az login --use-device-code` if not authenticated
- Automatically handles Cato SSL inspection (builds combined CA bundle)
- Reads groups from CSV (handles complex quoted membership rules)
- Creates mail-disabled security groups via Graph API POST
- Applies dynamic membership rule via Graph API PATCH
- Skips groups that already exist (idempotent — safe to re-run)
- Pre-run verification with explicit `--confirm` approval required for PRODUCTION
- `--dry-run` flag to preview all 288 groups without creating anything
- Generates timestamped CSV report after each run
- Final verification — queries Azure AD to confirm every group exists

**Usage:**
```bash
cd "Azure Cloud Shell/create groups"

# Prerequisites — run once
security find-certificate -a -p -c "Cato Networks Root CA" \
  /Library/Keychains/System.keychain > ~/corp-root-ca.pem

# Dry run — no changes
python3 -u create-AG-Git-.sh azure.csv --dry-run

# Real run — PRODUCTION (requires --confirm flag)
python3 -u create-AG-Git-.sh azure.csv --confirm

# Re-run safely — skips existing groups automatically
python3 -u create-AG-Git-.sh azure.csv --confirm
```

**Output example:**
```
✅ Logged in as : Jarvis@catonetworks.com
✅ Tenant ID    : d03fe63f-ee56-4020-a121-dd5b65bc7ea3

PRE-RUN VERIFICATION
  Mode: REAL RUN — will create groups in PRODUCTION

[1/288] AG-GitHub-W-catod
  SKIP — group already exists (ID: xxxx)

[6/288] AG-GitHub-W-platform
  Created — ID: ac30e921-a1ca-4747-82c7-65e8db985b75
  Dynamic rule applied OK

FINAL RESULTS
  Created : 281
  Skipped : 8
  Failed  : 0
  Verified: 288
```

#### `Azure Cloud Shell/create groups/azure.csv`

Source data file with all 288 groups.

| Column | Required | Description |
|---|---|---|
| `GroupName` | ✅ | e.g. `AG-GitHub-W-catod` |
| `MailNickname` | ❌ | Leave empty — script uses GroupName |
| `Description` | ✅ | e.g. `Grants write access to the catod GitHub repository` |
| `MembershipRule` | ✅ | Full Azure AD dynamic rule |

#### `Azure Cloud Shell/create groups/reports/`

Auto-generated CSV reports after each real run, named:
```
groups_report_YYYYMMDD_HHMMSS.csv
```

Columns: `GroupName`, `ObjectId`, `Description`, `Status`, `MembershipRule`

---

## Phase 2 — GitHub EMU SAML/SCIM Sync 🚧

**Planned steps:**
- Configure SCIM provisioning in Azure AD Enterprise App for GitHub EMU
- Azure AD groups (`AG-GitHub-W-*`) become available as IDP groups in GitHub
- Users are auto-provisioned when they match the dynamic membership rule

---

## Phase 3 — GitHub Teams Creation 🚧

**Planned steps:**
- Create GitHub Teams in `cato-networks-IT` org (one per `AG-GitHub-W-*` group)
- Link each team to its corresponding Azure AD IDP group via SCIM
- Members managed automatically — no manual team membership

**Planned script:** `Github Migration/create-github-teams.sh`

---

## Phase 4 — Repository Permissions 🚧

**Planned steps:**
- Assign each GitHub Team **Write** (`push`) permission to its matching repository
- One team → one repository (1:1 mapping via naming convention)
- Permission level: `push` (read + write, create branches)

**Planned script:** `Github Migration/assign-repo-permissions.sh`

---

## Repository Migration

Repositories were migrated from Azure DevOps (`uipathcato/uipath`) to GitHub (`cato-networks-IT`) and renamed with the `AgenticAi_` prefix.

### Scripts

#### `Github Migration/migrate_repo_bulk.sh`

Bulk migrates repositories from Azure DevOps to GitHub.

```bash
export ADO_PAT="your-ado-pat"
export GH_PAT="your-github-pat"
./Github\ Migration/migrate_repo_bulk.sh
```

#### `Github Migration/rename-repos.sh`

Renames all migrated repos to add `AgenticAi_` prefix.

```bash
gh auth login
bash "./Github Migration/rename-repos.sh"
```

**Example:** `catod` → `AgenticAi_catod`

---

## Infrastructure

| Component | Value |
|---|---|
| Azure AD Tenant | Cato Networks |
| GitHub Organization | `cato-networks-IT` |
| GitHub Type | Enterprise Managed Users (EMU) |
| ADO Organization | `uipathcato` |
| ADO Project | `uipath` |
| Auth — Azure | `az login --use-device-code` |
| Auth — GitHub | `gh auth login` / `GH_PAT` env var |

---

## Corporate SSL Inspection (Cato SASE)

Cato Networks SASE platform intercepts ALL outbound HTTPS traffic and re-signs SSL certificates using the Cato Root CA. macOS trusts this CA via Keychain, but Python/CLI tools do not.

**Affected tools:** `az` CLI, `gh` CLI, `curl`, Python `requests`, `pip`

### Fix — One-time setup

```bash
# Step 1 — Export Cato Root CA
security find-certificate -a -p -c "Cato Networks Root CA" \
  /Library/Keychains/System.keychain > ~/corp-root-ca.pem

# Step 2 — Build combined CA bundle
cat /Library/Frameworks/Python.framework/Versions/3.14/etc/openssl/cert.pem \
  ~/corp-root-ca.pem > /tmp/combined-ca-bundle.pem

# Step 3 — Set env vars
export REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem
export SSL_CERT_FILE=/tmp/combined-ca-bundle.pem

# Step 4 — Make permanent
echo 'export REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem' >> ~/.zshrc
echo 'export SSL_CERT_FILE=/tmp/combined-ca-bundle.pem' >> ~/.zshrc
```

> The `create-AG-Git-.sh` script builds the combined bundle automatically at startup — no manual setup required when running through the script.

---

## Production Safety Rules

> This project operates on a **live PRODUCTION** Azure AD tenant and GitHub organization. Follow these rules at all times.

1. **Always dry-run first** — use `--dry-run` before any real execution
2. **Verify tenant** — confirm `az account show` shows the correct tenant before running
3. **Verify org** — confirm `gh auth status` shows `cato-networks-IT` before running
4. **Explicit approval required** — all real runs require `--confirm` flag
5. **Never bulk-delete** — delete one resource at a time and verify
6. **Test on 1 resource first** — for new scripts, test on a single entry before running on all
7. **Keep reports** — all runs generate timestamped CSV reports in `reports/` for audit
8. **Don't rename repos without communication** — breaks existing clone URLs for developers

---

## AI-Assisted Development Setup (Cursor IDE)

This project is built with **Cursor IDE** and uses a structured set of AI context files to make the AI agent aware of the full infrastructure, rules, and project state across every session.

---

### `.cursor/commands/` — AI Context Files

These markdown files are loaded by the AI at the start of each session using slash commands (e.g. `/context`, `/rules`). They eliminate the need to re-explain the project every time.

#### `context.md` — Project Overview
Describes the full project: what it does, why it exists, all 4 phases, key files, and infrastructure details.

**Use it:** `/context` — loads full project understanding into the AI

#### `docs.md` — Reference Documentation
A curated reference of all Azure AD and GitHub CLI commands used in this project, including:
- Corporate SSL fix (Cato SSL inspection)
- `az ad group` commands
- `az rest` Graph API calls
- `gh` CLI commands for teams, IDP sync, repo permissions
- Production safety rules

**Use it:** `/docs` — gives the AI the correct CLI syntax without guessing

#### `rules.md` — Production Safety Rules
Strict rules the AI must follow when working on this project:
- Always dry-run before real execution
- Always verify Azure tenant and GitHub org before running
- Never bulk-delete
- Test on 1 resource before running on all
- Require explicit `YES` / `--confirm` approval before PRODUCTION runs
- Keep all reports for audit

**Use it:** `/rules` — ensures the AI behaves safely on a live production system

#### `memory.md` — Infrastructure Knowledge
Everything the AI needs to know about the environment without being told each session:
- Role: Infrastructure & Cloud Engineer at Cato Networks
- Azure AD extensionAttributes (`ext4`, `ext6`, `ext7`) and their meaning
- Cato SASE SSL inspection and how to fix it for CLI tools
- GitHub EMU — users are IDP-managed, not manually addable
- Device management (Jamf/Intune), automation tools (Workato/UIPath)
- Current project progress and which groups have been created

**Use it:** `/memory` — loads full infrastructure context into the AI

---

### `.cursor/skills/azure-dynamic-groups/` — AI Skill

Skills are specialized instruction files that teach the AI how to perform a specific task. This skill covers everything needed to work with Azure AD dynamic groups in this project.

#### `SKILL.md` — Azure Dynamic Groups Skill

Activated with `/azure-dynamic-groups <instruction>`.

**What it teaches the AI:**
- Prerequisites (az login, Cato SSL fix, Python)
- Correct Graph API commands (NOT `az ad group create` which lacks `--mail-enabled` support)
- Where the production script lives and how to run it
- CSV format and column definitions
- Common membership rule syntax examples
- Error handling tips (403, already exists, P1/P2 requirement)

**Example usage:**
```
/azure-dynamic-groups run dry run
/azure-dynamic-groups run the real script
/azure-dynamic-groups add 5 new groups to the CSV
/azure-dynamic-groups the script failed with error X, help me debug
```

---

### How It All Works Together

```
New chat session
      │
      ▼
/memory    → AI knows your infrastructure, Cato SSL, extensionAttributes
/rules     → AI follows production safety rules
/context   → AI knows all 4 phases and current progress
      │
      ▼
/azure-dynamic-groups run the real script
      │
      ▼
AI reads SKILL.md → knows exact commands, script path, CSV format
      │
      ▼
Shows pre-run verification → waits for YES → runs → shows results
```

This setup means you never have to explain the project twice. Every session starts with full context.

---

## File Structure

```
Azure-GitHub-Sync/
├── README.md                          ← This file
├── .cursor/
│   ├── commands/
│   │   ├── context.md                 ← Full project context & phase overview
│   │   ├── docs.md                    ← Azure AD + GitHub CLI reference docs
│   │   ├── rules.md                   ← Production safety rules for AI
│   │   └── memory.md                  ← Infrastructure knowledge & progress
│   └── skills/
│       └── azure-dynamic-groups/
│           └── SKILL.md               ← AI skill for Azure dynamic groups
│
├── Azure Cloud Shell/
│   └── create groups/
│       ├── create-AG-Git-.sh          ← Main script (Python)
│       ├── azure.csv                  ← 288 groups source data
│       ├── test-1group.csv            ← Single group test file
│       └── reports/                   ← Auto-generated run reports
│
└── Github Migration/
    ├── migrate_repo_bulk.sh           ← ADO → GitHub migration
    ├── migrate-new-repo-bulk.sh       ← New repo migration variant
    ├── rename-repos.sh                ← Add AgenticAi_ prefix
    └── ...
```

---

## Quick Start

```bash
# 1. Clone / open workspace
cd "Azure-GitHub-Sync"

# 2. Login to Azure
az login --use-device-code

# 3. Dry run — verify all 288 groups
cd "Azure Cloud Shell/create groups"
python3 -u create-AG-Git-.sh azure.csv --dry-run

# 4. Real run
python3 -u create-AG-Git-.sh azure.csv --confirm

# 5. Check report
open "reports/groups_report_$(ls reports/ | tail -1)"
```

---

## Run History

| Date | Groups Created | Skipped | Failed | Report |
|---|---|---|---|---|
| 2026-02-26 | 281 | 8 | 0 | `groups_report_20260226_134814.csv` |
| 2026-02-26 (test) | 1 | 0 | 0 | `groups_report_20260226_132454.csv` |
