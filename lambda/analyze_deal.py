import json
import boto3
import logging
from datetime import datetime
from botocore.exceptions import ClientError
import os

# Initialize AWS clients
s3_client = boto3.client('s3')
bedrock_runtime = boto3.client('bedrock-runtime')

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Constants
MODEL_ID = "amazon.nova-pro-v1:0"  # Using Nova Pro for Bedrock
BEDROCK_REGION = os.environ.get('AWS_REGION', 'us-east-1')

def lambda_handler(event, context):
    """
    Main Lambda handler for analyzing deal structures with Bedrock
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Check if deal data is sent directly from frontend
        deal_structure = body.get('dealData')
        
        # If no deal data, try to fetch from S3
        if not deal_structure:
            s3_key = body.get('s3Key')
            s3_bucket = body.get('s3Bucket')
            
            if not s3_key or not s3_bucket:
                return error_response(400, "Missing dealData or s3Key/s3Bucket")
            
            # Fetch the deal structure from S3
            deal_structure = fetch_deal_from_s3(s3_bucket, s3_key)
        
        # Analyze with Bedrock
        explanation = analyze_deal_with_bedrock(deal_structure)
        
        return success_response(explanation)
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return error_response(500, str(e))


def fetch_deal_from_s3(bucket, key):
    """
    Fetch the deal structure JSON from S3 (fallback option)
    """
    try:
        logger.info(f"Fetching {key} from bucket {bucket}")
        
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        deal_data = json.loads(content)
        
        logger.info("Successfully fetched deal structure from S3")
        return deal_data
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"S3 Client error: {error_code}")
        raise Exception(f"Failed to fetch from S3: {error_code}")


def analyze_deal_with_bedrock(deal_structure):
    """
    Send deal structure to Bedrock Nova for analysis
    """
    try:
        # Create a detailed prompt for Claude
        prompt = create_analysis_prompt(deal_structure)
        
        logger.info("Sending deal to Bedrock for analysis")
        
        # Call Bedrock API
        response = bedrock_runtime.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                # "anthropic_version": "bedrock-2023-06-01",
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {
                                "text": prompt
                            }
                        ]
                    }
                ],
                "inferenceConfig": {
                    "maxTokens": 1000,
                    "temperature": 0.3
                }
            })
        )
        
        # Parse response - properly handle StreamingBody
        try:
            response_body_bytes = response['body'].read()
            response_body_str = response_body_bytes.decode('utf-8')
            response_body = json.loads(response_body_str)
            
            logger.info(f"Bedrock response: {response_body_str}")
            
            # Try to extract text from nested Bedrock Nova response format
            analysis_text = None
            
            # Format 1: Nested debug_response structure
            if response_body.get('debug_response'):
                try:
                    debug_resp = response_body['debug_response']
                    content_list = debug_resp['output']['message']['content']
                    if content_list and len(content_list) > 0:
                        analysis_text = content_list[0]['text']
                except (KeyError, IndexError, TypeError):
                    pass
            
            # Format 2: Direct output with message field
            if not analysis_text and response_body.get('output'):
                try:
                    output = response_body['output']
                    if isinstance(output, dict) and output.get('message'):
                        content_list = output['message']['content']
                        if content_list and len(content_list) > 0:
                            analysis_text = content_list[0]['text']
                except (KeyError, IndexError, TypeError):
                    pass
            
            # Format 3: Simple content array
            if not analysis_text and response_body.get('content'):
                try:
                    content_list = response_body['content']
                    if content_list and len(content_list) > 0:
                        analysis_text = content_list[0]['text']
                except (KeyError, IndexError, TypeError):
                    pass
            
            if not analysis_text:
                raise Exception(f"Could not extract text from Bedrock response. Response structure: {json.dumps(response_body, indent=2)}")
            
            # Format the output as HTML
            formatted_output = format_explanation(analysis_text)
            
            logger.info("Successfully analyzed deal with Bedrock")
            return formatted_output
            
        except (json.JSONDecodeError, KeyError, TypeError) as e:
            logger.error(f"Error parsing Bedrock response: {str(e)}", exc_info=True)
            raise Exception(f"Failed to parse Bedrock response: {str(e)}")
            
    except ClientError as e:
        error_msg = str(e)
        logger.error(f"Bedrock ClientError: {error_msg}", exc_info=True)
        raise Exception(f"Failed to analyze with Bedrock: {error_msg}")


def create_analysis_prompt(deal_structure):
    """
    Create a detailed prompt for Claude to analyze the deal
    """
    deal_str = json.dumps(deal_structure, indent=2)
    
    prompt = f"""You are an expert auto finance analyst. Analyze the following auto finance deal structure and provide a clear, easy-to-understand explanation in simple English that anyone can understand, even without financial background.

Deal Structure JSON:
{deal_str}

Please provide a comprehensive analysis covering:

1. **Deal Overview**: Brief summary of what type of deal this is
2. **The Vehicle**: What car is being financed
3. **The Buyer**: Who is buying this vehicle
4. **Financial Terms**: Explain the pricing and payment structure in simple terms
5. **Key Numbers**: Break down the important financial figures
6. **Monthly Commitment**: What the buyer will pay each month
7. **Deal Summary**: Key takeaways and important things to know

Format your response in clear sections with headers (use # for headers, **bold** for important terms).
Use simple language and avoid financial jargon. If you must use technical terms, explain them in simple words.
Be concise but comprehensive."""
    
    return prompt


def format_explanation(text):
    """
    Convert markdown-style text to HTML for better display
    """
    lines = text.split('\n')
    html_lines = []
    in_list = False
    
    for line in lines:
        # Handle headers
        if line.startswith('### '):
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append(f'<h3>{line.replace("### ", "")}</h3>')
        elif line.startswith('## '):
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append(f'<h2>{line.replace("## ", "")}</h2>')
        elif line.startswith('# '):
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append(f'<h1>{line.replace("# ", "")}</h1>')
        # Handle list items
        elif line.startswith('- ') or line.startswith('* '):
            if not in_list:
                html_lines.append('<ul>')
                in_list = True
            item_text = line.replace('- ', '').replace('* ', '')
            item_text = item_text.replace('**', '<strong>').replace('__', '<strong>')
            html_lines.append(f'<li>{item_text}</li>')
        # Handle empty lines (paragraphs)
        elif line.strip() == '':
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            html_lines.append('<br>')
        # Regular text
        else:
            if in_list:
                html_lines.append('</ul>')
                in_list = False
            # Replace bold markers
            line = line.replace('**', '<strong>').replace('__', '</strong>')
            if line.strip():
                html_lines.append(f'<p>{line}</p>')
    
    # Close any open list
    if in_list:
        html_lines.append('</ul>')
    
    html = '\n'.join(html_lines)
    return html


def success_response(data):
    """
    Return successful response
    """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': True,
            'explanation': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    }


def error_response(status_code, message):
    """
    Return error response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': False,
            'error': message,
            'timestamp': datetime.utcnow().isoformat()
        })
    }
