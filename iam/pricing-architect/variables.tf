variable "name" {
  description = "Base name for the role and its managed policies. The role is created as <name>, allow-policy as <name>Access, deny-boundary as <name>Guardrails."
  type        = string
  default     = "PricingArchitect"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_+=,.@-]{0,62}$", var.name))
    error_message = "Name must match IAM naming rules (start with letter, 1-63 chars, [A-Za-z0-9_+=,.@-])."
  }
}

variable "path" {
  description = "IAM path for role and policies. Use a custom path (e.g. /finops/) to segregate cost-related principals."
  type        = string
  default     = "/finops/"
}

variable "session_duration_seconds" {
  description = "Max session length for AssumeRole. Cost-projection work often runs across long workshops, so default is 4h."
  type        = number
  default     = 14400

  validation {
    condition     = var.session_duration_seconds >= 3600 && var.session_duration_seconds <= 43200
    error_message = "session_duration_seconds must be between 3600 (1h) and 43200 (12h)."
  }
}

variable "trusted_principal_arns" {
  description = "IAM principal ARNs (users, roles, root of trusted accounts) allowed to assume this role. Leave empty if using only SAML/OIDC trust."
  type        = list(string)
  default     = []
}

variable "trusted_saml_provider_arns" {
  description = "SAML provider ARNs (e.g. IAM Identity Center, Okta, AzureAD) allowed to assume this role via SAML federation."
  type        = list(string)
  default     = []
}

variable "require_mfa" {
  description = "Require MFA on AssumeRole for IAM-principal trust. SAML federation already enforces IdP-side MFA, so the condition is applied only to the IAM-principal statement."
  type        = bool
  default     = true
}

variable "external_id" {
  description = "Optional sts:ExternalId for cross-account assumption (recommended when trusted_principal_arns contains principals from other accounts)."
  type        = string
  default     = null
  sensitive   = true
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary ARN to attach to the role. The module already attaches an explicit deny-policy; a boundary adds a second layer for delegated administration scenarios."
  type        = string
  default     = null
}

variable "allowed_regions" {
  description = "Regions in which the role may operate. Denied elsewhere via aws:RequestedRegion. Must include us-east-1 because global services (IAM, STS, Organizations, CE, Budgets, Pricing, Support) bind to it."
  type        = list(string)
  default     = ["us-east-1", "us-east-2", "eu-west-1", "eu-central-1", "ap-south-1"]

  validation {
    condition     = contains(var.allowed_regions, "us-east-1")
    error_message = "allowed_regions must include us-east-1 — global services (IAM, STS, Organizations, CE, Budgets) resolve there and the role breaks without it."
  }
}

variable "allowed_persona_tag_values" {
  description = "Full set of valid values for the Persona session tag. The trust policy rejects AssumeRole calls that do not set aws:RequestTag/Persona to one of these. Use this to define the personas allowed to assume the role at all."
  type        = list(string)
  default     = ["Architect", "FinOpsPractitioner", "Analyst", "AccountManager", "Junior"]
}

variable "write_persona_tag_values" {
  description = "Subset of allowed_persona_tag_values whose sessions may perform mutating actions (Pricing Calculator update/delete + tag, RAM share). Everyone else gets read + create-only. Each value must also be in allowed_persona_tag_values."
  type        = list(string)
  default     = ["Architect", "FinOpsPractitioner"]

  validation {
    condition     = length(var.write_persona_tag_values) > 0
    error_message = "write_persona_tag_values must be non-empty — at least one persona needs to be able to maintain estimates."
  }
}

variable "tags" {
  description = "Tags applied to the role and customer-managed policies."
  type        = map(string)
  default = {
    Purpose   = "PricingAndCostEstimation"
    ManagedBy = "Terraform"
  }
}
