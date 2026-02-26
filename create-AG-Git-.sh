#!/usr/bin/env python3
"""
Create Azure AD Dynamic Groups from CSV
Usage: python3 create-AG-Git-.sh azure.csv
       OR: ./create-AG-Git-.sh azure.csv  (if executable)

Requires:
  - az CLI authenticated: az login
  - Azure AD Premium P1 or P2 license
  - Role: Groups Administrator or Global Administrator
"""

import csv
import json
import subprocess
import sys
import os

# ====== CORPORATE SSL FIX (Cato SSL Inspection) ======
_COMBINED_CA = "/tmp/combined-ca-bundle.pem"
if not os.path.exists(_COMBINED_CA):
    _SYSTEM_CA = "/Library/Frameworks/Python.framework/Versions/3.14/etc/openssl/cert.pem"
    _CATO_CA   = os.path.expanduser("~/corp-root-ca.pem")
    if os.path.exists(_SYSTEM_CA) and os.path.exists(_CATO_CA):
        with open(_COMBINED_CA, "w") as _out:
            for _f in [_SYSTEM_CA, _CATO_CA]:
                with open(_f) as _src:
                    _out.write(_src.read())
os.environ["REQUESTS_CA_BUNDLE"] = _COMBINED_CA
os.environ["SSL_CERT_FILE"]      = _COMBINED_CA

# ====== CONFIG ======
CSV_FILE = sys.argv[1] if len(sys.argv) > 1 else "azure.csv"
DRY_RUN  = "--dry-run" in sys.argv   # pass --dry-run to preview without creating
CONFIRM  = "--confirm" in sys.argv   # pass --confirm to approve production run

# ============================


def run_az(args, input_json=None):
    """Run an az CLI command and return (success, output)."""
    cmd = ["az"] + args
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        input=input_json,
        stdin=subprocess.DEVNULL if input_json is None else None
    )
    return result.returncode == 0, result.stdout.strip(), result.stderr.strip()


def group_exists(group_name):
    """Check if a group already exists. Returns object_id or None."""
    ok, out, _ = run_az([
        "ad", "group", "show",
        "--group", group_name,
        "--query", "id",
        "-o", "tsv"
    ])
    return out.strip() if ok and out.strip() else None


def create_group(group_name, mail_nickname, description):
    """Create a mail-disabled security group via Graph API. Returns object_id or None."""
    body = json.dumps({
        "displayName":     group_name,
        "mailNickname":    mail_nickname,
        "description":     description,
        "mailEnabled":     False,
        "securityEnabled": True
    })
    ok, out, err = run_az([
        "rest", "--method", "POST",
        "--uri", "https://graph.microsoft.com/v1.0/groups",
        "--headers", "Content-Type=application/json",
        "--body", body,
        "--query", "id",
        "-o", "tsv"
    ])
    if ok:
        return out.strip()
    print(f"    ERROR creating group: {err}")
    return None


def apply_dynamic_rule(object_id, membership_rule):
    """Patch the group to enable dynamic membership via Graph API."""
    body = json.dumps({
        "groupTypes": ["DynamicMembership"],
        "membershipRule": membership_rule,
        "membershipRuleProcessingState": "On"
    })
    ok, _, err = run_az([
        "rest",
        "--method", "PATCH",
        "--uri", f"https://graph.microsoft.com/v1.0/groups/{object_id}",
        "--headers", "Content-Type=application/json",
        "--body", body
    ])
    if not ok:
        print(f"    ERROR applying dynamic rule: {err}")
    return ok


def check_az_login():
    ok, out, _ = run_az(["account", "show", "--query", "{Tenant:tenantId, Account:user.name, Subscription:name}", "-o", "json"])
    if not ok:
        print("Not logged in to Azure. Running az login --use-device-code ...")
        login_result = subprocess.run(["az", "login", "--use-device-code"], text=True)
        if login_result.returncode != 0:
            print("ERROR: az login failed. Please login manually and retry.")
            sys.exit(1)
        ok, out, _ = run_az(["account", "show", "--query", "{Tenant:tenantId, Account:user.name, Subscription:name}", "-o", "json"])

    if ok and out:
        import json as _json
        info = _json.loads(out)
        print(f"\n  Logged in as : {info.get('Account', 'N/A')}")
        print(f"  Tenant ID    : {info.get('Tenant', 'N/A')}")
        print(f"  Subscription : {info.get('Subscription', 'N/A')}")


def pre_run_approval(csv_file, dry_run, total):
    """Show a summary and ask for explicit approval before running."""
    print("\n" + "=" * 60)
    print("  PRE-RUN VERIFICATION")
    print("=" * 60)
    print(f"  Script       : create-AG-Git-.sh")
    print(f"  CSV file     : {csv_file}")
    print(f"  Total groups : {total}")
    print(f"  Mode         : {'DRY RUN (no changes)' if dry_run else '⚠️  REAL RUN — will create groups in PRODUCTION'}")
    print("=" * 60)

    if dry_run:
        print("\n  Dry run mode — no changes will be made. Proceeding...\n")
        return

    if not CONFIRM:
        print("\n  ⚠️  To run on PRODUCTION, add --confirm flag:")
        print(f"  python3 create-AG-Git-.sh {csv_file} --confirm")
        print("\n  Aborted. Nothing was created.")
        sys.exit(0)

    print("\n  ✅ --confirm flag received. Starting PRODUCTION run...\n")


# ====== MAIN ======
def main():
    if not os.path.exists(CSV_FILE):
        print(f"ERROR: CSV file not found: {CSV_FILE}")
        sys.exit(1)

    check_az_login()

    with open(CSV_FILE, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    total   = len(rows)
    created = 0
    skipped = 0
    failed  = 0

    pre_run_approval(CSV_FILE, DRY_RUN, total)

    print(f"\nAzure AD Dynamic Groups Creator")
    print(f"CSV file     : {CSV_FILE}")
    print(f"Total groups : {total}")
    print(f"Dry run      : {DRY_RUN}")
    print("=" * 60)

    for i, row in enumerate(rows, start=1):
        group_name       = row.get("GroupName", "").strip()
        mail_nickname    = row.get("MailNickname", "").strip() or group_name
        description      = row.get("Description", "").strip() or group_name
        membership_rule  = row.get("MembershipRule", "").strip()

        if not group_name:
            print(f"[{i}/{total}] SKIP — empty GroupName")
            skipped += 1
            continue

        print(f"\n[{i}/{total}] {group_name}")

        if DRY_RUN:
            print(f"  [DRY RUN] Would create group with rule: {membership_rule[:80]}...")
            continue

        # Check if group already exists
        existing_id = group_exists(group_name)
        if existing_id:
            print(f"  SKIP — group already exists (ID: {existing_id})")
            skipped += 1
            continue

        # Create the group
        object_id = create_group(group_name, mail_nickname, description)
        if not object_id:
            print(f"  FAILED — could not create group")
            failed += 1
            continue
        print(f"  Created — ID: {object_id}")

        # Apply dynamic membership rule
        if membership_rule:
            success = apply_dynamic_rule(object_id, membership_rule)
            if success:
                print(f"  Dynamic rule applied OK")
            else:
                print(f"  Dynamic rule FAILED")
                failed += 1
                continue
        else:
            print(f"  WARNING — no membership rule defined, group created as static")

        created += 1

    print("\n" + "=" * 60)
    print(f"Done.")
    print(f"  Created : {created}")
    print(f"  Skipped : {skipped}")
    print(f"  Failed  : {failed}")
    print(f"  Total   : {total}")

    # ====== VERIFICATION + CSV REPORT ======
    if not DRY_RUN and created > 0:
        print("\n" + "=" * 60)
        print("Verifying created groups in Azure AD...")
        print("=" * 60)
        print(f"{'#':<5} {'Group Name':<45} {'Object ID':<38} {'Status':<10} {'Dynamic Rule'}")
        print("-" * 130)

        report_dir  = "/Users/osher.rachamim/Documents/myscriptingwork-main/Azure Cloud Shell/create groups/reports"
        os.makedirs(report_dir, exist_ok=True)
        report_file = os.path.join(report_dir, f"groups_report_{__import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")
        report_rows = []
        found = 0

        for i, row in enumerate(rows, start=1):
            group_name  = row.get("GroupName", "").strip()
            description = row.get("Description", "").strip()
            if not group_name:
                continue

            ok, out, _ = run_az([
                "ad", "group", "show",
                "--group", group_name,
                "--query", "[displayName, id, membershipRule]",
                "-o", "tsv"
            ])
            if ok and out:
                parts       = out.strip().split("\t")
                name        = parts[0] if len(parts) > 0 else "N/A"
                obj_id      = parts[1] if len(parts) > 1 else "N/A"
                rule        = parts[2]  if len(parts) > 2 else "No rule"
                rule_short  = (rule[:60] + "...") if len(rule) > 60 else rule
                status      = "EXISTS"
                print(f"{i:<5} {name:<45} {obj_id:<38} {status:<10} {rule_short}")
                found += 1
                report_rows.append({
                    "GroupName":      name,
                    "ObjectId":       obj_id,
                    "Description":    description,
                    "Status":         status,
                    "MembershipRule": rule
                })
            else:
                print(f"{i:<5} {group_name:<45} {'N/A':<38} {'NOT FOUND':<10}")
                report_rows.append({
                    "GroupName":      group_name,
                    "ObjectId":       "N/A",
                    "Description":    description,
                    "Status":         "NOT FOUND",
                    "MembershipRule": ""
                })

        print("-" * 130)
        print(f"Total groups verified in Azure AD: {found}")

        with open(report_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=["GroupName", "ObjectId", "Description", "Status", "MembershipRule"])
            writer.writeheader()
            writer.writerows(report_rows)

        # ====== FINAL SUMMARY ======
        exists_count   = sum(1 for r in report_rows if r["Status"] == "EXISTS")
        notfound_count = sum(1 for r in report_rows if r["Status"] == "NOT FOUND")

        print(f"\n{'=' * 60}")
        print(f"  FINAL RESULTS")
        print(f"{'=' * 60}")
        print(f"  Groups created this run : {created}")
        print(f"  Groups skipped (existed): {skipped}")
        print(f"  Groups failed           : {failed}")
        print(f"  Groups verified OK      : {exists_count}")
        print(f"  Groups NOT FOUND        : {notfound_count}")
        print(f"{'=' * 60}")
        print(f"\n  Report saved to:")
        print(f"  {report_file}")
        print(f"\n  Open the report to see all group names, Object IDs,")
        print(f"  descriptions, statuses and membership rules.")
        print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
