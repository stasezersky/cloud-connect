#!/bin/bash

# Cleanup script for CloudFormation stack
# Usage: ./cleanup.sh [stack-name] [region] [profile]

STACK_NAME=${1:-cloud-connect-example}
REGION=${2:-us-east-1}
AWS_PROFILE=${3}

echo "Deleting CloudFormation stack: $STACK_NAME"
echo "Region: $REGION"
if [ ! -z "$AWS_PROFILE" ]; then
    echo "AWS Profile: $AWS_PROFILE"
fi
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
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
echo ""

# Check if stack exists
echo "Checking if stack exists..."
if [ ! -z "$AWS_PROFILE" ]; then
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --profile "$AWS_PROFILE" &>/dev/null
else
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &>/dev/null
fi

if [ $? -ne 0 ]; then
    echo "Stack $STACK_NAME does not exist or is already deleted."
    exit 0
fi

echo "✓ Stack found"
echo ""

# Confirm deletion
echo "⚠️  WARNING: This will delete all resources in the stack!"
echo "Resources to be deleted:"
echo "  - VPC and all networking components"
echo "  - Application Load Balancer"
echo "  - ECS Cluster and Fargate service"
echo "  - NAT Gateway (will stop charges)"
echo "  - CloudWatch Log Group"
echo "  - All associated security groups and IAM roles"
echo ""

read -p "Are you sure you want to delete stack '$STACK_NAME'? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deletion cancelled."
    exit 0
fi

# Delete the stack
echo ""
echo "Deleting stack... This may take several minutes."
if [ ! -z "$AWS_PROFILE" ]; then
    aws cloudformation delete-stack \
      --stack-name "$STACK_NAME" \
      --region "$REGION" \
      --profile "$AWS_PROFILE"
else
    aws cloudformation delete-stack \
      --stack-name "$STACK_NAME" \
      --region "$REGION"
fi

if [ $? -eq 0 ]; then
    echo "✓ Stack deletion initiated."
    echo ""
    echo "You can monitor the progress in the AWS Console:"
    echo "  https://$REGION.console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks"
    echo ""
    
    # Wait for stack deletion to complete (optional)
    echo "Waiting for stack deletion to complete..."
    echo "(This may take 5-15 minutes. You can press Ctrl+C to stop waiting without canceling the deletion)"
    
    if [ ! -z "$AWS_PROFILE" ]; then
        aws cloudformation wait stack-delete-complete \
          --stack-name "$STACK_NAME" \
          --region "$REGION" \
          --profile "$AWS_PROFILE"
    else
        aws cloudformation wait stack-delete-complete \
          --stack-name "$STACK_NAME" \
          --region "$REGION"
    fi
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Stack deleted successfully!"
        echo "All AWS resources have been cleaned up and billing has stopped."
    else
        echo ""
        echo "⚠️  Stack deletion may have failed or is taking longer than expected."
        echo "Please check the AWS Console for the current status."
    fi
else
    echo "❌ Failed to initiate stack deletion!"
    exit 1
fi