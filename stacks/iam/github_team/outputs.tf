output "github_team_id" {
  description = "A key value pair of the ID of the created team."
  value       = module.github_team.github_team_id
}

output "github_team_node_id" {
  description = "A key value pair of the Node ID of the created team."
  value       = module.github_team.github_team_node_id
}

output "github_team_slug" {
  description = "A key value pair of the slug of the created team, which may or may not differ from name, depending on whether name contains URL-unsafe characters. Useful when referencing the team in github_branch_protection."
  value       = module.github_team.github_team_slug
}