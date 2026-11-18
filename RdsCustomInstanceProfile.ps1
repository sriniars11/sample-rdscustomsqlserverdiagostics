# RDS Custom IAM Instance Profile Policy Checker
# Validates whether an IAM policy has the required permissions for RDS Custom

# Define your IAM policy here (paste the policy JSON you want to validate)
$policyJson = @'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ssmAgentPermission1",
      "Effect": "Allow",
      "Action": ["ssm:UpdateInstanceInformation"],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/AWSRDSCustom": ["custom-oracle", "custom-sqlserver", "custom-oracle-rac"]
        }
      }
    },
    {
      "Sid": "ssmAgentPermission2",
      "Effect": "Allow",
      "Action": ["ssm:GetManifest", "ssm:PutConfigurePackageResult"],
      "Resource": "*"
    },
    {
      "Sid": "ssmAgentPermission3",
      "Effect": "Allow",
      "Action": ["ssm:GetDocument"],
      "Resource": "arn:aws:ssm:*:*:document/*"
    },
    {
      "Sid": "ssmAgentPermission4",
      "Effect": "Allow",
      "Action": ["ssmmessages:CreateControlChannel", "ssmmessages:OpenControlChannel"],
      "Resource": "*"
    },
    {
      "Sid": "ssmAgentPermission5",
      "Effect": "Allow",
      "Action": [
        "ec2messages:AcknowledgeMessage",
        "ec2messages:DeleteMessage",
        "ec2messages:FailMessage",
        "ec2messages:GetEndpoint",
        "ec2messages:GetMessages",
        "ec2messages:SendReply"
      ],
      "Resource": "*"
    },
    {
      "Sid": "createEc2SnapshotPermission1",
      "Effect": "Allow",
      "Action": ["ec2:CreateSnapshot", "ec2:CreateSnapshots"],
      "Resource": ["arn:aws:ec2:*:*:volume/*"],
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/AWSRDSCustom": ["custom-oracle", "custom-sqlserver", "custom-oracle-rac"]
        }
      }
    },
    {
      "Sid": "createEc2SnapshotPermission2",
      "Effect": "Allow",
      "Action": ["ec2:CreateSnapshot", "ec2:CreateSnapshots"],
      "Resource": ["arn:aws:ec2:*::snapshot/*"],
      "Condition": {
        "StringLike": {
          "aws:RequestTag/AWSRDSCustom": ["custom-oracle", "custom-sqlserver", "custom-oracle-rac"]
        }
      }
    },
    {
      "Sid": "createEc2SnapshotPermission3",
      "Effect": "Allow",
      "Action": "ec2:CreateSnapshots",
      "Resource": ["arn:aws:ec2:*:*:instance/*"],
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/AWSRDSCustom": ["custom-oracle", "custom-sqlserver", "custom-oracle-rac"]
        }
      }
    },
    {
      "Sid": "createTagForEc2SnapshotPermission",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/AWSRDSCustom": ["custom-oracle", "custom-sqlserver", "custom-oracle-rac"],
          "ec2:CreateAction": ["CreateSnapshot", "CreateSnapshots"]
        }
      }
    },
    {
      "Sid": "rdsCustomS3ObjectPermission",
      "Effect": "Allow",
      "Action": [
        "s3:putObject",
        "s3:getObject",
        "s3:getObjectVersion",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": ["arn:aws:s3:::do-not-delete-rds-custom-*/*"],
      "Condition": {
        "StringEquals": { "aws:ResourceAccount": "${aws:PrincipalAccount}" }
      }
    },
    {
      "Sid": "rdsCustomS3BucketPermission",
      "Effect": "Allow",
      "Action": ["s3:ListBucketVersions", "s3:ListBucketMultipartUploads"],
      "Resource": ["arn:aws:s3:::do-not-delete-rds-custom-*"],
      "Condition": {
        "StringEquals": { "aws:ResourceAccount": "${aws:PrincipalAccount}" }
      }
    },
    {
      "Sid": "readSecretsFromCpPermission",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:do-not-delete-rds-custom-*",
        "arn:aws:secretsm