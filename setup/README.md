# Cloud Connect

## Description
This project demonstrates a simple AWS infrastructure setup using CloudFormation, featuring an Application Load Balancer (ALB) that routes traffic to a Fargate service running an NGINX container.

## Architecture
- **VPC** with public and private subnets across 2 availability zones
- **Application Load Balancer (ALB)** in public subnets for internet-facing traffic
- **ECS Fargate Service** running in private subnets with a single NGINX container
- **NAT Gateway** for outbound internet access from private subnets
- **Security Groups** configured for proper traffic flow

## Prerequisites

### 1. AWS Account & Credentials
You need an AWS account with programmatic access configured.

### 2. Required AWS Permissions
Your AWS user/role needs the following permissions to deploy this stack:

#### Essential Permissions (Minimum Required):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "ec2:*",
                "ecs:*",
                "elasticloadbalancing:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "logs:CreateLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Recommended: Use AWS Managed Policy with Administrative Access (Not Recommended for Production)
For simplicity, you can use the AWS managed policy:
- **`AdministratorAccess`** - Full access to all AWS services

### 3. AWS CLI Installation
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download and run the MSI installer from AWS documentation
```

### 4. AWS CLI Configuration

#### Option A: Configure Default Profile
```bash
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter output format (json)
```

#### Option B: Configure Named Profile
```bash
aws configure --profile myprofile
# Follow the same prompts as above
```

#### Option C: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your-access-key-here
export AWS_SECRET_ACCESS_KEY=your-secret-key-here
export AWS_DEFAULT_REGION=us-east-1
```

### 5. Test Your Configuration
```bash
# Test default profile
aws sts get-caller-identity

# Test named profile
aws sts get-caller-identity --profile myprofile

# Set profile for session
export AWS_PROFILE=myprofile
aws sts get-caller-identity
```

## Quick Deployment

### Deploy the stack:
```bash
# Using default profile
./deploy.sh

# Using named profile
./deploy.sh my-stack-name us-east-1 myprofile

# With custom parameters
./deploy.sh my-test-stack us-west-2 production
```

### Parameters:
- `stack-name` (optional): Name for your CloudFormation stack (default: `cloud-connect-example`)
- `region` (optional): AWS region to deploy to (default: `us-east-1`)
- `profile` (optional): AWS CLI profile to use (default: uses default profile or AWS_PROFILE env var)

### Clean up resources:
```bash
# Using default profile
./cleanup.sh

# Using named profile
./cleanup.sh my-stack-name us-east-1 myprofile
```

## Manual Deployment
If you prefer to deploy manually:

```bash
# With default profile
aws cloudformation deploy \
  --template-file cloudformation-alb-fargate.yaml \
  --stack-name your-stack-name \
  --region your-region \
  --capabilities CAPABILITY_IAM

# With named profile
aws cloudformation deploy \
  --template-file cloudformation-alb-fargate.yaml \
  --stack-name your-stack-name \
  --region your-region \
  --profile your-profile-name \
  --capabilities CAPABILITY_IAM
```

## What Gets Created
- **1 VPC** with Internet Gateway
- **4 Subnets** (2 public, 2 private across 2 AZs)
- **1 NAT Gateway** with Elastic IP
- **Route tables** and associations
- **Security groups** for ALB and ECS
- **Application Load Balancer** with listener
- **ECS Cluster** with Fargate service (1 task)
- **Task definition** running NGINX container
- **Target group** for load balancer routing
- **CloudWatch log group** for container logs
- **IAM role** for ECS task execution

## Accessing the Application
After deployment, the ALB URL will be displayed in the output. The NGINX welcome page should be accessible via HTTP on port 80.

Example: `http://CloudConnect-ALB-1234567890.us-east-1.elb.amazonaws.com`

## Cost Considerations
This setup includes billable resources:
- **NAT Gateway**: ~$45/month + data processing fees
- **Application Load Balancer**: ~$22/month + LCU charges
- **Fargate**: ~$13/month for 1 task (0.25 vCPU, 0.5 GB RAM)
- **Data Transfer**: Varies based on usage

**Estimated total: ~$80-100/month if left running continuously**

💡 **Cost-saving tip**: Use `./cleanup.sh` when not actively using the environment!

## Troubleshooting

### Common Issues:

#### 1. AWS Credentials Not Configured
```
Error: AWS credentials not configured or invalid.
```
**Solution**: Run `aws configure` or `aws configure --profile myprofile`

#### 2. Insufficient Permissions
```
User: arn:aws:iam::123456789012:user/myuser is not authorized to perform: iam:CreateRole
```
**Solution**: Ensure your user has the required permissions listed above

#### 3. Stack Already Exists
```
Stack with id cloud-connect-example already exists
```
**Solution**: Use a different stack name or delete the existing stack first

#### 4. Region Capacity Issues
```
Cannot create cluster: specified availability-zone does not support the requested instance type
```
**Solution**: Try a different region (us-east-1, us-west-2 are usually reliable)

#### 5. VPC Limits Exceeded
```
The maximum number of VPCs has been reached
```
**Solution**: Delete unused VPCs or request a limit increase from AWS

### Getting Help:
- Check AWS CloudFormation events in the console for detailed error messages
- Ensure you're using a supported region
- Verify your AWS account has no billing issues
- Check service quotas in the AWS console

## Security Notes
- Containers run in private subnets with no direct internet access
- Load balancer security group only allows HTTP/HTTPS traffic
- ECS security group only accepts traffic from the load balancer
- All resources are isolated within a dedicated VPC
- IAM roles follow least-privilege principles

## Customization
To modify the setup:
1. Edit `cloudformation-alb-fargate.yaml`
2. Update container image, ports, or resource allocation
3. Modify security groups or networking configuration
4. Redeploy with `./deploy.sh`