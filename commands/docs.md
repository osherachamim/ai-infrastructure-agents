# Documentation References — Azure AD & GitHub CLI
> This project manages live Azure AD groups and a GitHub EMU organization.

---

## Azure AD — Dynamic Groups

### Official Docs
- [Azure AD Dynamic Group Membership Rules](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership)
- [az ad group CLI Reference](https://learn.microsoft.com/en-us/cli/azure/ad/group)
- [Microsoft Graph API — Groups](https://learn.microsoft.com/en-us/graph/api/resources/group)
- [Dynamic Group Rule Syntax](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership#supported-operators)
- [extensionAttribute Reference](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership#extension-attributes-and-custom-extension-properties)

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
3. **Check if resource exists first** — use `az ad group show` or `gh api` GET before creating
---
