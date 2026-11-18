@'
# Check-RdsCustomNetwork.ps1
# Validates network prerequisites for RDS Custom for SQL Server on an EC2 instance.

function Get-InstanceMetadata {
    param ([string]$Path)
    try {
        $token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri "http://169.254.169.254/latest/api/token"
        $metadata = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri "http://169.254.169.254/latest/meta-data/$Path"
        return $metadata
    }
    catch {
        Write-Host "Error accessing instance metadata: $_" -ForegroundColor Red
        return $null
    }
}

try {
    $instanceId = Get-InstanceMetadata "instance-id"
    $vpcId = Get-InstanceMetadata "network/interfaces/macs/$(Get-InstanceMetadata "network/interfaces/macs/")/vpc-id"
    Write-Host "`n=== Current Instance Information ===" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor Green
    Write-Host "VPC ID: $vpcId" -ForegroundColor Green
}
catch {
    Write-Host "Error getting instance metadata. Please ensure you're running this script on an EC2 instance." -ForegroundColor Red
    exit
}

Write-Host "`n=== VPC Security Group and Network ACL Requirements ===" -ForegroundColor Cyan
Write-Host "Checking required port configurations..." -ForegroundColor Yellow
$requiredPorts = @(
    @{ Port = 443; Protocol = "TCP"; Direction = "Outbound"; Description = "Required for VPC endpoint access" },
    @{ Port = 443; Protocol = "TCP"; Direction = "Outbound"; Description = "Required for Amazon S3 gateway endpoint access" },
    @{ Port = 1433; Protocol = "TCP"; Direction = "Both"; Description = "Required for Multi-AZ SQL Server setup" },
    @{ Port = 1120; Protocol = "TCP"; Direction = "Both"; Description = "Required for Multi-AZ SQL Server setup" },
    @{ PortRange = "0-65535"; Protocol = "TCP"; Direction = "Inbound"; Description = "Required in private network ACL for DB instance subnet" }
)
foreach ($req in $requiredPorts) {
    Write-Host "`nPort Requirement:" -ForegroundColor Yellow
    if ($req.PortRange) { Write-Host "- Port Range: $($req.PortRange)" -ForegroundColor Green }
    else { Write-Host "- Port: $($req.Port)" -ForegroundColor Green }
    Write-Host "- Protocol: $($req.Protocol)" -ForegroundColor Green
    Write-Host "- Direction: $($req.Direction)" -ForegroundColor Green
    Write-Host "- Purpose: $($req.Description)" -ForegroundColor Green
}

Write-Host "`n=== Required VPC Endpoints for RDS Custom SQL Server ===" -ForegroundColor Cyan
$requiredEndpoints = @(
    @{ Name = "monitoring"; Description = "Amazon CloudWatch Monitoring"; Purpose = "Required for CloudWatch monitoring integration"; ServiceName = "com.amazonaws.region.monitoring" },
    @{ Name = "logs"; Description = "Amazon CloudWatch Logs"; Purpose = "Required for CloudWatch Logs integration"; ServiceName = "com.amazonaws.region.logs" },
    @{ Name = "events"; Description = "Amazon CloudWatch Events/EventBridge"; Purpose = "Required for event management and notifications"; ServiceName = "com.amazonaws.region.events" },
    @{ Name = "ec2"; Description = "Amazon EC2"; Purpose = "Required for EC2 API operations"; ServiceName = "com.amazonaws.region.ec2" },
    @{ Name = "ec2messages"; Description = "Amazon EC2 Messages"; Purpose = "Required for EC2 communication"; ServiceName = "com.amazonaws.region.ec2messages" },
    @{ Name = "s3"; Description = "Amazon S3"; Purpose = "Required for S3 bucket access"; ServiceName = "com.amazonaws.region.s3" },
    @{ Name = "secretsmanager"; Description = "AWS Secrets Manager"; Purpose = "Required for secrets management"; ServiceName = "com.amazonaws.region.secretsmanager" },
    @{ Name = "ssm"; Description = "AWS Systems Manager"; Purpose = "Required for Systems Manager operations"; ServiceName = "com.amazonaws.region.ssm" },
    @{ Name = "ssmmessages"; Description = "AWS Systems Manager Messages"; Purpose = "Required for Systems Manager communication"; ServiceName = "com.amazonaws.region.ssmmessages" }
)
Write-Host "Checking VPC endpoints in VPC: $vpcId..." -ForegroundColor Yellow
Write-Host "These endpoints