import boto3
import time
import os
import logging
from datetime import datetime, timedelta, timezone, time

# Initialize the DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['TABLE_NAME']
table = dynamodb.Table(table_name)
# Initialize the SNS client
sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)  # or DEBUG, ERROR, etc.



def lambda_handler(event, context):
#    now = int(time.time())

    deleted_time = datetime.now() - timedelta(minutes=3)
    logger.info(f"deleted_time: ${deleted_time}")
    items_to_delete = table.scan(
        FilterExpression="item_timestamp <= :deleted_time",
        ExpressionAttributeValues={":deleted_time": deleted_time.isoformat() + "Z"}  # DynamoDB expects ISO 8601 format
    ).get("Items", [])

    for item in items_to_delete:
        value = item.get('value')
        description = item.get('description')
        buyer = item.get('buyer')
        item_timestamp = item.get('item_timestamp')

        logger.info(f"Item to delete: {item} ")
        logger.info(f"deleted_time  : {deleted_time.isoformat()}")
        logger.info(f"item_timestamp: {item_timestamp}")
        d1 = datetime.strptime(deleted_time.isoformat(), '%Y-%m-%dT%H:%M:%S.%f')
        d2 = datetime.strptime(item_timestamp, '%Y-%m-%dT%H:%M:%S.%f')
        diff = (d2 - d1).total_seconds() / 60 + 180
        logger.info(f"diff in minute: {diff}")
        # Delete the item from DynamoDB.
        table.delete_item(Key={
            'PK': item['PK'],
            'SK': item['SK']
            })
        # Format the subject and message for the SNS notification.
        subject = f"Item is deleted:"
        message = (
            f"Details:\n\n"
            f"value: {value}\n"
            f"description: {description}\n"
            f"buyer: {buyer}\n\n"
            f"stay in base {diff} the item was received.\n"
        )
        # Publish the message to the SNS topic.
        #response = sns_client.publish(
        #    TopicArn=SNS_TOPIC_ARN,
        #    Message=message,
        #    Subject=subject
        #)
        logger.info(f"Successfully published message to SNS. Message: {message}")
        #logger.info(f"Successfully published message to SNS. MessageId: {response['MessageId']}")
