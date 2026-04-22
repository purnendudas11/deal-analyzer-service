import json
import boto3
import logging
from datetime import datetime
from botocore.exceptions import ClientError
import uuid

# Initialize AWS clients
s3_client = boto3.client('s3')

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda handler to generate presigned URL for S3 upload
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        file_name = body.get('fileName')
        content_type = body.get('contentType', 'application/json')
        bucket = body.get('bucket')
        
        if not file_name or not bucket:
            return error_response(400, "Missing fileName or bucket")
        
        # Generate presigned URL
        presigned_url = generate_presigned_url(bucket, file_name, content_type)
        
        return success_response({
            'presignedUrl': presigned_url,
            'fileKey': file_name,
            'bucket': bucket
        })
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return error_response(500, str(e))


def generate_presigned_url(bucket, key, content_type):
    """
    Generate a presigned URL for uploading to S3
    """
    try:
        logger.info(f"Generating presigned URL for {bucket}/{key}")
        
        url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket,
                'Key': key,
                'ContentType': content_type
            },
            ExpiresIn=3600  # URL valid for 1 hour
        )
        
        logger.info("Presigned URL generated successfully")
        return url
        
    except ClientError as e:
        logger.error(f"S3 error: {str(e)}")
        raise Exception(f"Failed to generate presigned URL: {str(e)}")


def success_response(data):
    """Return successful response"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'success': True,
            'data': data,
            'timestamp': datetime.utcnow().isoformat()
        })
    }


def error_response(status_code, message):
    """Return error response"""
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
