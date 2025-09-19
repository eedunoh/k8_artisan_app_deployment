import json
import boto3
import os

sns = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']  # This has been set in the lambda terraform file as an environment variable

def lambda_handler(event, context):
    record = event['Records'][0]
    
    bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']
    event_name = record['eventName']
    event_time = record['eventTime']

    message = (
        f"New S3 Event\n"
        f"Event: {event_name}\n"
        f"Time: {event_time}\n"
        f"Bucket: {bucket}\n"
        f"Object Key: {key}"
    )

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="Artisan S3 Upload Notification - You Have A New Job",
        Message=message
    )

    return {
        'statusCode': 200,
        'body': json.dumps('Notification sent successfully')
    }
