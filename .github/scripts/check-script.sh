#!/bin/bash

# Ensure yq is available (assumed installed in the workflow step)
# Fetch base ref for PR comparison
git fetch origin "${{ github.base_ref }}:${{ github.base_ref }}"

CHANGED=false
# Get list of changed YAML files in the specific path
CHANGED_FILES=$(git diff --name-only "${{ github.base_ref }}".."${{ github.head_ref }}" -- 'ansible-azure-aad/group/all/*.yaml')

for FILE in $CHANGED_FILES; do
  # Extract gh_groups from base ref (fallback to empty if file didn't exist)
  git show "${{ github.base_ref }}:$FILE" > base.yaml 2>/dev/null || echo "{}" > base.yaml
  yq e '.gh_groups' base.yaml > base_gh.yaml
  
  # Extract from head ref
  yq e '.gh_groups' "$FILE" > head_gh.yaml
  
  # Normalize (sort keys to ignore formatting/order changes) and diff
  yq e -P 'sort_keys(..)' base_gh.yaml > base_norm.yaml
  yq e -P 'sort_keys(..)' head_gh.yaml > head_norm.yaml
  
  if ! diff -q base_norm.yaml head_norm.yaml; then
    CHANGED=true
    break  # No need to check further files
  fi
done

# Clean up temp files (optional but good practice)
rm -f base.yaml base_gh.yaml head_gh.yaml base_norm.yaml head_norm.yaml

# Set GitHub output
echo "gh_groups_changed=$CHANGED" >> "$GITHUB_OUTPUT"