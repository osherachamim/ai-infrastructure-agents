# Azure AD → GitHub Access Management Automation

> **Owner:** Infrastructure & Cloud Engineering 

---

## Overview

This project automates the full lifecycle of GitHub organization access management using **Azure AD as the Identity Provider (IDP)**. Instead of managing GitHub access manually, this automation bridges Azure AD dynamic groups with GitHub EMU teams and repository permissions — ensuring access follows the same rules as the organization's identity management.

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
- `az ad group` commands
- `az rest` Graph API calls
- `gh` CLI commands for teams, IDP sync, repo permissions
- Production safety rules

**Use it:** `/docs` — gives the AI the correct CLI syntax without guessing

#### `rules.md` — Production Safety Rules
Strict rules the AI must follow when working on this project:
- Always dry-run before real execution
- Always verify Azure tenant and GitHub org before running

**Use it:** `/rules` — ensures the AI behaves safely on a live production system

#### `memory.md` — Infrastructure Knowledge
Everything the AI needs to know about the environment without being told each session:
- Role: Infrastructure & Cloud Engineer
- GitHub EMU — users are IDP-managed, not manually addable
- Current project progress and which groups have been created

**Use it:** `/memory` — loads full infrastructure context into the AI

---

### `.cursor/skills/azure-dynamic-groups/` — AI Skill

Skills are specialized instruction files that teach the AI how to perform a specific task. This skill covers everything needed to work with Azure AD dynamic groups in this project.

#### `SKILL.md` — Azure Dynamic Groups Skill

**What it teaches the AI:**
- Correct Graph API commands (NOT `az ad group create` which lacks `--mail-enabled` support)
- Common membership rule syntax examples

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

## Problem Statement

Managing GitHub repository access manually is not scalable:

**Solution:** Automate the full flow from Azure AD → GitHub using IDP sync and dynamic group membership rules.

---

## High-Level Architecture

```
Azure AD Users
          │
          ▼
Azure AD Dynamic Security Groups
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

## Phase 1 — Azure AD Dynamic Groups ✅

### What Was Done
Created Azure AD mail-disabled security groups** using a Python script that reads from a CSV file and calls the Microsoft Graph API.



### Scripts

Main Python script to bulk-create Azure AD dynamic groups.

**Features:**
- Auto `az login --use-device-code` if not authenticated
- Creates mail-disabled security groups via Graph API POST
- Applies dynamic membership rule via Graph API PATCH
  
---

## Phase 2 — GitHub EMU SAML/SCIM Sync 

**Planned steps:**
- Configure SCIM provisioning in Azure AD Enterprise App for GitHub EMU
- Users are auto-provisioned when they match the dynamic membership rule

---

## Phase 3 — GitHub Teams Creation 

**Planned steps:**
- Create GitHub Teams in org.
- Link each team to its corresponding Azure AD IDP group via SCIM
- Members managed automatically — no manual team membership
---

## Phase 4 — Repository Permissions 

**Planned steps:**
- Assign each GitHub Team **Write** (`push`) permission to its matching repository
- One team → one repository (1:1 mapping via naming convention)
- Permission level: `push` (read + write, create branches)

---
