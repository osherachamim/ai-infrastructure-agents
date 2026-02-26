---
name: azure-dynamic-groups
description: Create Azure AD dynamic groups using bash and az CLI. Handles reading group definitions from Excel or CSV files, building membership rules, and bulk-creating groups via az CLI. Use when the user asks about Azure dynamic groups, AAD groups, creating groups from Excel/spreadsheet data, or Azure Cloud Shell group scripts.
---

# Azure Dynamic Groups via CursorAI Agent

## Prerequisites

- `az` CLI installed and authenticated (`az login --use-device-code`)
- For Excel input: convert to CSV first (save as CSV from Excel), or use Python to parse



**Features:**
- Auto `az login` if not already authenticated
- Reads CSV with Python parser (handles complex quoted membership rules)
- Creates mail-disabled security groups (`--mail-enabled false --security-enabled true`)
- Patches dynamic membership rule via Graph API (`az rest`)
- Skips groups that already exist (safe to re-run)
- `--dry-run` flag to preview without creating anything
- Summary report: Created / Skipped / Failed


## Converting Excel to CSV

If the user has an `.xlsx` file, convert it to CSV:
- In Excel: File → Save As → CSV (Comma delimited)
- Or via Python (if needed): `python3 -c "import pandas as pd; pd.read_excel('Book1.xlsx').to_csv('groups.csv', index=False)"`

## Error Handling Tips

- If `az ad group create` fails with "already exists" → use `az ad group show --group "$GROUP_NAME"` to get the existing ID
- If Graph PATCH fails with 403 → ensure the logged-in account has `Groups Administrator` or `Global Administrator` role
- Dynamic membership requires **Azure AD Premium P1 or P2**

