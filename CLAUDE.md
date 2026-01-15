# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform configuration for exporting closed workflow histories from Temporal Cloud to AWS S3. Uses cross-account IAM role assumption where specific Temporal Cloud IAM roles assume a role in your AWS account to write exports.

## Common Commands

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy all resources
terraform destroy

# Format and validate
terraform fmt
terraform validate
```

## Required Environment Variables

```bash
export TF_VAR_temporal_api_key="your-temporal-api-key"
```

## Architecture

The configuration creates three main resources:

1. **S3 Bucket** (`s3.tf`) - Private bucket with versioning for workflow exports
2. **IAM Role** (`iam.tf`) - Role trusting specific Temporal Cloud IAM roles (defined in `temporal_role_arns` variable) with External ID condition using `temporal_external_id`
3. **Export Sink** (`export_sink.tf`) - Temporal Cloud resource configuring hourly exports; uses `data.aws_caller_identity` to get AWS account ID automatically

## Key Variables

Two Temporal identifiers are required (they are different):
- `temporal_account_id` - Account slug (e.g., `sdvdw`) used in namespace ID
- `temporal_external_id` - UUID used in IAM trust policy External ID condition

The namespace ID format is: `{namespace_name}.{temporal_account_id}`

## Provider Versions

- `hashicorp/aws` ~> 5.0
- `temporalio/temporalcloud` ~> 0.1 (currently using 0.9.x)
