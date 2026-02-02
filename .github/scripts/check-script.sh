#!/bin/bash

# git fetch origin "${{ github.base_ref }}:${{ github.base_ref }}"
git fetch origin main:main

CHANGED=false
RELEVANT_PATHS_REGEX='^(deployments/cpsi/global/iam/core_github_team/|\.github/workflows/gh-team-pr\.yml|modules/terraform-github-team/terraform-github-team|stacks/iam/github_team/|ansible-azure-aad/group/all/.*\.yaml$)'


# CHANGED_FILES=$(git diff --name-only "${{ github.base_ref }}".."${{ github.head_ref }}" -- 'ansible-aad/*.yaml')
CHANGED_FILES=$(git diff --name-only main..HEAD -- 'ansible-aad/*.yaml')
RELEVANT_FILES=$(echo "$FILES" | grep -E "$RELEVANT_PATHS_REGEX" || true)

for FILE in $CHANGED_FILES; do
   git show "main:$FILE" > base.yaml 2>/dev/null || echo "{}" > base.yaml
   yq e '.gh_groups' base.yaml > base_gh.yaml
   

   yq e '.gh_groups' "$FILE" > head_gh.yaml
   
   yq e -P 'sort_keys(..)' base_gh.yaml > base_norm.yaml
   yq e -P 'sort_keys(..)' head_gh.yaml > head_norm.yaml
  
  if ! diff -q base_norm.yaml head_norm.yaml; then
    CHANGED=true
    break  # No need to check further files
  fi
done


rm -f base.yaml base_gh.yaml head_gh.yaml base_norm.yaml head_norm.yaml
echo "gh_groups_changed=$CHANGED" >> "$GITHUB_OUTPUT"