#!/bin/bash

# Simple deployment script for CloudFormation template
# Usage: ./deploy.sh [stack-name] [region] [profile]

STACK_NAME=${1:-cloud-connect-example}
REGION=${2:-us-east-1}
AWS_PROFILE=${3}
TEMPLATE_FILE="cloudformation-alb-fargate.yaml"

echo "Deploying CloudFormation stack: $STACK_NAME"
echo "Region: $REGION"
echo "Template: $TEMPLATE_FILE"
if [ ! -z "$AWS_PROFILE" ]; then
    echo "AWS Profile: $AWS_PROFILE"
fi
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file $TEMPLATE_FILE not found."
    exit 1
fi

# Build AWS CLI command with optional profile
AWS_CMD="aws cloudformation deploy"
if [ ! -z "$AWS_PROFILE" ]; then
    AWS_CMD="$AWS_CMD --profile $AWS_PROFILE"
fi

# Test AWS credentials
echo "Testing AWS credentials..."
if [ ! -z "$AWS_PROFILE" ]; then
    CALLER_IDENTITY=$(aws sts get-caller-identity --profile "$AWS_PROFILE" 2>/dev/null)
else
    CALLER_IDENTITY=$(aws sts get-caller-identity 2>/dev/null)
fi

if [ $? -ne 0 ]; then
    echo "Error: AWS credentials not configured or invalid."
    echo ""
    echo "Please run one of the following:"
    echo "  aws configure                    # Configure default profile"
    echo "  aws configure --profile myprofile # Configure named profile"
    echo "  export AWS_PROFILE=myprofile     # Use existing profile"
    exit 1
fi

echo "✓ AWS credentials validated"
echo "Account: $(echo $CALLER_IDENTITY | jq -r '.Account // "Unknown"')"
echo "User/Role: $(echo $CALLER_IDENTITY | jq -r '.Arn // "Unknown"')"
echo ""

# Deploy the stack
echo "Deploying stack..."
$AWS_CMD \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides EnvironmentName="$STACK_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Stack deployed successfully!"
    echo ""
    
    # Get the ALB URL
    if [ ! -z "$AWS_PROFILE" ]; then
        ALB_URL=$(aws cloudformation describe-stacks \
          --stack-name "$STACK_NAME" \
          --region "$REGION" \
          --profile "$AWS_PROFILE" \
          --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
          --output text 2>/dev/null)
    else
        ALB_URL=$(aws cloudformation describe-stacks \
          --stack-name "$STACK_NAME" \
          --region "$REGION" \
          --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerUrl`].OutputValue' \
          --output text 2>/dev/null)
    fi
    
    if [ ! -z "$ALB_URL" ]; then
        echo "🌐 Application Load Balancer URL: $ALB_URL"
        echo ""
        echo "Note: It may take a few minutes for the service to become healthy."
        echo "You can check the status in the AWS Console under:"
        echo "  - ECS > Clusters > $STACK_NAME-cluster"
        echo "  - EC2 > Load Balancers"
    fi
    
    echo ""
    echo "To clean up resources later, run:"
    echo "  ./cleanup.sh $STACK_NAME $REGION${AWS_PROFILE:+ $AWS_PROFILE}"
else
    echo ""
    echo "❌ Stack deployment failed!"
    echo "Check the CloudFormation events in AWS Console for details:"
    echo "  https://$REGION.console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks"
    exit 1
fi