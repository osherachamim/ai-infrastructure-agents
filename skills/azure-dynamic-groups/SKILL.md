---
name: azure-dynamic-groups
description: Create Azure AD dynamic groups using bash and az CLI. Handles reading group definitions from Excel or CSV files, building membership rules, and bulk-creating groups via az CLI. Use when the user asks about Azure dynamic groups, AAD groups, creating groups from Excel/spreadsheet data, or Azure Cloud Shell group scripts.
---

# Azure Dynamic Groups via CursorAI Agent

## Prerequisites

- `az` CLI installed and authenticated (`az login --use-device-code`)
- For Excel input: convert to CSV first (save as CSV from Excel), or use Python to parse
- **Corporate SSL fix required** — Cato SSL inspection intercepts HTTPS traffic:
  ```bash
  # Export Cato Root CA once
  security find-certificate -a -p -c "Cato Networks Root CA" /Library/Keychains/System.keychain > ~/corp-root-ca.pem
  # Set env vars before running any az command
  export REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem
  export SSL_CERT_FILE=/tmp/combined-ca-bundle.pem
  ```
  The script handles this automatically by building `/tmp/combined-ca-bundle.pem` at startup.

## Core Commands

**Create mail-disabled security group via Graph API** (`az ad group create` does NOT support `--mail-enabled`/`--security-enabled` in newer CLI versions):
```bash
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/groups" \
  --headers "Content-Type=application/json" \
  --body '{
    "displayName": "GROUP_NAME",
    "mailNickname": "MAIL_NICKNAME",
    "description": "DESCRIPTION",
    "mailEnabled": false,
    "securityEnabled": true
  }'
```

**Apply dynamic membership rule after creation:**
```bash
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/groups/{GROUP_OBJECT_ID}" \
  --headers "Content-Type=application/json" \
  --body '{
    "groupTypes": ["DynamicMembership"],
    "membershipRule": "MEMBERSHIP_RULE",
    "membershipRuleProcessingState": "On"
  }'
```

## Production Script

The real script lives at:
```
Azure Cloud Shell/create groups/create-AG-Git-.sh
```

It is a Python script (runs in Azure Cloud Shell where Python 3 is always available).

**Features:**
- Auto `az login` if not already authenticated
- Reads CSV with Python parser (handles complex quoted membership rules)
- Creates mail-disabled security groups (`--mail-enabled false --security-enabled true`)
- Patches dynamic membership rule via Graph API (`az rest`)
- Skips groups that already exist (safe to re-run)
- `--dry-run` flag to preview without creating anything
- Summary report: Created / Skipped / Failed

**Run:**
```bash
# Navigate to the script folder first
cd "/Users/osher.rachamim/Documents/myscriptingwork-main/Azure Cloud Shell/create groups"

# Dry run first
python3 create-AG-Git-.sh azure.csv --dry-run

# Real run
python3 create-AG-Git-.sh azure.csv
```

> In Azure Cloud Shell, upload both files to the same folder and run from there.

**CSV columns:**
```
GroupName, MailNickname (optional), Description, MembershipRule
```
- `MailNickname` — leave empty, script uses GroupName automatically
- `MembershipRule` — full Azure AD dynamic rule with extensionAttribute conditions

## CSV Format

```csv
GroupName,MailNickname,Description,MembershipRule
AG-GitHub-Developers,AG-GitHub-Developers,GitHub Developers group,(user.department -eq "R&D")
AG-GitHub-DevOps,AG-GitHub-DevOps,DevOps team,(user.jobTitle -contains "DevOps")
```

## Converting Excel to CSV

If the user has an `.xlsx` file, convert it to CSV:
- In Excel: File → Save As → CSV (Comma delimited)
- Or via Python (if needed): `python3 -c "import pandas as pd; pd.read_excel('Book1.xlsx').to_csv('groups.csv', index=False)"`

## Common Membership Rule Examples

| Use Case | Rule |
|---|---|
| By department | `(user.department -eq "Engineering")` |
| By job title contains | `(user.jobTitle -contains "Developer")` |
| By country | `(user.country -eq "IL")` |
| By group member | `(user.memberOf -any (group.objectId -in ["<group-id>"]))` |
| By email domain | `(user.mail -endsWith "@company.com")` |
| Combined (AND) | `(user.department -eq "IT") -and (user.country -eq "IL")` |

## Error Handling Tips

- If `az ad group create` fails with "already exists" → use `az ad group show --group "$GROUP_NAME"` to get the existing ID
- If Graph PATCH fails with 403 → ensure the logged-in account has `Groups Administrator` or `Global Administrator` role
- Dynamic membership requires **Azure AD Premium P1 or P2**

## File Naming Convention (project pattern)

Based on existing scripts in this workspace:
- Use descriptive names: `create-AG-<team>-<purpose>.sh`
- Example: `create-AG-Git-Developers.sh`, `create-AG-DevOps-Teams.sh`
