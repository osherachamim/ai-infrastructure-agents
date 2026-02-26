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

- Create Azure AD dynamic security groups


## Phase 2 — GitHub EMU SAML/SCIM Sync
**Status:** Planned

- Azure AD groups are synced to GitHub Enterprise Managed Users (EMU) via SCIM
- Each Azure AD group becomes available as an IDP group in GitHub
- Users provisioned automatically when they match the dynamic rule

## Phase 3 — GitHub Teams Creation
**Status:** Planned

- Create GitHub Teams inside the organization
- Each team is linked to the corresponding Azure AD IDP group
- Team naming mirrors the Azure AD group name
- Members are managed automatically via IDP sync (no manual team membership)

## Phase 4 — Repository Permissions
**Status:** Planned

- Assign each GitHub Team **Write** permission to its corresponding repository
- One team per repository
- Permission level: Write (push, pull, create branches)
- Repositories: migrated from Azure DevOps to GitHub

## Key Files

## Important Notes
- Corporate proxy uses self-signed certificate → use `az login --use-device-code`
- All Azure AD groups are **mail-disabled security groups**
- Script is idempotent — safe to re-run, skips existing groups
