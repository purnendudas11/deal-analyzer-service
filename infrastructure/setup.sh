#!/bin/bash

# AWS S3 and Bedrock Configuration Script
# This script sets up all required AWS infrastructure for the Deal Structure Analyzer POC

set -e

# Configuration variables
AWS_REGION="${AWS_REGION:-us-east-1}"
S3_BUCKET_NAME="deal-structure-bucket-$(date +%s)"
LAMBDA_ROLE_NAME="deal-analyzer-lambda-role"
ANALYZE_LAMBDA_NAME="analyze-deal-with-bedrock"
PRESIGNED_LAMBDA_NAME="generate-presigned-url"
API_GATEWAY_NAME="deal-analyzer-api"

echo "=========================================="
echo "Deal Analyzer Infrastructure Setup"
echo "=========================================="
echo "AWS Region: $AWS_REGION"
echo "S3 Bucket: $S3_BUCKET_NAME"
echo ""

# Step 1: Create S3 Bucket
echo "[1/6] Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$S3_BUCKET_NAME" \
    --region "$AWS_REGION" \
    $([ "$AWS_REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$AWS_REGION" || echo "") \
    2>/dev/null || echo "Bucket already exists or naming conflict"

# Enable versioning
echo "  - Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$S3_BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region "$AWS_REGION"

# Block public access
echo "  - Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$S3_BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$AWS_REGION"

# Set lifecycle policy to delete old uploads
echo "  - Setting lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$S3_BUCKET_NAME" \
    --lifecycle-configuration '{
      "Rules": [
        {
          "ID": "DeleteOldUploads",
          "Status": "Enabled",
          "Prefix": "deals/",
          "Expiration": {
            "Days": 30
          }
        }
      ]
    }' \
    --region "$AWS_REGION"

echo "  ✓ S3 bucket created successfully"

# Step 2: Create IAM Role for Lambda
echo ""
echo "[2/6] Creating IAM role for Lambda..."

# Create trust policy
TRUST_POLICY=$(cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

aws iam create-role \
    --role-name "$LAMBDA_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    2>/dev/null || echo "Role already exists"

# Create inline policy
POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetObjectVersion",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${S3_BUCKET_NAME}/*"
    },
    {
      "Sid": "S3BucketList",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::${S3_BUCKET_NAME}"
    },
    {
      "Sid": "BedrockAPI",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
)

aws iam put-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-name "deal-analyzer-policy" \
    --policy-document "$POLICY_DOCUMENT"

echo "  ✓ IAM role created successfully"

# Step 3: Create Lambda Functions
echo ""
echo "[3/6] Creating Lambda functions..."

ROLE_ARN=$(aws iam get-role --role-name "$LAMBDA_ROLE_NAME" --query 'Role.Arn' --output text)

# Package analyze_deal.py
echo "  - Creating analyze-deal Lambda function..."
cd lambda
zip -q function-analyze.zip analyze_deal.py
aws lambda create-function \
    --function-name "$ANALYZE_LAMBDA_NAME" \
    --runtime python3.11 \
    --role "$ROLE_ARN" \
    --handler "analyze_deal.lambda_handler" \
    --zip-file "fileb://function-analyze.zip" \
    --timeout 60 \
    --memory-size 256 \
    --environment "Variables={AWS_REGION=$AWS_REGION}" \
    --region "$AWS_REGION" \
    2>/dev/null || {
        echo "  - Updating analyze-deal Lambda function..."
        aws lambda update-function-code \
            --function-name "$ANALYZE_LAMBDA_NAME" \
            --zip-file "fileb://function-analyze.zip" \
            --region "$AWS_REGION"
    }

# Package presigned_url.py
echo "  - Creating presigned-url Lambda function..."
zip -q function-presigned.zip presigned_url.py
aws lambda create-function \
    --function-name "$PRESIGNED_LAMBDA_NAME" \
    --runtime python3.11 \
    --role "$ROLE_ARN" \
    --handler "presigned_url.lambda_handler" \
    --zip-file "fileb://function-presigned.zip" \
    --timeout 30 \
    --memory-size 128 \
    --region "$AWS_REGION" \
    2>/dev/null || {
        echo "  - Updating presigned-url Lambda function..."
        aws lambda update-function-code \
            --function-name "$PRESIGNED_LAMBDA_NAME" \
            --zip-file "fileb://function-presigned.zip" \
            --region "$AWS_REGION"
    }

cd ..

echo "  ✓ Lambda functions created successfully"

# Step 4: Create API Gateway
echo ""
echo "[4/6] Creating API Gateway..."

# Create REST API
API_ID=$(aws apigateway create-rest-api \
    --name "$API_GATEWAY_NAME" \
    --description "API for Deal Structure Analyzer" \
    --region "$AWS_REGION" \
    --query 'id' \
    --output text 2>/dev/null) || {
    echo "  - API Gateway already exists, retrieving ID..."
    API_ID=$(aws apigateway get-rest-apis \
        --query "items[?name=='$API_GATEWAY_NAME'].id" \
        --output text \
        --region "$AWS_REGION")
}

echo "  API ID: $API_ID"

# Get root resource
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$AWS_REGION" \
    --query 'items[0].id' \
    --output text)

# Create /presigned-url resource
PRESIGNED_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_ID" \
    --path-part "presigned-url" \
    --region "$AWS_REGION" \
    --query 'id' \
    --output text 2>/dev/null) || {
    PRESIGNED_RESOURCE=$(aws apigateway get-resources \
        --rest-api-id "$API_ID" \
        --region "$AWS_REGION" \
        --query "items[?path=='/presigned-url'].id" \
        --output text)
}

# Create /analyze-deal resource
ANALYZE_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_ID" \
    --path-part "analyze-deal" \
    --region "$AWS_REGION" \
    --query 'id' \
    --output text 2>/dev/null) || {
    ANALYZE_RESOURCE=$(aws apigateway get-resources \
        --rest-api-id "$API_ID" \
        --region "$AWS_REGION" \
        --query "items[?path=='/analyze-deal'].id" \
        --output text)
}

echo "  ✓ API Gateway created successfully"

# Step 5: Create Method Integrations
echo ""
echo "[5/6] Setting up API Gateway methods..."

# Get Lambda ARNs
ANALYZE_ARN=$(aws lambda get-function --function-name "$ANALYZE_LAMBDA_NAME" --region "$AWS_REGION" --query 'Configuration.FunctionArn' --output text)
PRESIGNED_ARN=$(aws lambda get-function --function-name "$PRESIGNED_LAMBDA_NAME" --region "$AWS_REGION" --query 'Configuration.FunctionArn' --output text)

# Create POST method for presigned-url
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$PRESIGNED_RESOURCE" \
    --http-method POST \
    --authorization-type NONE \
    --region "$AWS_REGION" 2>/dev/null || true

# Create integration for presigned-url
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$PRESIGNED_RESOURCE" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${PRESIGNED_ARN}/invocations" \
    --region "$AWS_REGION"

# Create POST method for analyze-deal
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$ANALYZE_RESOURCE" \
    --http-method POST \
    --authorization-type NONE \
    --region "$AWS_REGION" 2>/dev/null || true

# Create integration for analyze-deal
aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$ANALYZE_RESOURCE" \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${ANALYZE_ARN}/invocations" \
    --region "$AWS_REGION"

# Grant API Gateway permission to invoke Lambda functions
aws lambda add-permission \
    --function-name "$PRESIGNED_LAMBDA_NAME" \
    --statement-id "APIGatewayInvoke-presigned" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --region "$AWS_REGION" 2>/dev/null || true

aws lambda add-permission \
    --function-name "$ANALYZE_LAMBDA_NAME" \
    --statement-id "APIGatewayInvoke-analyze" \
    --action "lambda:InvokeFunction" \
    --principal apigateway.amazonaws.com \
    --region "$AWS_REGION" 2>/dev/null || true

echo "  ✓ API Gateway methods configured"

# Step 6: Deploy API
echo ""
echo "[6/6] Deploying API Gateway..."

DEPLOYMENT=$(aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name prod \
    --region "$AWS_REGION" \
    --query 'id' \
    --output text 2>/dev/null) || {
    echo "  - Updating existing deployment..."
    DEPLOYMENT=$(aws apigateway create-deployment \
        --rest-api-id "$API_ID" \
        --stage-name prod \
        --region "$AWS_REGION" \
        --query 'id' \
        --output text)
}

echo "  ✓ API deployed successfully"

# Output summary
echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration Summary:"
echo "  AWS Region:        $AWS_REGION"
echo "  S3 Bucket:         $S3_BUCKET_NAME"
echo "  Lambda Role:       $LAMBDA_ROLE_NAME"
echo "  Lambda Functions:  $ANALYZE_LAMBDA_NAME, $PRESIGNED_LAMBDA_NAME"
echo "  API Gateway ID:    $API_ID"
echo "  API Endpoint:      https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/prod"
echo ""
echo "Next Steps:"
echo "  1. Copy the API Endpoint above"
echo "  2. Open frontend/index.html in your browser"
echo "  3. Enter the API Endpoint in the Configuration section"
echo "  4. Enter S3 Bucket Name: $S3_BUCKET_NAME"
echo "  5. Upload a deal structure JSON file"
echo "  6. Click 'Explain My Deal' to see the AI analysis"
echo ""
echo "S3 Bucket Name to use: $S3_BUCKET_NAME"
