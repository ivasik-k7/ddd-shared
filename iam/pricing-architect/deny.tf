# Defence-in-depth Deny boundary. Each block is a risk category. Anything
# here overrides any future Allow from another attached policy.

data "aws_iam_policy_document" "guardrails" {

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Global services (IAM, STS, Organizations, CE, Budgets, Support, Pricing)
  # bind to us-east-1 in aws:RequestedRegion, so keeping that region in
  # allowed_regions is required for the role to work at all.
  statement {
    sid       = "DenyOutOfRegion"
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }

  statement {
    sid    = "DenyIdentityMutation"
    effect = "Deny"
    actions = [
      "iam:Add*", "iam:Attach*", "iam:Create*", "iam:Delete*", "iam:Detach*",
      "iam:Pass*", "iam:Put*", "iam:Remove*", "iam:Set*", "iam:Tag*",
      "iam:Untag*", "iam:Update*", "iam:Upload*",
      "sso:*", "sso-admin:*", "sso-directory:*", "identitystore:*",
      "cognito-idp:*", "cognito-identity:*", "cognito-sync:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyAccountPaymentOrgMutation"
    effect = "Deny"
    actions = [
      "account:Close*", "account:Delete*", "account:Disable*", "account:Enable*",
      "account:Put*", "account:Start*",
      "aws-portal:Modify*",
      "billing:Delete*", "billing:Put*", "billing:Update*",
      "freetier:Put*",
      "invoicing:Put*", "invoicing:Update*", "invoicing:Batch*",
      "payments:Create*", "payments:Delete*", "payments:Update*",
      "purchase-orders:Add*", "purchase-orders:Delete*", "purchase-orders:Update*",
      "tax:BatchPut*", "tax:Delete*", "tax:Put*", "tax:Update*",
      "organizations:Accept*", "organizations:Attach*", "organizations:Cancel*",
      "organizations:Close*", "organizations:Create*", "organizations:Decline*",
      "organizations:Delete*", "organizations:Deregister*", "organizations:Detach*",
      "organizations:Disable*", "organizations:Enable*", "organizations:Invite*",
      "organizations:Leave*", "organizations:Move*", "organizations:Put*",
      "organizations:Register*", "organizations:Remove*", "organizations:Tag*",
      "organizations:Untag*", "organizations:Update*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyCostConfigMutation"
    effect = "Deny"
    actions = [
      "bcm-data-exports:Create*", "bcm-data-exports:Delete*", "bcm-data-exports:Update*",
      "budgets:Create*", "budgets:Delete*", "budgets:Execute*", "budgets:Modify*",
      "ce:Create*", "ce:Delete*", "ce:Update*", "ce:ProvideAnomalyFeedback",
      "cur:DeleteReportDefinition", "cur:ModifyReportDefinition", "cur:PutReportDefinition",
      "cost-optimization-hub:UpdateEnrollmentStatus",
      "compute-optimizer:UpdateEnrollmentStatus",
      "savingsplans:CreateSavingsPlan", "savingsplans:DeleteQueuedSavingsPlan",
      "savingsplans:Return*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyAuditAndSecurityTampering"
    effect = "Deny"
    actions = [
      "access-analyzer:*",
      "cloudtrail:*",
      "config:*",
      "detective:*",
      "guardduty:*",
      "inspector2:*",
      "macie2:*",
      "securityhub:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyKMSAndSecretsMutation"
    effect = "Deny"
    actions = [
      "kms:CancelKeyDeletion", "kms:Create*", "kms:Delete*",
      "kms:Disable*", "kms:Disconnect*", "kms:Put*",
      "kms:Replicate*", "kms:RetireGrant", "kms:RevokeGrant",
      "kms:Schedule*", "kms:Update*",
      "secretsmanager:Cancel*", "secretsmanager:Create*", "secretsmanager:Delete*",
      "secretsmanager:Put*", "secretsmanager:Restore*", "secretsmanager:Rotate*",
      "secretsmanager:Update*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyS3ExposureMutation"
    effect = "Deny"
    actions = [
      "s3:DeleteBucketPolicy",
      "s3:PutAccessPointPolicy", "s3:PutAccountPublicAccessBlock",
      "s3:PutBucketAcl", "s3:PutBucketCORS",
      "s3:PutBucketOwnershipControls", "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock", "s3:PutBucketWebsite",
      "s3:PutMultiRegionAccessPointPolicy",
      "s3:PutObjectAcl", "s3:PutObjectVersionAcl",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyHighCostResourceCreation"
    effect = "Deny"
    actions = [
      "ec2:Allocate*", "ec2:Create*", "ec2:Modify*", "ec2:Purchase*",
      "ec2:Request*", "ec2:Run*", "ec2:Start*",
      "rds:Create*", "rds:Purchase*", "rds:Restore*",
      "redshift:Create*", "redshift:Purchase*", "redshift:Restore*",
      "redshift-serverless:Create*",
      "emr:Create*", "emr:RunJobFlow",
      "elasticache:Create*", "elasticache:Purchase*",
      "es:Create*", "opensearch:Create*",
      "dynamodb:Create*", "dynamodb:Purchase*", "dynamodb:Restore*",
      "kafka:Create*", "msk:Create*",
      "sagemaker:Create*",
      "eks:Create*", "ecs:Create*", "ecs:Run*", "ecs:Start*",
      "lambda:Create*", "lambda:Publish*",
      "elasticfilesystem:Create*", "fsx:Create*",
      "storagegateway:Activate*", "storagegateway:Create*",
      "globalaccelerator:Create*",
      "directconnect:Allocate*", "directconnect:Create*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyOutboundExfilChannels"
    effect = "Deny"
    actions = [
      "ses:Create*", "ses:Send*", "ses:Update*",
      "sns:Create*", "sns:Delete*", "sns:Publish*",
      "sns:Set*", "sns:Subscribe", "sns:TagResource",
      "events:Create*", "events:Delete*", "events:Put*",
      "scheduler:*", "pipes:*", "chatbot:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "guardrails" {
  name        = "${var.name}Guardrails"
  path        = var.path
  description = "Deny boundary: TLS-only; in-region only; blocks identity / account / payment / org mutation, cost-config writes, audit-security tampering, KMS+Secrets destructive ops, S3 exposure changes, high-cost resource creation, and outbound exfil channels."
  policy      = data.aws_iam_policy_document.guardrails.json
  tags        = var.tags
}
