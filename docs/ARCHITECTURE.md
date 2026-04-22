# Architecture & Technical Design

## System Architecture

### Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          End User Browser                               │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ • File Upload Interface                                          │  │
│  │ • Deal Details Display                                           │  │
│  │ • Configuration Panel                                            │  │
│  │ • AI Explanation Viewer                                          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                 HTTPS (REST API Calls)
                              │
┌─────────────────────────────────────────────────────────────────────────┐
│                        AWS API Gateway                                  │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │ /presigned-url (POST)  → Generate upload URLs                  │   │
│  │ /analyze-deal (POST)   → Trigger analysis                     │   │
│  └────────────────────────────────────────────────────────────────┘   │
└─────────┬───────────────────────────────────────────────────────────┬──┘
          │                                                            │
          ▼                                                            ▼
┌──────────────────────────┐                        ┌────────────────────────………┐
│   Lambda Function 1      │                        │   Lambda Function 2         │
│  Presigned URL Gen       │                        │  Analyze Deal (Bedrock)     │
├──────────────────────────┤                        ├─────────────────────────────┤
│ • Receives request       │                        │ • Receives s3Key            │
│ • Generates S3 URL      │                        │ • Fetches from S3           │
│ • Returns (1hr expiry)  │                        │ • Calls Bedrock Claude     │
│ • Logs to CloudWatch    │                        │ • Formats response          │
│ Runtime: Python 3.11    │                        │ • Returns HTML explanation  │
│ Memory: 128 MB          │                        │ Runtime: Python 3.11        │
│ Timeout: 30s            │                        │ Memory: 256 MB              │
│ Execution Role: ✓       │                        │ Timeout: 60s                │
│                         │                        │ Execution Role: ✓           │
└──────────────────────────┘                        └────────────────────────────┘
          │                                                  │
          ▼                                                  ▼
      ┌───────────┐                              ┌────────────────────┐
      │  S3       │◄─────────────────────────────│ AWS Bedrock        │
      │ Bucket    │  GET/PUT JSON files          │ Claude 3 Sonnet    │
      │           │                              │  • Analyzes deal   │
      │ Policies: │                              │  • Generates text  │
      │ • Private │                              │ • Model ID:        │
      │ • Versioning                             │   anthropic.claude │
      │ • Lifecycle                              │   -3-sonnet-...    │
      └───────────┘                              └────────────────────┘
```

---

## Component Details

### 1. Frontend (HTML/CSS/JavaScript)

**File**: `frontend/index.html`, `styles.css`, `app.js`

**Technology**:
- Plain vanilla JavaScript (no frameworks for simplicity)
- CSS Grid & Flexbox for responsive design
- Local Storage for configuration persistence

**Key Features**:
```javascript
// Configuration management
localStorage.setItem('apiEndpoint', endpoint);
localStorage.setItem('s3Bucket', bucket);

// File handling
- Drag & drop support
- JSON validation
- JSON preview with syntax highlighting

// API communication
- Fetch API for HTTP calls
- Error handling
- Loading states

// UI updates
- Dynamic deal details grid
- Formatted explanation display
- Real-time status messages
```

**Workflow**:
1. User uploads JSON file
2. App validates and previews
3. User clicks "Upload to S3"
4. App calls `/presigned-url` endpoint
5. Browser uploads directly to S3 using presigned URL
6. User clicks "Explain My Deal"
7. App calls `/analyze-deal` endpoint
8. Lambda fetches from S3, calls Bedrock
9. Results displayed in UI

---

### 2. Backend - Lambda Function 1: Presigned URL Generator

**File**: `lambda/presigned_url.py`

**Purpose**: Generate temporary URLs for secure S3 uploads

**Input**:
```json
{
  "fileName": "deals/1234567890-deal.json",
  "contentType": "application/json",
  "bucket": "deal-structure-bucket-xxx"
}
```

**Process**:
1. Receives upload request
2. Validates bucket exists
3. Generates presigned PUT URL (valid 1 hour)
4. Returns URL to frontend

**Output**:
```json
{
  "presignedUrl": "https://s3.amazonaws.com/...",
  "fileKey": "deals/1234567890-deal.json",
  "bucket": "deal-structure-bucket-xxx"
}
```

**Security**:
- Presigned URL expires in 1 hour
- Can only PUT (upload), not GET or DELETE
- Tied to specific bucket and key

---

### 3. Backend - Lambda Function 2: Deal Analyzer

**File**: `lambda/analyze_deal.py`

**Purpose**: Fetch deal from S3 and analyze with Bedrock Claude

**Input**:
```json
{
  "s3Key": "deals/1234567890-deal.json",
  "s3Bucket": "deal-structure-bucket-xxx",
  "region": "us-east-1"
}
```

**Process**:
```python
# 1. Fetch deal from S3
response = s3_client.get_object(Bucket=bucket, Key=key)
deal_structure = json.loads(response['Body'].read())

# 2. Create analysis prompt
prompt = create_analysis_prompt(deal_structure)

# 3. Call Bedrock Claude 3 Sonnet
response = bedrock_runtime.invoke_model(
    modelId="anthropic.claude-3-sonnet-20240229-v1:0",
    body=json.dumps({
        "max_tokens": 2000,
        "messages": [{"role": "user", "content": prompt}]
    })
)

# 4. Format and return
explanation = format_explanation(response_body['content'][0]['text'])
return success_response(explanation)
```

**Output**:
```json
{
  "success": true,
  "explanation": "<p><h3>Deal Overview</h3>...",
  "timestamp": "2024-04-21T10:30:00Z"
}
```

**Prompt Structure**:
```
"Analyze this auto finance deal and provide:
1. Deal Overview
2. Vehicle Details
3. Buyer Information
4. Financial Terms (simple explanation)
5. Key Numbers Breakdown
6. Monthly Commitment
7. Deal Summary

Use simple English, no jargon."
```

---

### 4. AWS S3 Configuration

**Bucket Name**: `deal-structure-bucket-[timestamp]`

**Configuration**:
```yaml
Versioning: Enabled
  - Allows recovery of previous versions
  
Lifecycle Rules:
  - Delete objects in "deals/" after 30 days
  - Keeps storage costs low
  
Public Access Block: ALL ENABLED
  - Prevents accidental public exposure
  
Encryption: Default (S3-Managed)
  - Data encrypted at rest
  - Optional: Switch to KMS for customer-managed keys
  
Folder Structure:
  deals/
    ├── 1234567890-deal.json
    ├── 1234567891-deal.json
    └── 1234567892-deal.json
```

---

### 5. AWS API Gateway

**Endpoints**:

| Method | Path | Lambda Function | Purpose |
|--------|------|-----------------|---------|
| POST | /presigned-url | presigned_url_lambda | Generate S3 upload URL |
| POST | /analyze-deal | analyze_deal_lambda | Analyze with Bedrock |

**Configuration**:
```yaml
REST API Name: deal-analyzer-api

Resources:
  /presigned-url
    POST:
      Integration: Lambda Proxy
      Target: generate-presigned-url
      CORS: Enabled
      
  /analyze-deal
    POST:
      Integration: Lambda Proxy
      Target: analyze-deal-with-bedrock
      CORS: Enabled

Deployment:
  Stage: prod
  URL: https://[api-id].execute-api.[region].amazonaws.com/prod
```

**CORS Headers** (automatically added):
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

---

### 6. AWS Bedrock Integration

**Model**: Anthropic Claude 3 Sonnet (`anthropic.claude-3-sonnet-20240229-v1:0`)

**Why Sonnet?**
- Balanced cost ($3/M input tokens, $15/M output tokens)
- Fast response times (~1-2 seconds)
- Excellent reasoning for financial analysis
- Suitable for POC and production

**API Call**:
```python
response = bedrock_runtime.invoke_model(
    modelId="anthropic.claude-3-sonnet-20240229-v1:0",
    contentType="application/json",
    accept="application/json",
    body=json.dumps({
        "anthropic_version": "bedrock-2023-06-01",
        "max_tokens": 2000,  # Max response length
        "messages": [
            {
                "role": "user",
                "content": analysis_prompt
            }
        ]
    })
)
```

**Response Format**:
```json
{
  "content": [
    {
      "type": "text",
      "text": "Deal Overview: Jane Smith is financing..."
    }
  ],
  "usage": {
    "input_tokens": 525,
    "output_tokens": 312
  }
}
```

---

## Data Flow Diagram

### Upload Flow
```
User selects JSON file
        ↓
Frontend validates JSON
        ↓
Frontend calls /presigned-url API
        ↓
Lambda 1 generates presigned URL
        ↓
Frontend receives URL (valid 1 hr)
        ↓
Frontend uploads file directly to S3
        ↓
S3 confirms upload
        ↓
Frontend enables "Explain" button
```

### Analysis Flow
```
User clicks "Explain My Deal"
        ↓
Frontend calls /analyze-deal API
        ↓
Lambda 2 fetches file from S3
        ↓
Lambda 2 creates analysis prompt
        ↓
Lambda 2 calls Bedrock Claude
        ↓
Claude analyzes and produces explanation
        ↓
Lambda 2 formats output as HTML
        ↓
Frontend receives HTML
        ↓
Frontend displays explanation
```

---

## Security Architecture

### IAM Permissions

```json
{
  "S3Access": {
    "Actions": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
    "Resources": ["arn:aws:s3:::deal-structure-bucket/*"],
    "Effect": "Allow"
  },
  "BedrockAccess": {
    "Actions": ["bedrock:InvokeModel"],
    "Resources": ["arn:aws:bedrock:*::foundation-model/*"],
    "Effect": "Allow"
  },
  "CloudWatchLogs": {
    "Actions": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
    "Resources": ["arn:aws:logs:*:*:*"],
    "Effect": "Allow"
  }
}
```

### Data Protection

```
User ──HTTPS──> API Gateway ──Encrypted──> Lambda
                                     ↓
                              Bedrock API (HTTPS)
                                     ↓
                              Claude Analysis
                                     ↓
                    Response ──HTTPS──> User
                    
S3 Storage: Encrypted at rest (KMS or S3-managed)
Data lifetime: 30 days (auto-deleted)
```

---

## Scalability Considerations

### Current Limits (Single User)
- Lambda: 128-256 MB (sufficient for analysis)
- API Gateway: 1000 req/sec (for free tier)
- Bedrock: Per-account throttling (usually high)

### For Production Scaling
```
Frontend (CDN)
      ↓
API Gateway (auto-scales)
      ↓
Lambda Concurrency: 1000 (set in Lambda config)
      ↓
S3 (unlimited capacity)
      ↓
Bedrock (managed by AWS)
```

---

## Monitoring & Logging

### CloudWatch Logs
- Lambda logs: `/aws/lambda/analyze-deal-with-bedrock`
- Lambda logs: `/aws/lambda/generate-presigned-url`
- API logs: API Gateway execution logs

### Metrics to Monitor
```
Lambda Metrics:
  - Duration (ms)
  - Errors
  - Concurrent Executions
  
S3 Metrics:
  - Requests
  - Storage (GB)
  
Bedrock Metrics:
  - Input tokens
  - Output tokens
  - Invoke count
```

---

## Error Handling

### Frontend Error Handling
```javascript
try {
  response = await fetch(apiEndpoint, {...})
  if (!response.ok) throw new Error(`HTTP ${response.status}`)
  data = await response.json()
  if (!data.success) throw new Error(data.error)
} catch (error) {
  showError(statusElement, `Error: ${error.message}`)
}
```

### Lambda Error Handling
```python
try:
    # Process request
except ClientError as e:
    logger.error(f"AWS Error: {e}")
    return error_response(500, str(e))
except Exception as e:
    logger.error(f"Error: {e}", exc_info=True)
    return error_response(500, "Internal server error")
```

---

**Last Updated**: April 21, 2026  
**Version**: 1.0
