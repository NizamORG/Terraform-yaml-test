#!/bin/bash
set -euo pipefail

git fetch origin main:origin/main

FILES=$(git diff --name-only origin/main..HEAD)

echo "Changed files:"
echo "$FILES"

if echo "$FILES" | grep -qvE '^ansible-aad/.*\.yaml$'; then
  echo "only_ansible=false" >> "$GITHUB_OUTPUT"
  echo "Non-ansible files detected. Skipping gh_groups diff."
  echo "gh_groups_changed=false" >> "$GITHUB_OUTPUT"
  exit 0
else
  echo "only_ansible=true" >> "$GITHUB_OUTPUT"
fi

GH_GROUPS_CHANGED=false

YAML_FILES=$(echo "$FILES" | grep '^ansible-aad/.*\.yaml$' || true)

echo "$YAMLFILES"

for FILE in $YAML_FILES; do
  echo "Checking gh_groups diff for $FILE"

  # Base version
  git show "origin/main:$FILE" > base.yaml 2>/dev/null || echo "{}" > base.yaml

  # Head version
  cat "$FILE" > head.yaml

  # Extract gh_groups
  yq e '.gh_groups' base.yaml > base_gh.yaml
  yq e '.gh_groups' head.yaml > head_gh.yaml

  # Normalize (order-independent)
  yq e -P 'sort_keys(..)' base_gh.yaml > base_norm.yaml
  yq e -P 'sort_keys(..)' head_gh.yaml > head_norm.yaml

  if ! diff -q base_norm.yaml head_norm.yaml >/dev/null; then
    GH_GROUPS_CHANGED=true
    break
  fi
done

echo "gh_groups_changed=$GH_GROUPS_CHANGED" >> "$GITHUB_OUTPUT"
