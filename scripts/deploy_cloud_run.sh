#!/bin/bash
# Deploy to Google Cloud Run (assumes gcloud CLI is installed and configured)
# Usage: ./deploy_cloud_run.sh <PROJECT_ID> <REGION>

PROJECT_ID=$1
REGION=$2
SERVICE_NAME=care-connect-backend

if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Usage: $0 <PROJECT_ID> <REGION>"
  exit 1
fi

gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars OPENAI_API_KEY=$OPENAI_API_KEY,ALLOWED_ORIGINS=$ALLOWED_ORIGINS,PORT=5000
