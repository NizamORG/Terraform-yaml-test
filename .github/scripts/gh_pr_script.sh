#!/bin/bash
set -euo pipefail
git fetch origin main:origin/main
triggerred_paths='^(deployments/cpsi/global/iam/core_github_team/|\.github/workflows/gh-team-pr\.yml|\.github/workflows/gh-team-apply\.yml|modules/terraform-github-team/terraform-github-team|stacks/iam/github_team/|ansible-aad/.*\.yaml$)'

MODE="${MODE:-}"
if [[ "$MODE" == "PR" ]]; then
 diff_Files=$(git diff --name-only origin/main..HEAD)
 var="origin/main"
elif [[ "$MODE" == "MAIN" ]]; then
 diff_Files=$(git diff --name-only HEAD^1..HEAD)
 var="HEAD~1"
fi
echo "var:$var"
echo "diff:$diff_Files"
relevant_files=$(echo "$diff_Files" | grep -E "$triggerred_paths" || true)
echo "relevant: $relevant
if echo "$relevant_files" | grep -qvE '^ansible-azure-aad/group_vars/all/.*\.yaml$'; then
  echo "only_ansible=false" >> "$GITHUB_OUTPUT"
  echo "gh_groups_changed=false" >> "$GITHUB_OUTPUT"
  exit 0
else
 echo "only_ansible=true" >> "$GITHUB_OUTPUT"
 gh_grp_changed=false
 gh_files=$(echo "$relevant_files" | grep '^ansible-azure-aad/group_vars/all/.*\.yaml$' || true)

 for file in $gh_files; do
  git show "$var:$file" 2>/dev/null | yq e '.gh_groups | sort_keys(..)' - > base.yaml || echo "{}" > base.yaml
  yq e '.gh_groups | sort_keys(..)' "$file" > head.yaml
  echo "base"
  cat base.yaml
  echo "head"
  cat head.yaml
  if ! diff -q base.yaml head.yaml >/dev/null; then
   gh_grp_changed=true
   break
  fi
 done
 echo "gh_groups_changed=$gh_grp_changed"
 echo "gh_groups_changed=$gh_grp_changed" >> "$GITHUB_OUTPUT"
fi
