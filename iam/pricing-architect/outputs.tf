output "role_name" {
  description = "Name of the pricing-architect IAM role."
  value       = aws_iam_role.pricing_architect.name
}

output "role_arn" {
  description = "ARN of the pricing-architect IAM role. Use this as the target of sts:AssumeRole calls or permission-set mappings."
  value       = aws_iam_role.pricing_architect.arn
}

output "role_unique_id" {
  description = "Stable unique ID of the role (use in SCP / RCP conditions that key on principal IDs)."
  value       = aws_iam_role.pricing_architect.unique_id
}

output "access_policy_arn" {
  description = "ARN of the comprehensive access policy attached to the role."
  value       = aws_iam_policy.access.arn
}

output "guardrails_policy_arn" {
  description = "ARN of the defence-in-depth Deny policy attached to the role."
  value       = aws_iam_policy.guardrails.arn
}

output "assume_role_command" {
  description = "Convenience CLI snippet to assume the role for a quick session."
  value       = "aws sts assume-role --role-arn ${aws_iam_role.pricing_architect.arn} --role-session-name pricing-architect-$(date +%Y%m%d-%H%M%S)"
}
