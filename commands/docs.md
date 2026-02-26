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

---

## GitHub CLI (`gh`)

### Official Docs
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [gh repo commands](https://cli.github.com/manual/gh_repo)
- [gh team commands](https://cli.github.com/manual/gh_team)
- [GitHub REST API — Teams](https://docs.github.com/en/rest/teams/teams)
- [GitHub EMU Documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/about-enterprise-managed-users)
- [IDP Group Sync — GitHub Teams](https://docs.github.com/en/enterprise-cloud@latest/organizations/organizing-members-into-teams/synchronizing-a-team-with-an-identity-provider-group)


### GitHub Permission Levels

| Permission | Can Do |
|---|---|
| `pull` | Read only |
| `push` | Read + Write
| `maintain` | Manage repo settings (no admin) |
| `admin` | Full control |

---

## Production Safety Rules

> Follow these rules every time when working with this project:

1. **Always dry-run first** — use `--dry-run` flag or `--method GET` before any write operation
2. **Verify tenant before running** — run `az account show` to confirm you are in the correct Azure tenant
3. **Verify org before running** — run `gh auth status` to confirm you are in ORG
4. **Never bulk-delete** — always delete one resource at a time and verify before proceeding
5. **Check if resource exists first** — use `az ad group show` or `gh api` GET before creating
6. **Test on 1 group first** — when running a new script, comment out the loop and test on 1 entry
---
