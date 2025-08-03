import json
import boto3
import os
import uuid
import logging
from datetime import datetime, timedelta, timezone

# Initialize the DynamoDB client
#dynamodb = boto3.resource('dynamodb')
#table_name = os.environ['TABLE_NAME']
#table = dynamodb.Table(table_name)
# Initialize the SNS client
sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')


# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)  # or DEBUG, ERROR, etc.

events = boto3.client('events')
# Generate a unique UUID for the item
uuid = str(uuid.uuid4())

def lambda_handler(event, context):
    try:
        logger.debug(f"Event: {event}")
        body = json.loads(event['body'])

#	"valid": true,
#	"value": 12,
#	"description": "5W40 motor oil",
#	"buyer": "Hristo"
        current_timestamp = datetime.now().isoformat()
        isValid = body.get('valid', True)
        if not isValid:
            logger.info("Invalid item data")
            # Save the item to DynamoDB
#            item = {
#                'PK': f"item#{uuid}",
#                'SK': f"item#{uuid}",
#                'valid': body['valid'],
#                'value': body['value'],
#                'description': body['description'],
#                'buyer': body['buyer'],
#                'timestamp': current_timestamp
#            }
#            table.put_item(Item=item)
#            logger.info(f"Item saved: {item}")
        else:
            logger.info("Item data is valid")
            valid= body['valid']
            value=body['value']
            description=body['description']
            buyer=body['buyer']

            # Format the subject and message for the SNS notification.
            subject = f"JSON is valid :"
            message = (
                f"Details:\n\n"
                f"value: {value}\n"
                f"description: {description}\n"
                f"buyer: {buyer}\n\n"
                f"on {current_timestamp} the item was received.\n"
            )
            # Publish the message to the SNS topic.
            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message,
                Subject=subject
            )
            logger.info(f"Successfully published message to SNS. MessageId: {response['MessageId']}")






        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Item was processing', 'valid: ': isValid})
        }
    except Exception as e:
        logger.error(f"Error saving item: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }
