# Deal Structure Analyzer - Gen AI POC

A serverless web application that analyzes auto finance deal structures using AWS Bedrock (Claude 3 Sonnet) and explains complex financial terms in simple, easy-to-understand English.

## ✨ Features

- 📤 **Easy File Upload** - Drag and drop or click to upload JSON deal structures
- 🤖 **AI-Powered Analysis** - AWS Bedrock Claude 3 Sonnet analyzes deals instantly
- 📊 **Deal Visualization** - Interactive dashboard showing key deal details
- 💬 **Plain English Explanations** - Complex finance explained simply
- ☁️ **Cloud Storage** - Secure S3 storage with automatic cleanup
- 🔓 **No Servers to Manage** - Fully serverless architecture
- 💰 **Cost Effective** - Pay only for what you use (~$0.77/month for low volume)

## 🏗️ Technology Stack

| Component | Technology |
|-----------|-----------|
| **Frontend** | HTML5, CSS3, Vanilla JavaScript |
| **Backend** | AWS Lambda (Python 3.11) |
| **AI/ML** | AWS Bedrock (Claude 3 Sonnet) |
| **Storage** | AWS S3 |
| **API** | AWS API Gateway |
| **Infrastructure** | CloudFormation, IAM |
| **Infrastructure as Code** | Bash, CloudFormation YAML |

## 🚀 Quick Start (5 minutes)

### Prerequisites
- ✅ AWS account with full access to S3, Lambda, Bedrock, API Gateway
- ✅ AWS CLI configured locally
- ✅ Python 3.11+

### Step 1: Enable Bedrock Access
```bash
# Go to AWS Console > Bedrock > Model Access
# Click "Manage Model Access"
# Request access to "Claude 3 Sonnet"
```

### Step 2: Run Setup Script
```bash
cd Explain-Deal-POC
chmod +x infrastructure/setup.sh
./infrastructure/setup.sh
```

**Save the output:**
- API Endpoint: `https://[api-id].execute-api.[region].amazonaws.com/prod`
- S3 Bucket Name: `deal-structure-bucket-[timestamp]`

### Step 3: Open Frontend
```bash
# Open in browser:
file:///path/to/Explain-Deal-POC/frontend/index.html

# Or serve locally:
cd frontend && python -m http.server 8000
# Visit: http://localhost:8000
```

Configure:
- API Endpoint: (paste from Step 2)
- S3 Bucket: (paste from Step 2)
- Click "Save Configuration"

### Step 4: Test
1. Upload `deal-structure.json`
2. Click "Upload to S3"
3. Click "Explain My Deal"
4. See the AI explanation!

## 📁 Project Structure

```
Explain-Deal-POC/
├── frontend/                          # Web UI
│   ├── index.html                     # Main application  
│   ├── app.js                         # Frontend logic  
│   └── styles.css                     # Styling
│
├── lambda/                            # AWS Lambda functions
│   ├── analyze_deal.py                # Bedrock integration +  S3 fetch
│   └── presigned_url.py               # Presigned URL generation
│
├── infrastructure/                    # AWS setup scripts
│   ├── setup.sh                       # Automated deployment
│   ├── cloudformation-template.yaml   # IaC template
│   ├── lambda-iam-policy.json         # IAM policy
│   └── lambda-trust-policy.json       # Trust policy
│
├── docs/                              # Documentation
│   ├── SETUP_GUIDE.md                 # Comprehensive setup guide
│   ├── QUICK_START.md                 # Quick start (this file)
│   └── ARCHITECTURE.md                # Technical architecture
│
├── deal-structure.json                # Sample deal file
└── README.md                          # Project overview
```

## 📊 Architecture

```
Frontend (Browser)
    ↓
API Gateway (REST API)
    ├─→ Presigned URL Lambda (Generate S3 upload URLs)
    │       ↓
    │    S3 Bucket (Store deal structures)
    │
    └─→ Analyze Lambda (Fetch & Analyze)
            ↓
    AWS Bedrock Claude 3 Sonnet (AI Analysis)
            ↓
Frontend (Display explanation)
```

## 💰 Estimated Costs

| Service | Cost/Month |
|---------|-----------|
| S3 | $0.23 |
| Lambda | $0.20 |
| Bedrock | $0.30 |
| API Gateway | $0.04 |
| **Total** | **~$0.77** |

*Prices based on 100 analyses per month. AWS free tier may apply.*

## 📖 Documentation

- **[QUICK_START.md](docs/QUICK_START.md)** - Get started in 5 minutes
- **[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)** - Comprehensive setup & troubleshooting
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical deep dive

## ⚡ Key Features Explained

### 1. File Upload
- Drag & drop support
- JSON validation  
- Real-time preview
- File size checking

### 2. Secure S3 Storage
- Presigned URLs (1-hour expiration)
- Direct browser upload (no server side copy)
- Automatic cleanup (30-day lifecycle)
- Versioning enabled

### 3. AI Analysis
- Claude 3 Sonnet model
- Custom analysis prompt
- Formatted HTML output
- Error handling

### 4. Deal Details Display
- Auto-extracted key information
- Formatted currency values
- Responsive grid layout
- Real-time updates

## 🔒 Security

- ✅ **IAM Roles** - Least privilege permissions
- ✅ **S3 Privacy** - Block all public access
- ✅ **HTTPS Only** - All API calls encrypted
- ✅ **Presigned URLs** - Secure temporary access
- ✅ **Auto Cleanup** - Files auto-deleted after 30 days
- ✅ **Logging** - All activities logged in CloudWatch

## 🧪 Testing

### Quick Test
```bash
# 1. Open frontend/index.html in browser
# 2. Configure API endpoint and S3 bucket
# 3. Upload deal-structure.json
# 4. Click "Explain My Deal"
```

### View Logs
```bash
# Lambda logs
aws logs tail /aws/lambda/analyze-deal-with-bedrock --follow
aws logs tail /aws/lambda/generate-presigned-url --follow
```

### Test S3 Upload
```bash
aws s3 ls deal-structure-bucket-xxx/deals/
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Setup fails | Ensure AWS CLI is configured: `aws configure` |
| Bedrock error | Enable Claude in Bedrock Model Access |
| API unreachable | Verify endpoint format and trailing `/prod` |
| Upload fails | Check S3 bucket name matches configuration |
| No analysis | Check Lambda logs for errors |

See [SETUP_GUIDE.md](docs/SETUP_GUIDE.md#-troubleshooting) for detailed troubleshooting.

## 📈 Scaling & Production

For production deployment:
- ✅ Add CloudFront CDN
- ✅ Enable WAF (Web Application Firewall)
- ✅ Add Cognito authentication
- ✅ Use custom domain
- ✅ Set up auto-scaling
- ✅ Add monitoring & alerting
- ✅ Implement rate limiting

See [SETUP_GUIDE.md](docs/SETUP_GUIDE.md#-scalability-considerations) for details.

## 🎯 Use Cases

- 📋 **Dealer Explanation** - Explain deals to customers
- 📊 **Deal Review** - Quick analysis of multiple deals
- 🎓 **Training** - Teach finance professionals
- 📱 **Integration** - Embed in other systems
- 📈 **Batch Analysis** - Process multiple files

## ✨ What's Included

### Frontend
- Modern responsive UI
- Drag & drop file upload
- Real-time deal details
- Configuration management
- Error handling

### Backend
- 2 Lambda functions
- S3 integration
- Bedrock Claude integration
- API Gateway setup
- IAM policies

### Infrastructure
- Automated setup script
- CloudFormation template
- Comprehensive documentation
- Sample deal structure
- Troubleshooting guide

## 🚀 Next Steps

After initial setup:

1. **Customize Analysis Prompt** - Edit `lambda/analyze_deal.py` to change analysis focus
2. **Add More Features** - Support XML, CSV files; generate PDF reports
3. **Monitor Usage** - Set up CloudWatch dashboards
4. **Enhance Security** - Add Cognito authentication
5. **Deploy to Production** - Follow production checklist

## 📚 Resources

- [AWS Bedrock Docs](https://docs.aws.amazon.com/bedrock/)
- [AWS Lambda Guide](https://docs.aws.amazon.com/lambda/)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [Claude API Docs](https://docs.anthropic.com/)
- [AWS S3 Guide](https://docs.aws.amazon.com/s3/)

## 💡 Key Learnings

This POC demonstrates:
- ✅ Serverless architecture best practices
- ✅ Integrating GenAI with AWS services
- ✅ Secure file handling with S3
- ✅ RESTful API design
- ✅ Infrastructure as Code (IaC)
- ✅ Cost-effective cloud solutions

## 📝 Configuration Files

### Environment Variables
None - configuration stored in frontend localStorage

### AWS Resources Created
- S3 Bucket: `deal-structure-bucket-[timestamp]`
- Lambda Role: `deal-analyzer-lambda-role`
- Lambda Function 1: `generate-presigned-url`
- Lambda Function 2: `analyze-deal-with-bedrock`
- API Gateway: `deal-analyzer-api`

## 🔄 CI/CD Integration

To integrate with CI/CD:

```bash
# Deploy with CloudFormation
aws cloudformation create-stack \
  --stack-name deal-analyzer \
  --template-body file://infrastructure/cloudformation-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## 🤝 Contributing

This is a POC project. Feel free to:
- Customize the AI prompt
- Add new features
- Improve the UI
- Optimize costs
- Add authentication

## 📄 License

This project is provided as-is for educational and demonstration purposes.

---

## 🚀 Ready to Get Started?

1. **Enable Bedrock access** (2 min)
2. **Run setup script** (5 min)
3. **Configure frontend** (2 min)
4. **Test with sample file** (3 min)
5. **Start analyzing deals!** ✨

**[→ Start with QUICK_START.md](docs/QUICK_START.md)**

---

**Questions?**  
See [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) for comprehensive documentation and troubleshooting.

**Report Issues:**  
Check the troubleshooting section or AWS documentation links above.

---

**Built with** ❤️ **using AWS Services**

Last Updated: April 21, 2026
