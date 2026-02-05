#!/bin/bash
set -euo pipefail

git fetch origin main:origin/main
RELEVANT_PATHS_REGEX='^(deployments/cpsi/global/iam/core_github_team/|\.github/workflows/gh-pr\.yml|modules/terraform-github-team/terraform-github-team|stacks/iam/github_team/|ansible-aad/.*\.yaml$)'

MODE="${MODE:-}"
if [[ "$MODE" == "PR" ]]; then
  TRIFILES=$(git diff --name-only origin/main..HEAD)
  echo "Running PR Workflow"
elif [[ "$MODE" == "MAIN" ]]; then
  TRIFILES=$(git diff --name-only HEAD^1..HEAD)
  echo "Running Main Apply Workflow"
fi

echo "Changed files:"
echo "$TRIFILES"
RELEVANT_FILES=$(echo "$TRIFILES" | grep -E "$RELEVANT_PATHS_REGEX" || true)
echo "Relevant files: $RELEVANT_FILES"
if echo "$RELEVANT_FILES" | grep -qvE '^ansible-aad/.*\.yaml$'; then
  echo "only_ansible=false" >> "$GITHUB_OUTPUT"
  echo "Non-ansible files detected. Skipping gh_groups diff"
  echo "gh_groups_changed=false" >> "$GITHUB_OUTPUT"
  exit 0
else
  echo "only_ansible=true" >> "$GITHUB_OUTPUT"
fi

GH_GROUPS_CHANGED=false

GH_FILES=$(echo "$FILES" | grep '^ansible-aad/.*\.yaml$' || true)

echo "gh_files: $GH_FILES"

for FILE in $GH_FILES; do
  echo "Checking gh_groups diff for $FILE"

  git show "origin/main:$FILE" > base.yaml 2>/dev/null || echo "{}" > base.yaml
  cat "$FILE" > head.yaml

  yq e '.gh_groups' base.yaml > base_gh.yaml
  yq e '.gh_groups' head.yaml > head_gh.yaml

  yq e -P 'sort_keys(..)' base_gh.yaml > base_norm.yaml
  yq e -P 'sort_keys(..)' head_gh.yaml > head_norm.yaml

  if ! diff -q base_norm.yaml head_norm.yaml >/dev/null; then
    GH_GROUPS_CHANGED=true
    break
  fi
done
echo "gh_groups_changed=$GH_GROUPS_CHANGED" >> "$GITHUB_OUTPUT"