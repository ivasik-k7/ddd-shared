# =============================================================================
# Pricing Architect — IAM role + trust + attachments.
#
# Policy bodies live next door:
#   - allow.tf — Allow policy (cost/pricing/discovery surface).
#   - deny.tf  — Deny boundary (priv-esc, audit tampering, cost-config writes,
#                exfil channels, high-cost resource creation).
# This file is the wiring: who can assume the role, how long the session
# lasts, which policies stick to it.
#
# Three policies attached by default:
#   1. <name>Access              — custom, allow.tf.
#   2. <name>Guardrails          — custom Deny, deny.tf.
#   3. AWS-managed ViewOnlyAccess — cross-service Describe/List, opt-out via var.
# =============================================================================

locals {
  has_iam_trust  = length(var.trusted_principal_arns) > 0
  has_saml_trust = length(var.trusted_saml_provider_arns) > 0
}

# -----------------------------------------------------------------------------
# Trust policy. Split into IAM-principal vs SAML-federation statements on
# purpose: MFA gets enforced on the IAM side only. SAML IdPs do MFA upstream
# and AWS won't see aws:MultiFactorAuthPresent on the federated session, so
# adding the condition there silently locks Identity Center out and you spend
# an afternoon wondering why.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  dynamic "statement" {
    for_each = local.has_iam_trust ? [1] : []
    content {
      sid     = "TrustIAMPrincipals"
      effect  = "Allow"
      actions = ["sts:AssumeRole", "sts:TagSession"]

      principals {
        type        = "AWS"
        identifiers = var.trusted_principal_arns
      }

      # Caller must set the Persona session tag to a valid value. StringEquals
      # against a missing key returns false, so this also enforces "tag present".
      # Downstream Allow uses aws:PrincipalTag/Persona for ABAC on mutating actions.
      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/Persona"
        values   = var.allowed_persona_tag_values
      }

      dynamic "condition" {
        for_each = var.require_mfa ? [1] : []
        content {
          test     = "Bool"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["true"]
        }
      }

      dynamic "condition" {
        for_each = var.external_id == null ? [] : [var.external_id]
        content {
          test     = "StringEquals"
          variable = "sts:ExternalId"
          values   = [condition.value]
        }
      }
    }
  }

  dynamic "statement" {
    for_each = local.has_saml_trust ? [1] : []
    content {
      sid     = "TrustSAMLFederation"
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithSAML", "sts:TagSession"]

      principals {
        type        = "Federated"
        identifiers = var.trusted_saml_provider_arns
      }

      # SAML:aud is always this string for sign-in via the federation endpoint.
      # AWS rejects assertions without it; keeping it explicit makes that
      # visible to the next person reading the policy.
      condition {
        test     = "StringEquals"
        variable = "SAML:aud"
        values   = ["https://signin.aws.amazon.com/saml"]
      }

      # Persona tag from the IdP attribute mapping:
      # https://aws.amazon.com/SAML/Attributes/PrincipalTag:Persona
      condition {
        test     = "StringEquals"
        variable = "aws:RequestTag/Persona"
        values   = var.allowed_persona_tag_values
      }

      # MFA enforced AWS-side, not just IdP-trust. Most modern IdPs (Okta,
      # AzureAD, Identity Center) forward aws:MultiFactorAuthPresent; if yours
      # doesn't, fix it upstream rather than disabling this condition.
      dynamic "condition" {
        for_each = var.require_mfa ? [1] : []
        content {
          test     = "Bool"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["true"]
        }
      }
    }
  }
}

resource "aws_iam_role" "pricing_architect" {
  name               = var.name
  path               = var.path
  description        = "Pricing & cost-estimation work only. Reads across cost/billing/usage, full CRUD on Pricing Calculator estimates, no writes anywhere it matters."
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # 4h default. Cost workshops run long, but past 4h you should be
  # re-authenticating anyway — forces a sanity check that the session is
  # still needed. 12h is the API ceiling; we never use it.
  max_session_duration = var.session_duration_seconds
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "access" {
  role       = aws_iam_role.pricing_architect.name
  policy_arn = aws_iam_policy.access.arn
}

resource "aws_iam_role_policy_attachment" "guardrails" {
  role       = aws_iam_role.pricing_architect.name
  policy_arn = aws_iam_policy.guardrails.arn
}

# AWS-managed ViewOnlyAccess gives Describe/List across the entire service
# catalogue — EC2 instance types, RDS engines, S3 bucket inventory, ECS
# clusters, the lot. Critical for accurate estimates: you can't size an
# RDS Multi-AZ Aurora Serverless v2 without seeing the current config.
# Importantly, ViewOnly *does not* include data-plane reads (s3:GetObject,
# dynamodb:GetItem) — so PII stays out of reach. Off via var for shops that
# layer their own discovery role on top.
resource "aws_iam_role_policy_attachment" "view_only_access" {
  role       = aws_iam_role.pricing_architect.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}
