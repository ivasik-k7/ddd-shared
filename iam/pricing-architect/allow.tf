# Allow policy for the pricing/cost-estimation persona.
# Reads across cost & usage data. Pricing Calculator create is open;
# update/delete/share are gated by aws:PrincipalTag/Persona (ABAC).

data "aws_iam_policy_document" "access" {

  statement {
    sid    = "PricingCalculatorRead"
    effect = "Allow"
    actions = [
      "bcm-pricing-calculator:Get*",
      "bcm-pricing-calculator:List*",
      "bcm-pricing-calculator:Describe*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PricingCalculatorCreate"
    effect = "Allow"
    actions = [
      "bcm-pricing-calculator:CreateBillEstimate",
      "bcm-pricing-calculator:CreateBillScenario",
      "bcm-pricing-calculator:CreateWorkloadEstimate",
    ]
    resources = ["*"]
  }

  # Update / delete / tag-mutation gated by Persona session tag. Tag actions
  # live here (not in Create) so a read+create-only session cannot strip the
  # Owner tag and re-write it — protects any tag-based ownership scheme
  # layered on top later.
  statement {
    sid    = "PricingCalculatorMutate"
    effect = "Allow"
    actions = [
      "bcm-pricing-calculator:BatchUpdate*",
      "bcm-pricing-calculator:Delete*",
      "bcm-pricing-calculator:TagResource",
      "bcm-pricing-calculator:UntagResource",
      "bcm-pricing-calculator:Update*",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/Persona"
      values   = var.write_persona_tag_values
    }
  }

  statement {
    sid    = "PricingAPIRead"
    effect = "Allow"
    actions = [
      "pricing:Describe*",
      "pricing:Get*",
      "pricing:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CostExplorerRead"
    effect = "Allow"
    actions = [
      "ce:Describe*",
      "ce:Get*",
      "ce:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BillingDataExportsRead"
    effect = "Allow"
    actions = [
      "bcm-data-exports:Get*",
      "bcm-data-exports:List*",
      "cur:Describe*",
      "cur:Get*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BudgetsRead"
    effect = "Allow"
    actions = [
      "budgets:Describe*",
      "budgets:View*",
      "budgets:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SavingsPlansRead"
    effect = "Allow"
    actions = [
      "savingsplans:Describe*",
      "savingsplans:Get*",
      "savingsplans:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "OptimizerRead"
    effect = "Allow"
    actions = [
      "compute-optimizer:Describe*",
      "compute-optimizer:Get*",
      "cost-optimization-hub:Get*",
      "cost-optimization-hub:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "TrustedAdvisorCostRead"
    effect = "Allow"
    actions = [
      "support:DescribeTrustedAdvisor*",
      "trustedadvisor:Describe*",
      "trustedadvisor:Get*",
      "trustedadvisor:List*",
    ]
    resources = ["*"]
  }

  # account:GetAccountInformation excluded — returns root email/phone (PII).
  statement {
    sid    = "AccountAndOrgContextRead"
    effect = "Allow"
    actions = [
      "account:GetRegionOptStatus",
      "account:ListRegions",
      "organizations:Describe*",
      "organizations:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "WorkloadDiscoveryRead"
    effect = "Allow"
    actions = [
      "resource-explorer-2:Get*",
      "resource-explorer-2:List*",
      "resource-explorer-2:Search",
      "resource-groups:Get*",
      "resource-groups:List*",
      "resource-groups:Search*",
      "tag:Describe*",
      "tag:Get*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ObservabilityRead"
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Describe*",
      "logs:GetLogGroupFields",
      "logs:ListLogDeliveries",
      "logs:ListTagsForResource",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "BillingConsoleRead"
    effect = "Allow"
    actions = [
      "billing:Get*",
      "billing:List*",
      "consolidatedbilling:Get*",
      "consolidatedbilling:List*",
      "freetier:Get*",
      "invoicing:Get*",
      "invoicing:List*",
      "payments:List*",
      "tax:Get*",
      "tax:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "MarketplaceAndLicenseRead"
    effect = "Allow"
    actions = [
      "aws-marketplace:Describe*",
      "aws-marketplace:Get*",
      "aws-marketplace:List*",
      "aws-marketplace:Search*",
      "aws-marketplace:View*",
      "license-manager:Get*",
      "license-manager:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ServiceQuotasRead"
    effect = "Allow"
    actions = [
      "servicequotas:Get*",
      "servicequotas:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "HealthRead"
    effect = "Allow"
    actions = [
      "health:Describe*",
      "health:Get*",
      "health:List*",
    ]
    resources = ["*"]
  }

  # RAM share — three conditions ANDed: only Pricing Calculator resource
  # types, only sessions tagged with a write-eligible Persona, and never
  # external to the org (AllowExternalPrincipals must be false).
  statement {
    sid    = "ShareEstimatesViaRAM"
    effect = "Allow"
    actions = [
      "ram:AssociateResourceShare",
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare",
      "ram:DisassociateResourceShare",
      "ram:TagResource",
      "ram:UntagResource",
      "ram:UpdateResourceShare",
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ram:RequestedResourceType"
      values   = ["bcm-pricing-calculator:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/Persona"
      values   = var.write_persona_tag_values
    }
    condition {
      test     = "Bool"
      variable = "ram:AllowExternalPrincipals"
      values   = ["false"]
    }
  }

  statement {
    sid    = "RAMRead"
    effect = "Allow"
    actions = [
      "ram:Accept*",
      "ram:Get*",
      "ram:List*",
      "ram:Reject*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SelfIntrospection"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:ListAccountAliases",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "access" {
  name        = "${var.name}Access"
  path        = var.path
  description = "Read across cost & usage; Pricing Calculator create open, update/delete/share gated by Persona session tag; RAM share constrained to in-org."
  policy      = data.aws_iam_policy_document.access.json
  tags        = var.tags
}
