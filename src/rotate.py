import botocore
import boto3
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()


def lambda_handler(event, context):
    secretmanager_client = boto3.client('secretsmanager')
    grafana_client = boto3.client('grafana')

    grafana_secret_arn = os.environ['GRAFANA_API_SECRET_ARN']
    grafana_api_key_name = os.environ['GRAFANA_API_KEY_NAME']
    grafana_workspace_id = os.environ['GRAFANA_WORKSPACE_ID']

    # Delete key if exists
    try:
        grafana_client.delete_workspace_api_key(
            keyName=grafana_api_key_name,
            workspaceId=grafana_workspace_id
        )
    except grafana_client.exceptions.ResourceNotFoundException:
        pass

    # Generate new API key
    try:
        new_api_key = grafana_client.create_workspace_api_key(
            keyName=grafana_api_key_name,
            keyRole='ADMIN',
            secondsToLive=2592000,
            workspaceId=grafana_workspace_id
        )['key']
    except botocore.exceptions.ClientError as error:
        logger.error(error)
        return {
            'statusCode': 500,
            'message': 'Error: Failed to generate new API key'
        }

    # Update the secret with the new API key
    try:
        secretmanager_client.update_secret(
            SecretId=grafana_secret_arn,
            SecretString=new_api_key
        )
    except botocore.exceptions.ClientError as error:
        logger.error(error)
        return {
            'statusCode': 500,
            'message': 'Error: Failed to update secret'
        }

    return {
        'statusCode': 200,
        'message': 'Success: Secret rotated successfully'
    }
