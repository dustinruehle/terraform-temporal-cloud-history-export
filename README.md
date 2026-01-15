# Temporal Cloud Namespace Export Sink - Terraform Setup

Export closed workflow histories from Temporal Cloud to AWS S3 using Terraform.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Where to Find Configuration Values](#where-to-find-configuration-values)
- [Configuration Reference](#configuration-reference)
- [Understanding Temporal IDs](#understanding-temporal-ids)
- [Verification](#verification)
- [Exported Data Format](#exported-data-format)
- [Cost Considerations](#cost-considerations)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [References](#references)

---

## Overview

### What is a Namespace Export Sink?

A Namespace Export Sink continuously exports closed workflow histories from a Temporal Cloud namespace to your own cloud storage (AWS S3 or GCS). This enables:

- **Compliance & Auditing** — Retain workflow history beyond the 90-day Temporal Cloud limit
- **Analytics** — Query workflow data in your data warehouse
- **Long-term Storage** — Archive workflow histories for regulatory requirements

### How Often Does It Run?

| Aspect | Detail |
|--------|--------|
| Frequency | **Hourly** |
| Schedule | Runs 10 minutes after each hour |
| Delay | Up to 24 hours for a closed workflow to appear |
| Guarantee | At least once delivery (dedupe by `runID`) |

Once configured, exports run automatically — no manual triggering required.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  ┌──────────────────┐                                                       │
│  │   You/Terraform  │                                                       │
│  │                  │                                                       │
│  │  API Key with    │                                                       │
│  │  Write permission│                                                       │
│  └────────┬─────────┘                                                       │
│           │                                                                 │
│           │ 1. Configure export sink                                        │
│           ▼                                                                 │
│  ┌──────────────────┐         ┌──────────────────┐                         │
│  │  Temporal Cloud  │         │   Your AWS       │                         │
│  │                  │         │   Account        │                         │
│  │  ┌────────────┐  │         │                  │                         │
│  │  │ Namespace  │  │  2. Assume Role            │                         │
│  │  │            │──┼────────────────────────────┼──┐                      │
│  │  └────────────┘  │         │                  │  │                      │
│  │                  │         │  ┌────────────┐  │  │                      │
│  └──────────────────┘         │  │  IAM Role  │◄─┼──┘                      │
│                               │  └─────┬──────┘  │                         │
│                               │        │         │                         │
│                               │        │ 3. Write                          │
│                               │        ▼         │                         │
│                               │  ┌────────────┐  │                         │
│                               │  │ S3 Bucket  │  │                         │
│                               │  └────────────┘  │                         │
│                               └──────────────────┘                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How Cross-Account Access Works

The IAM role in your AWS account trusts specific Temporal Cloud IAM roles (from multiple Temporal AWS accounts) to assume it. The trust policy requires an **External ID** (your Temporal account UUID) to prevent confused deputy attacks.

---

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) v1.0+
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- Temporal Cloud account with **Write** permission on the target namespace

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd TemporalCloud-Terraform-WorkflowHistory-Export

# Create your variables file from the example
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region           = "us-east-1"
temporal_account_id  = "abc123"                                  # Your account slug
temporal_external_id = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"    # Your External ID (UUID)
bucket_name          = "your-company-temporal-exports"
namespace_name       = "your-namespace"
```

See [Where to Find Configuration Values](#where-to-find-configuration-values) for detailed instructions.

### Step 2: Set API Key

```bash
export TF_VAR_temporal_api_key="your-temporal-api-key"
```

### Step 3: Deploy

```bash
terraform init
terraform plan
terraform apply
```

---

## Where to Find Configuration Values

### Temporal Cloud UI (cloud.temporal.io)

#### temporal_account_id (Account Slug)

1. Log in to [Temporal Cloud](https://cloud.temporal.io)
2. Click **Namespaces** in the left sidebar
3. Your namespace ID is displayed in the format below — the account ID is the part after the dot:

```
sandbox.abc123
        └── Account ID (use this value)
```

#### temporal_external_id (UUID)

1. Log in to [Temporal Cloud](https://cloud.temporal.io)
2. Navigate to **Settings** → **Export**
3. Select **Manual** for the **Access Method**
4. Fill out the required fields
5. Click **Download** in the **Create AWS Role** section
6. Look for the **External ID** — a UUID format string (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)
7. If not visible in UI, contact Temporal support or check the [AWS S3 Export Setup docs](https://docs.temporal.io/cloud/export/aws-export-s3)

#### temporal_api_key

1. Log in to [Temporal Cloud](https://cloud.temporal.io)
2. Click **Settings** in the left sidebar
3. Select **API Keys**
4. Click **Create API Key**
5. Give it a descriptive name (e.g., "terraform-export-sink")
6. **Important:** Ensure the API key has **Write** permission on your target namespace
7. Copy the key immediately — it won't be shown again

#### namespace_name

1. Log in to [Temporal Cloud](https://cloud.temporal.io)
2. Click **Namespaces** in the left sidebar
3. Your namespace name is displayed in the list (e.g., `production`, `staging`)

### AWS Configuration

#### aws_region

Choose the AWS region that matches (or is closest to) your Temporal Cloud namespace region. Common options:
- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)

#### bucket_name

Choose a globally unique S3 bucket name. Suggestions:
- `{company}-temporal-exports-{namespace}` (e.g., `acme-temporal-exports-production`)
- Must be lowercase, no spaces, 3-63 characters

---

## Configuration Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `temporal_api_key` | API key with Write permission (set via env var) | — |
| `temporal_account_id` | Account slug from Temporal Cloud UI | `abc123` |
| `temporal_external_id` | UUID for IAM trust policy | `a1b2c3d4-e5f6-...` |
| `bucket_name` | S3 bucket name (globally unique) | `acme-temporal-exports` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region (should match namespace region) |
| `namespace_name` | `sandbox` | Temporal namespace to export from |
| `temporal_role_arns` | *(5 Temporal ARNs)* | Temporal Cloud IAM roles for trust policy |

### Outputs

| Output | Description |
|--------|-------------|
| `s3_bucket_name` | Name of the S3 bucket |
| `s3_bucket_arn` | ARN of the S3 bucket |
| `iam_role_arn` | ARN of the IAM role |
| `export_sink_name` | Name of the export sink |

---

## Understanding Temporal IDs

This configuration requires **two different Temporal identifiers**:

| ID | Format | Used For | Example |
|----|--------|----------|---------|
| `temporal_account_id` | Short slug | Namespace ID in export sink | `abc123` |
| `temporal_external_id` | UUID | IAM trust policy External ID | `a1b2c3d4-e5f6-7890-...` |

### Namespace ID Format

The full namespace ID combines these:

```
my-namespace.abc123
     │         │
     │         └── temporal_account_id (slug)
     └── namespace_name
```

### Why Two IDs?

- **Account slug** — Used by Temporal Cloud APIs to identify your namespace
- **External ID (UUID)** — Security mechanism for AWS cross-account role assumption; prevents confused deputy attacks

---

## Verification

### Check Temporal Cloud UI

1. Go to Temporal Cloud UI
2. Navigate to your namespace → **Export**
3. Status should show **Enabled** and health should show **Ok**

### Check via tcld

```bash
export TEMPORAL_CLOUD_API_KEY="your-api-key"

tcld namespace export s3 get \
  --namespace my-namespace.abc123 \
  --sink-name s3-workflow-export
```

### Check S3 Bucket

```bash
# List bucket contents (will be empty until workflows close)
aws s3 ls s3://your-bucket-name/ --recursive
```

---

## Exported Data Format

### File Location

Files are organized by date:

```
s3://your-bucket/temporal-workflow-history/export/<namespace>/YYYY/MM/DD/...
```

### File Format

- **Format:** Protocol Buffers (proto)
- **Schema:** [temporalio/api on GitHub](https://github.com/temporalio/api)
- **Contents:** Closed workflow execution histories

### Converting to Parquet

For analytics, convert proto to Parquet. See Temporal's [example Python workflow](https://temporal.io/blog/get-insights-from-workflow-histories-export-on-temporal-cloud) for conversion.

---

## Cost Considerations

### Temporal Cloud

- **1 Action per workflow exported**
- Appears as separate line item on invoice per namespace
- Excluded from APS calculations

### AWS

- S3 storage costs for exported files
- S3 PUT request costs

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `Access Denied` on terraform apply | API key lacks Write permission | Grant Write permission to service account on namespace |
| `rpc error: code = Unavailable desc = error reading from server: EOF` | Transient API connectivity issue | Retry the command; check network/VPN; verify API key has no extra whitespace |
| Export status shows `Error` | IAM role misconfigured | Verify trust policy has correct External ID (UUID, not slug) |
| No files in S3 | No workflows have closed | Run a workflow and wait up to 24 hours |
| `InvalidParameterValue` | Bucket in wrong region | S3 bucket must be in same region as namespace |
| `AssumeRole` failure | Trust policy incorrect | Verify `temporal_role_arns` and `temporal_external_id` are correct |

### Debug API Connectivity

```bash
# Test Temporal Cloud API connectivity
curl -v https://saas-api.tmprl.cloud:443

# Test with tcld
export TEMPORAL_CLOUD_API_KEY="your-api-key"
tcld namespace list
```

### Verify IAM Role Trust Policy

```bash
aws iam get-role --role-name temporal-export-your-namespace \
  --query 'Role.AssumeRolePolicyDocument'
```

Should show:
- **Principal:** List of Temporal Cloud role ARNs (see `temporal_role_arns` in `variables.tf`)
- **Condition:** `sts:ExternalId` equals your `temporal_external_id` (UUID)

---

## Cleanup

```bash
terraform destroy
```

**Note:** If the S3 bucket contains files, empty it first:

```bash
aws s3 rm s3://your-bucket-name --recursive
terraform destroy
```

Or add `force_destroy = true` to the `aws_s3_bucket` resource in `s3.tf`.

---

## References

### Temporal Documentation

- [Workflow History Export Overview](https://docs.temporal.io/cloud/export)
- [AWS S3 Export Setup](https://docs.temporal.io/cloud/export/aws-export-s3)
- [Namespace Permissions Reference](https://docs.temporal.io/cloud/users#namespace-level-permissions-details)
- [Terraform Provider Documentation](https://registry.terraform.io/providers/temporalio/temporalcloud/latest/docs)

### AWS Documentation

- [Cross-Account IAM Role Tutorial](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html)
- [IAM Trust Policies (AWS Security Blog)](https://aws.amazon.com/blogs/security/how-to-use-trust-policies-with-iam-roles/)

---
