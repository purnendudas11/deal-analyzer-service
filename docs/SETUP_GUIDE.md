# Deal Structure Analyzer - Gen AI POC
## Comprehensive Deployment & Setup Guide

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Setup Instructions](#setup-instructions)
5. [Configuration](#configuration)
6. [Usage Guide](#usage-guide)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)
9. [Cost Optimization](#cost-optimization)

---

## 🎯 Project Overview

The Deal Structure Analyzer is a Gen AI POC that leverages AWS Bedrock (Claude) to analyze auto finance deal structures in JSON format and provide simple English explanations.

### Features
- **File Upload**: Upload JSON deal structure files
- **Cloud Storage**: Automatic storage in AWS S3
- **AI Analysis**: AWS Bedrock Claude 3 Sonnet analysis
- **Plain English Output**: Complex deal structures explained simply
- **Web Interface**: User-friendly dashboard for interaction

### Tech Stack
- **Frontend**: HTML5, CSS3, vanilla JavaScript
- **Backend**: AWS Lambda (Python 3.11)
- **AI**: AWS Bedrock (Claude 3 Sonnet)
- **Storage**: AWS S3
- **API**: AWS API Gateway
- **Infrastructure**: CloudFormation

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (Web UI)                         │
│  • File Upload Form  • Deal Details Display  • Explanation View   │
└──────────────┬──────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS API Gateway (REST API)                    │
│  Endpoints: /{presigned-url, analyze-deal}                       │
└──────┬─────────────────────────────────────┬────────────────────┘
       │                                      │
       ▼                                      ▼
┌────────────────────┐            ┌─────────────────────┐
│  Lambda Function   │            │  Lambda Function    │
│ (Presigned URL)    │            │ (Analyze with AI)   │
└────────┬───────────┘            └──────────┬──────────┘
         │                                   │
         ▼                                   ▼
    ┌──────────┐                   ┌──────────────────┐
    │   S3     │                   │  AWS Bedrock     │
    │ Bucket   │◄──────────────────│  (Claude 3)      │
    └──────────┘     GET/PUT       └──────────────────┘
```

---

## 📦 Prerequisites

### AWS Account Requirements
- ✅ AWS IAM account with full access to:
  - S3 (create bucket, upload/download objects)
  - Lambda (create functions, manage roles)
  - API Gateway (create REST APIs)
  - Bedrock (invoke models)
  - CloudWatch Logs (logging)
  - IAM (manage roles and policies)

### Local Machine Requirements
- ✅ AWS CLI installed and configured (`aws --version`)
- ✅ Python 3.11+ installed
- ✅ Zip utility for packaging (included on macOS)
- ✅ Git (optional, for version control)
- ✅ Modern web browser (Chrome, Firefox, Safari, Edge)

### AWS CLI Configuration
```bash
# Configure AWS credentials
aws configure

# When prompted, enter:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1 (or your preferred region)
# Default output format: json
```

### Bedrock Model Access
You must enable access to Claude 3 Sonnet in AWS Bedrock:

1. Go to [AWS Bedrock Console](https://console.aws.amazon.com/bedrock)
2. Navigate to **Model Access** (left sidebar)
3. Click **Manage Model Access**
4. Find **Anthropic** → **Claude 3 Sonnet**
5. Click "Request Access" (or if already granted, it will show ✓)
6. Accept the modal agreement
7. Wait for status to change to "Access granted" (usually instant)

---

## 🚀 Setup Instructions

### Option 1: Automated Setup (Recommended)

#### Step 1: Navigate to the project directory
```bash
cd /path/to/UI\ CODE/Explain-Deal-POC
```

#### Step 2: Make the setup script executable
```bash
chmod +x infrastructure/setup.sh
```

#### Step 3: Run the setup script
```bash
# Basic setup (uses default region us-east-1)
./infrastructure/setup.sh

# Or specify a different region
AWS_REGION=us-west-2 ./infrastructure/setup.sh
```

The script will:
- ✅ Create S3 bucket with versioning and lifecycle policies
- ✅ Create IAM role with appropriate permissions
- ✅ Package and deploy Lambda functions
- ✅ Create API Gateway with 2 resources and methods
- ✅ Configure integrations and permissions
- ✅ Display the API endpoint for frontend configuration

#### Step 4: Copy the API Endpoint
The script will output something like:
```
API Endpoint: https://abc123.execute-api.us-east-1.amazonaws.com/prod
S3 Bucket Name: deal-structure-bucket-1234567890
```

**Save these values** - you'll need them for the frontend.

---

### Option 2: CloudFormation Deployment

#### Step 1: Deploy CloudFormation Stack
```bash
aws cloudformation create-stack \
  --stack-name deal-analyzer-poc \
  --template-body file://infrastructure/cloudformation-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

#### Step 2: Wait for stack creation
```bash
aws cloudformation describe-stacks \
  --stack-name deal-analyzer-poc \
  --query 'Stacks[0].StackStatus' \
  --region us-east-1
```

#### Step 3: Get stack outputs
```bash
aws cloudformation describe-stacks \
  --stack-name deal-analyzer-poc \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

---

### Option 3: Manual AWS Console Setup

If you prefer to set up manually via AWS Console:

1. **Create S3 Bucket**
   - Service: S3 → Create Bucket
   - Name: `deal-structure-bucket-[timestamp]`
   - Enable versioning
   - Block public access

2. **Create IAM Role**
   - Service: IAM → Roles → Create Role
   - Trusted entity: Lambda
   - Attach policy: Use `infrastructure/lambda-iam-policy.json`

3. **Create Lambda Functions**
   - Function 1: `analyze-deal-with-bedrock` (analyze_deal.py)
   - Function 2: `generate-presigned-url` (presigned_url.py)
   - Assign IAM role from step 2

4. **Create API Gateway**
   - Create REST API
   - Add resources: `/presigned-url`, `/analyze-deal`
   - Create POST methods
   - Configure Lambda integrations

5. **Deploy API**
   - Create deployment
   - Create stage: `prod`

---

## ⚙️ Configuration

### Frontend Configuration

#### Step 1: Open the Frontend
Open your browser and navigate to:
```
file:///path/to/UI\ CODE/Explain-Deal-POC/frontend/index.html
```

Or serve it locally:
```bash
# Using Python
cd frontend
python -m http.server 8000
# Then open: http://localhost:8000
```

#### Step 2: Configure Settings
In the browser, scroll to the **Configuration** section and enter:

- **API Gateway Endpoint**: `https://[your-api-id].execute-api.[region].amazonaws.com/prod`
- **S3 Bucket Name**: `deal-structure-bucket-[timestamp]`
- **AWS Region**: Select your region

Click **Save Configuration** - settings are saved in browser localStorage.

### Environment Variables (Lambda)

The Lambda functions automatically read from environment variables:

```bash
# For analyze_deal Lambda:
export AWS_REGION=us-east-1

# These are set automatically based on your AWS account
```

---

## 📖 Usage Guide

### Step 1: Upload a Deal Structure File

1. Click the **File Upload** area
2. Either:
   - Click to select a JSON file
   - Drag and drop a JSON file
3. The file preview will appear below

Example file: `/deal-structure.json` is included in the project.

### Step 2: Upload to S3

1. Click **Upload to S3** button
2. File will be uploaded automatically
3. Status message confirms success

### Step 3: Get AI Explanation

1. Click **Explain My Deal** button
2. Please wait - Claude analyzes the deal
3. Simple English explanation appears below

### Step 4: Review Results

The output includes:
- Deal Overview
- Vehicle Information
- Buyer Details
- Financial Terms Explanation
- Monthly Payment Breakdown
- Key Takeaways

---

## 🔍 Testing

### Test with Sample File

The project includes a sample deal structure at:
```
/Users/purnendudas/Library/CloudStorage/OneDrive-Personal/Learning\ and\ Development/UI\ CODE/Explain-Deal-POC/deal-structure.json
```

#### Test Steps:
1. Open frontend UI
2. Enter configuration (API + S3 bucket)
3. Select the sample deal-structure.json file
4. Verify preview shows deal data
5. Click "Upload to S3"
6. Verify upload success message
7. Click "Explain My Deal"
8. Verify AI explanation appears

### Verify API Calls

Monitor Lambda execution:
```bash
# View Lambda logs for analyze-deal function
aws logs tail /aws/lambda/analyze-deal-with-bedrock --follow

# View Lambda logs for presigned-url function
aws logs tail /aws/lambda/generate-presigned-url --follow
```

### Test Bedrock Connectivity

```bash
# Test if Claude model is accessible
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)]'
```

---

## 🐛 Troubleshooting

### Issue: "Invalid JSON file"
**Solution**: Ensure the file is valid JSON. Test with:
```bash
# Validate JSON
python -m json.tool your-file.json
```

### Issue: "API Endpoint not accessible"
**Solution**: 
- Verify API Gateway is deployed
- Check endpoint format: `https://[api-id].execute-api.[region].amazonaws.com/prod`
- Ensure trailing `/prod` is included

### Issue: "S3 Upload fails"
**Solution**:
- Verify S3 bucket name is correct
- Check bucket exists: `aws s3 ls | grep deal-structure`
- Verify Lambda has S3 permissions
- Check CloudWatch logs: `aws logs tail /aws/lambda/generate-presigned-url --follow`

### Issue: "Analysis fails with Bedrock error"
**Solution**:
- Verify Claude model access: Go to Bedrock → Model Access
- Check Lambda has Bedrock permissions
- Verify region supports Bedrock (us-east-1, us-west-2, eu-west-1, ap-southeast-1)
- Check Lambda timeout (default 60 seconds should be okay)

### Issue: "CORS errors in browser"
**Solution**:
- The API Gateway is configured with CORS headers
- Refresh browser cache (Ctrl+Shift+R or Cmd+Shift+R)
- Check browser console for detailed error

### Debug Mode

Enable detailed logging:

```bash
# Update Lambda environment variable
aws lambda update-function-configuration \
  --function-name analyze-deal-with-bedrock \
  --environment Variables={LOG_LEVEL=DEBUG}
```

Then view logs:
```bash
aws logs tail /aws/lambda/analyze-deal-with-bedrock --follow --format short
```

---

## 🔒 Security Best Practices

### 1. IAM Permissions - Principle of Least Privilege
The setup uses minimal required permissions:
- Lambda can only access its specific S3 bucket
- Lambda can only invoke specific Bedrock models
- No wildcard (*) in resource ARNs

### 2. S3 Security
- Block all public access: ✅ Enabled
- Versioning enabled: ✅ Enabled
- Lifecycle policy: ✅ Auto-delete files after 30 days

### 3. API Gateway Security
Current setup is open for POC. For production:

```bash
# Add API Key requirement
aws apigateway update-method \
  --rest-api-id [api-id] \
  --resource-id [resource-id] \
  --http-method POST \
  --authorization-type API_KEY
```

For better security, add:
- ✅ AWS WAF (Web Application Firewall)
- ✅ API throttling
- ✅ Authorization (AWS_IAM, Cognito)
- ✅ Encryption in transit (TLS - already enabled)

### 4. Lambda Security
- ✅ Functions run with minimal IAM role
- ✅ Environment data not logged
- ✅ Timeout set appropriately
- ✅ Memory sized appropriately (256MB for analysis)

### 5. Data Protection
- ✅ S3 data encrypted at rest (can enable KMS)
- ✅ API calls over HTTPS
- ✅ Auto-delete old files via lifecycle policy

---

## 💰 Cost Optimization

### Estimated Monthly Costs (Low Volume)

| Service | Usage | Cost |
|---------|-------|------|
| S3 | 100 files, 30 days | $0.23 |
| Lambda | 100 calls, ~30s each | $0.20 |
| Bedrock | 100 calls | $0.30 |
| API Gateway | 100 calls | $0.04 |
| **Total** | | **~$0.77** |

### Cost-Saving Tips

1. **S3 Lifecycle Policy**: Auto-delete files (already configured for 30 days)

2. **Lambda Optimization**:
   - Reduce timeout if unnecessary
   - Use provisioned concurrency only for production

3. **Bedrock Model Selection**:
   - Claude 3 Sonnet: Good balance (current)
   - Claude 3 Haiku: Cheaper, faster (for simple cases)
   - Claude 3 Opus: Most capable but expensive

4. **API Gateway**:
   - Cache responses where applicable
   - Use stage variables for testing

### Monitor Costs

```bash
# Set up billing alerts
aws budgets create-budget \
  --account-id [your-account-id] \
  --budget file://budget-config.json

# View current spending
aws ce get-cost-and-usage \
  --time-period Start=2024-04-01,End=2024-04-30 \
  --granularity MONTHLY \
  --metrics UnblendedCost
```

---

## 📁 Project Structure

```
Explain-Deal-POC/
├── frontend/                          # Web UI
│   ├── index.html                     # Main UI page
│   ├── styles.css                     # Styling
│   └── app.js                         # Frontend logic
├── lambda/
│   ├── analyze_deal.py                # Bedrock integration
│   ├── presigned_url.py               # S3 upload handler
│   └── requirements.txt               # Python dependencies
├── infrastructure/
│   ├── setup.sh                       # Automated setup script
│   ├── cloudformation-template.yaml   # IaC template
│   ├── lambda-iam-policy.json         # IAM policy definition
│   └── lambda-trust-policy.json       # Trust policy
├── docs/
│   └── SETUP_GUIDE.md                 # This file
├── deal-structure.json                # Sample deal structure
└── README.md                          # Quick start

```

---

## 🎓 Learning Resources

### AWS Resources
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [AWS API Gateway Guide](https://docs.aws.amazon.com/apigateway/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

### Claude / Bedrock API
- [Anthropic Claude API Docs](https://docs.anthropic.com/)
- [Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/)

### Auto Finance Terms
- [Auto Finance Basics](https://www.investopedia.com/terms/a/auto-financing.asp)
- [Understanding APR](https://www.investopedia.com/terms/a/apr.asp)
- [Lease vs Purchase](https://www.investopedia.com/articles/pf/06/leasevbuybuy.asp)

---

## 📞 Support & Next Steps

### Common Next Steps

1. **Production Deployment**
   - Add authentication (Cognito)
   - Enable SSL/TLS certificates
   - Set up CloudFront CDN
   - Implement rate limiting

2. **Enhanced Features**
   - Support for multiple file formats (XML, CSV)
   - Batch analysis
   - Custom report generation
   - Deal comparison tool

3. **Monitoring**
   - Set up CloudWatch dashboards
   - Create automated alerts
   - Track model accuracy metrics

### Additional Enhancement Ideas

- Add deal templates for quick creation
- Export explanations to PDF
- Compare multiple deals side-by-side
- Store analysis history
- Add deal scoring/rating system
- Multi-language support
- Mobile app version

---

## 📝 Additional Notes

### Regional Availability
Bedrock is available in:
- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

Choose the closest region for lower latency.

### Model Updates
AWS frequently updates Bedrock models. To see available models:
```bash
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)]' \
  --output table
```

Update the MODEL_ID in Lambda functions if needed.

---

**Version**: 1.0  
**Last Updated**: April 21, 2026  
**Status**: POC - Ready for Testing

For questions or issues, consult the troubleshooting section or AWS documentation.
