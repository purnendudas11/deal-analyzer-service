# Common AWS CLI Commands for Deal Analyzer POC

## View Project Resources

### List S3 Buckets
aws s3 ls

### List Specific Bucket Contents
aws s3 ls deal-structure-bucket-[timestamp]/deals/

### List Lambda Functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `deal`)]'

### List API Gateways
aws apigateway get-rest-apis --query 'items[?name==`deal-analyzer-api`]'

## Monitoring & Logs

### View Lambda Logs - Real-time
aws logs tail /aws/lambda/analyze-deal-with-bedrock --follow
aws logs tail /aws/lambda/generate-presigned-url --follow

### View Lambda Logs - Last 10 minutes
aws logs tail /aws/lambda/analyze-deal-with-bedrock --since 10m

### Get Lambda Function Details
aws lambda get-function --function-name analyze-deal-with-bedrock
aws lambda get-function-configuration --function-name analyze-deal-with-bedrock

### Get Lambda Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=analyze-deal-with-bedrock \
  --start-time 2024-04-21T00:00:00Z \
  --end-time 2024-04-21T23:59:59Z \
  --period 3600 \
  --statistics Average,Maximum

## S3 Operations

### Download File from S3
aws s3 cp s3://deal-structure-bucket-[timestamp]/deals/[filename] ./

### Upload File to S3
aws s3 cp ./deal-structure.json s3://deal-structure-bucket-[timestamp]/deals/

### List Bucket Versioning Status
aws s3api get-bucket-versioning --bucket deal-structure-bucket-[timestamp]

### List Object Versions
aws s3api list-object-versions --bucket deal-structure-bucket-[timestamp] --prefix deals/

### Restore Previous Version
aws s3api get-object \
  --bucket deal-structure-bucket-[timestamp] \
  --key deals/[filename] \
  --version-id [version-id] \
  ./[filename]

## Lambda Management

### Update Lambda Code
aws lambda update-function-code \
  --function-name analyze-deal-with-bedrock \
  --zip-file fileb://function.zip

### Update Lambda Configuration
aws lambda update-function-configuration \
  --function-name analyze-deal-with-bedrock \
  --timeout 90 \
  --memory-size 512

### Test Lambda Function Locally
aws lambda invoke \
  --function-name analyze-deal-with-bedrock \
  --payload '{
    "s3Key": "deals/test-deal.json",
    "s3Bucket": "deal-structure-bucket-xxx",
    "region": "us-east-1"
  }' \
  response.json && cat response.json | jq .

### Get Lambda Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=analyze-deal-with-bedrock \
  --start-time 2024-04-20T00:00:00Z \
  --end-time 2024-04-21T23:59:59Z \
  --period 86400 \
  --statistics Sum

## API Gateway

### Get API ID
aws apigateway get-rest-apis --query 'items[?name==`deal-analyzer-api`].id' --output text

### Get API Resources
aws apigateway get-resources --rest-api-id [api-id]

### Get API Methods
aws apigateway get-method --rest-api-id [api-id] --resource-id [resource-id] --http-method POST

### Test API Manually
curl -X POST https://[api-id].execute-api.us-east-1.amazonaws.com/prod/presigned-url \
  -H "Content-Type: application/json" \
  -d '{
    "fileName": "test/demo.json",
    "contentType": "application/json",
    "bucket": "deal-structure-bucket-xxx"
  }'

## IAM Management

### List IAM Role
aws iam get-role --role-name deal-analyzer-lambda-role

### View IAM Role Policies
aws iam list-role-policies --role-name deal-analyzer-lambda-role

### View Specific Policy
aws iam get-role-policy \
  --role-name deal-analyzer-lambda-role \
  --policy-name deal-analyzer-policy

### Update IAM Role Policy
aws iam put-role-policy \
  --role-name deal-analyzer-lambda-role \
  --policy-name deal-analyzer-policy \
  --policy-document file://updated-policy.json

## CloudFormation

### Create Stack
aws cloudformation create-stack \
  --stack-name deal-analyzer-poc \
  --template-body file://cloudformation-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM

### Describe Stack Status
aws cloudformation describe-stacks --stack-name deal-analyzer-poc

### Get Stack Outputs
aws cloudformation describe-stacks \
  --stack-name deal-analyzer-poc \
  --query 'Stacks[0].Outputs'

### Update Stack
aws cloudformation update-stack \
  --stack-name deal-analyzer-poc \
  --template-body file://cloudformation-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM

### Delete Stack
aws cloudformation delete-stack --stack-name deal-analyzer-poc

### Monitor Stack Deletion
aws cloudformation describe-stacks --stack-name deal-analyzer-poc --query 'Stacks[0].StackStatus'

## Bedrock

### List Available Models
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)]'

### Check Model Access
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-sonnet-20240229-v1:0 \
  --region us-east-1

### List Model Access
aws bedrock list-foundation-models \
  --region us-east-1 \
  --by-provider Anthropic

## Cost Analysis

### Get Cost and Usage
aws ce get-cost-and-usage \
  --time-period Start=2024-04-01,End=2024-04-30 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

### Get Cost by Service
aws ce get-cost-and-usage \
  --time-period Start=2024-04-01,End=2024-04-30 \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{
    "Tags": {
      "Key": "Application",
      "Values": ["DealAnalyzer"]
    }
  }'

## Cleanup Commands

### Delete Lambda Functions
aws lambda delete-function --function-name analyze-deal-with-bedrock
aws lambda delete-function --function-name generate-presigned-url

### Delete S3 Bucket (empty it first)
aws s3 rm --recursive s3://deal-structure-bucket-xxx/
aws s3api delete-bucket --bucket deal-structure-bucket-xxx

### Delete IAM Role
aws iam delete-role-policy --role-name deal-analyzer-lambda-role --policy-name deal-analyzer-policy
aws iam delete-role --role-name deal-analyzer-lambda-role

### Delete API Gateway
aws apigateway delete-rest-api --rest-api-id [api-id]

## Troubleshooting Commands

### Check AWS CLI Configuration
aws configure list

### Verify Credentials Work
aws sts get-caller-identity

### Check Bedrock API Access
aws bedrock describe-foundation-model \
  --model-identifier anthropic.claude-3-sonnet-20240229-v1:0 \
  --region us-east-1

### Check Lambda Permissions
aws lambda get-policy --function-name analyze-deal-with-bedrock

### View Lambda Environment Variables
aws lambda get-function-configuration \
  --function-name analyze-deal-with-bedrock \
  --query 'Environment'

### Test S3 Permissions
aws s3api head-bucket --bucket deal-structure-bucket-xxx

### Check Lambda Execution Role
aws iam get-role --role-name deal-analyzer-lambda-role --query 'Role.AssumeRolePolicyDocument'

---

For more commands: `aws [service] help` or `aws [service] [command] help`
