# 🚀 Quick Start Guide

## This POC is now ready! Here's how to get started immediately:

### Prerequisites
✅ AWS IAM account with full access
✅ AWS CLI configured locally
✅ Python 3.11+ installed
✅ Modern web browser

### Step 1: Enable Bedrock Access (2 minutes)
```bash
# Go to AWS Console > Bedrock > Model Access
# Request access to "Claude 3 Sonnet" (usually instant)
```

### Step 2: Run Automated Setup (5 minutes)
```bash
cd "/Users/purnendudas/Library/CloudStorage/OneDrive-Personal/Learning and Development/UI CODE/Explain-Deal-POC"
chmod +x infrastructure/setup.sh
./infrastructure/setup.sh
```

**Save the output:**
```
API Endpoint: https://xyz.execute-api.us-east-1.amazonaws.com/prod
S3 Bucket Name: deal-structure-bucket-1234567890
```

### Step 3: Open Frontend & Configure (2 minutes)
```bash
# Open in browser:
file:///Users/purnendudas/Library/CloudStorage/OneDrive-Personal/Learning\ and\ Development/UI\ CODE/Explain-Deal-POC/frontend/index.html

# Or serve locally:
cd frontend && python -m http.server 8000
# Then open: http://localhost:8000
```

Scroll to **Configuration** section and enter:
- API Endpoint: (paste from Step 2)
- S3 Bucket: (paste from Step 2)
- Click **Save**

### Step 4: Test It Out (3 minutes)
1. Upload the sample `deal-structure.json` file
2. Click **Upload to S3**
3. Click **Explain My Deal**
4. See the AI explanation!

---

## 📊 What You'll Get

✅ **Web UI** - Beautiful interface for file upload and result display  
✅ **AI Analysis** - AWS Bedrock Claude 3 analyzes deal structures  
✅ **Simple Output** - Complex finance explained in plain English  
✅ **Cloud Storage** - Files safely stored in S3  
✅ **Serverless** - No servers to manage, pay only for what you use

---

## 🏗️ Architecture

```
Browser → API Gateway → Lambda (Bedrock) → S3 + Bedrock
         ↓
    Upload to S3
     Analysis
     Results
```

---

## 📚 Full Documentation

See `docs/SETUP_GUIDE.md` for:
- Detailed setup instructions
- Troubleshooting guide
- Security best practices
- Cost optimization
- Testing procedures

---

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `frontend/index.html` | Web interface |
| `frontend/app.js` | Frontend logic |
| `lambda/analyze_deal.py` | Bedrock integration |
| `lambda/presigned_url.py` | S3 upload handler |
| `infrastructure/setup.sh` | Automated deployment |
| `deal-structure.json` | Sample file for testing |

---

## ⚡ Costs

- **S3**: ~$0.23/month
- **Lambda**: ~$0.20/month
- **Bedrock**: ~$0.30/month (Claude 3 Sonnet)
- **API Gateway**: ~$0.04/month
- **Total**: ~$0.77/month (low volume)

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Setup script fails | Ensure AWS CLI is configured: `aws configure` |
| Bedrock error | Enable Claude in Bedrock console > Model Access |
| API endpoint error | Check format: `https://[id].execute-api.[region].amazonaws.com/prod` |
| Upload fails | Verify S3 bucket name is correct |

---

## ✨ What's Included

### Frontend
- Modern, responsive UI
- Drag & drop file upload
- Real-time deal details display
- Configuration management
- Error handling & status messages

### Backend
- 2 Lambda functions
- S3 integration for file storage
- Bedrock Claude 3 Sonnet integration
- API Gateway with CORS support
- CloudFormation IaC template

### Infrastructure
- Automated setup script
- CloudFormation template
- IAM policies preconfigured
- Lifecycle policies for cost savings
- Comprehensive documentation

---

## 🎓 Next Steps After Setup

1. **Test with different deal types** - Try various finance structures
2. **Customize the prompt** - Edit the analysis prompt in `lambda/analyze_deal.py`
3. **Add features** - Support more file formats, batch analysis, etc.
4. **Monitor costs** - Use CloudWatch to track usage
5. **Enhance security** - Add authentication and rate limiting

---

## 📖 Documentation Structure

```
docs/
└── SETUP_GUIDE.md        - Complete deployment guide
    - Prerequisites
    - Setup instructions (3 methods)
    - Configuration
    - Usage guide
    - Testing procedures
    - Troubleshooting
    - Security guide
    - Cost analysis
    - Learning resources
```

---

**You're all set! Proceed with Step 1 above to get started. 🚀**

For detailed information, see `docs/SETUP_GUIDE.md`
