# Documentation References — Azure AD & GitHub CLI

> ⚠️ **PRODUCTION ENVIRONMENT**
> This project manages live Azure AD groups and a GitHub EMU organization.
> Always run `--dry-run` first. Never run destructive commands without verifying scope.
> When in doubt — stop and ask.

---

## Azure AD — Dynamic Groups

### Official Docs
- [Azure AD Dynamic Group Membership Rules](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership)
- [az ad group CLI Reference](https://learn.microsoft.com/en-us/cli/azure/ad/group)
- [Microsoft Graph API — Groups](https://learn.microsoft.com/en-us/graph/api/resources/group)
- [Dynamic Group Rule Syntax](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership#supported-operators)
- [extensionAttribute Reference](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership#extension-attributes-and-custom-extension-properties)

### Corporate SSL Fix (Cato SSL Inspection)

Cato intercepts HTTPS traffic and re-signs with its own Root CA. Azure CLI (Python requests) doesn't trust macOS Keychain automatically.

```bash
# Step 1 — Export Cato Root CA (once)
security find-certificate -a -p -c "Cato Networks Root CA" /Library/Keychains/System.keychain > ~/corp-root-ca.pem

# Step 2 — Build combined CA bundle (system certs + Cato cert)
cat /Library/Frameworks/Python.framework/Versions/3.14/etc/openssl/cert.pem ~/corp-root-ca.pem > /tmp/combined-ca-bundle.pem

# Step 3 — Set env vars before running az commands
export REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem
export SSL_CERT_FILE=/tmp/combined-ca-bundle.pem

# Step 4 — Make permanent in zsh
echo 'export REQUESTS_CA_BUNDLE=/tmp/combined-ca-bundle.pem' >> ~/.zshrc
echo 'export SSL_CERT_FILE=/tmp/combined-ca-bundle.pem' >> ~/.zshrc
```

> The `create-AG-Git-.sh` script builds the combined bundle automatically at startup.

### Key CLI Commands

```bash
# Login (use device code for corporate proxy)
az login --use-device-code

# Verify logged-in account and tenant
az account show

# List all groups matching a pattern
az ad group list --display-name "AG-GitHub-W-" --query "[].{Name:displayName, ID:id}" -o table

# Show a specific group
az ad group show --group "AG-GitHub-W-catod" --query "{Name:displayName, ID:id, Rule:membershipRule}" -o json

# Check group members
az ad group member list --group "AG-GitHub-W-catod" --query "[].{Name:displayName, UPN:userPrincipalName}" -o table

# Delete a group (⚠️ PROD — double check before running)
az ad group delete --group "<object-id>"

# Update dynamic membership rule on existing group
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/groups/<object-id>" \
  --headers "Content-Type=application/json" \
  --body '{
    "membershipRule": "<new-rule>",
    "membershipRuleProcessingState": "On"
  }'

# Check membership rule processing state
az rest --method GET \
  --uri "https://graph.microsoft.com/v1.0/groups/<object-id>?$select=displayName,membershipRule,membershipRuleProcessingState"
```

### Membership Rule Attributes Used in This Project

| Attribute | Values Used | Purpose |
|---|---|---|
| `user.userType` | `Member` | Exclude guest users |
| `user.accountEnabled` | `true` | Active users only |
| `user.department` | `ne null` | Must have a department |
| `user.mail` | `ne null` | Must have an email |
| `user.extensionAttribute4` | Employment type + Team | Auto-membership rule |
| `user.extensionAttribute6` | `eq null` | Exclude offboarded users |
| `user.extensionAttribute7` | Group name | Manual override per user |

---

## GitHub CLI (`gh`)

### Official Docs
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [gh repo commands](https://cli.github.com/manual/gh_repo)
- [gh team commands](https://cli.github.com/manual/gh_team)
- [GitHub REST API — Teams](https://docs.github.com/en/rest/teams/teams)
- [GitHub EMU Documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/about-enterprise-managed-users)
- [IDP Group Sync — GitHub Teams](https://docs.github.com/en/enterprise-cloud@latest/organizations/organizing-members-into-teams/synchronizing-a-team-with-an-identity-provider-group)

### Key CLI Commands

```bash
# Login
gh auth login

# Verify login and org access
gh auth status

# List all repos in org
gh repo list cato-networks-IT --limit 300

# Rename a repo (⚠️ PROD — breaks existing clone URLs)
gh repo rename <new-name> --repo cato-networks-IT/<old-name> --yes

# List all teams in org
gh api orgs/cato-networks-IT/teams --paginate --jq '.[].name'

# Create a team
gh api orgs/cato-networks-IT/teams \
  --method POST \
  --field name="<team-name>" \
  --field description="<description>" \
  --field privacy="closed"

# Link team to IDP group (Azure AD group)
gh api orgs/cato-networks-IT/teams/<team-slug>/team-sync/group-mappings \
  --method PATCH \
  --field groups='[{"group_id":"<azure-group-id>","group_name":"<azure-group-name>","group_description":"<desc>"}]'

# Add team to repo with permission (⚠️ PROD)
gh api orgs/cato-networks-IT/teams/<team-slug>/repos/cato-networks-IT/<repo-name> \
  --method PUT \
  --field permission="push"

# List team repos
gh api orgs/cato-networks-IT/teams/<team-slug>/repos --jq '.[].name'

# List team members
gh api orgs/cato-networks-IT/teams/<team-slug>/members --jq '.[].login'

# Remove team from repo (⚠️ PROD)
gh api orgs/cato-networks-IT/teams/<team-slug>/repos/cato-networks-IT/<repo-name> \
  --method DELETE
```

### GitHub Permission Levels

| Permission | Can Do |
|---|---|
| `pull` | Read only |
| `push` | Read + Write (default for `AG-GitHub-W-*` groups) |
| `maintain` | Manage repo settings (no admin) |
| `admin` | Full control |

---

## Production Safety Rules

> Follow these rules every time when working with this project:

1. **Always dry-run first** — use `--dry-run` flag or `--method GET` before any write operation
2. **Verify tenant before running** — run `az account show` to confirm you are in the correct Azure tenant
3. **Verify org before running** — run `gh auth status` to confirm you are in `cato-networks-IT`
4. **Never bulk-delete** — always delete one resource at a time and verify before proceeding
5. **Check if resource exists first** — use `az ad group show` or `gh api` GET before creating
6. **Keep reports** — every script run generates a CSV report in `reports/` — keep them for audit
7. **Test on 1 group first** — when running a new script, comment out the loop and test on 1 entry
8. **Don't rename repos without communication** — repo renames break existing clone URLs for developers

---

## Project Files Reference

| File | Purpose |
|---|---|
| `Azure Cloud Shell/create groups/create-AG-Git-.sh` | Bulk-create Azure AD dynamic groups from CSV |
| `Azure Cloud Shell/create groups/azure.csv` | Source data: 288 groups with rules |
| `Azure Cloud Shell/create groups/reports/` | Auto-generated CSV reports after each run |
| `Github Migration/migrate_repo_bulk.sh` | Migrate repos from Azure DevOps → GitHub |
| `Github Migration/rename-repos.sh` | Rename repos with `AgenticAi_` prefix |
| `.cursor/commands/context.md` | Full project context and phase overview |
| `.cursor/skills/azure-dynamic-groups/SKILL.md` | AI skill for Azure dynamic groups |
