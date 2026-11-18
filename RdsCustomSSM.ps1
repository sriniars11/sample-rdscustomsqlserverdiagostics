  function Get-SSMDiagnostics { 
    # Check SSM Agent Service Status 
    $requiredServices = @( 
        "AmazonSSMAgent", 
        "WinRM",                # Windows Remote Management 
        "LanmanServer",         # Server Service 
        "RpcSs",               # Remote Procedure Call 
        "RpcEptMapper",        # RPC Endpoint Mapper 
        "gpsvc",               # Group Policy Client 
        "iphlpsvc",            # IP Helper 
        "W32Time"              # Windows Time 
    ) 
 
    Write-Host "`nChecking Required Windows Services:" 
    Write-Host "--------------------------------" 
    foreach ($serviceName in $requiredServices) { 
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue 
        if ($service) { 
            $statusColor = if ($service.Status -eq "Running") { "Green" } else { "Red" } 
            Write-Host "${serviceName}: " -NoNewline 
            Write-Host $service.Status -ForegroundColor $statusColor 
        } else { 
            Write-Host "${serviceName} - Not Found" -ForegroundColor Red 
        } 
    } 
 
    # Check SSM endpoint connectivity 
    $ssmEndpoints = @( 
        "ssm.us-east-1.amazonaws.com", 
        "ssmmessages.us-east-1.amazonaws.com", 
        "ec2messages.us-east-1.amazonaws.com", 
        "s3.us-east-1.amazonaws.com", 
        "logs.us-east-1.amazonaws.com" 
    ) 
 
    Write-Host "`nTesting SSM Endpoints Connectivity:" 
    Write-Host "--------------------------------" 
    foreach ($endpoint in $ssmEndpoints) { 
        try { 
            $test = Test-NetConnection -ComputerName $endpoint -Port 443 -WarningAction SilentlyContinue 
            $status = if ($test.TcpTestSucceeded) { "Success" } else { "Failed" } 
            $statusColor = if ($status -eq "Success") { "Green" } else { "Red" } 
             
           Write-Host "${endpoint} - " -NoNewline 
            Write-Host $status -ForegroundColor $statusColor 
        } 
        catch { 
            Write-Host "${endpoint} - Failed (Error: $_)" -ForegroundColor Red 
        } 
    } 
 
    # Check SSM Agent Logs 
    $logPaths = @( 
        "C:\ProgramData\Amazon\SSM\Logs\amazon-ssm-agent.log", 
        "C:\ProgramData\Amazon\SSM\Logs\errors.log" 
    ) 
 
    Write-Host "`nChecking SSM Agent Logs:" 
    Write-Host "----------------------" 
    foreach ($logPath in $logPaths) { 
        if (Test-Path $logPath) { 
            Write-Host "`nRecent entries from ${logPath}" 
            try { 
                Get-Content $logPath -Tail 5 | ForEach-Object { 
                    Write-Host $_ 
                } 
            } 
            catch { 
                Write-Host "Unable to read log file: $_" -ForegroundColor Yellow 
            } 
        } 
        else { 
            Write-Host "Log file not found: ${logPath}" -ForegroundColor Yellow 
        } 
    } 
 
    # Check SSM Agent Version 
    try { 
        $ssmAgentPath = "C:\Program Files\Amazon\SSM\amazon-ssm-agent.exe" 
        if (Test-Path $ssmAgentPath) { 
            $versionInfo = (Get-Item $ssmAgentPath).VersionInfo 
            Write-Host "`nSSM Agent Version:" -NoNewline 
            Write-Host " $($versionInfo.ProductVersion)" -ForegroundColor Green 
        } 
        else { 
            Write-Host "`nSSM Agent not found at expected location" -ForegroundColor Red 
        } 
    } 
    catch { 
        Write-Host "`nUnable to retrieve SSM Agent version" -ForegroundColor Red 
    } 
 
    # Check Proxy Settings 
    Write-Host "`nProxy Settings:" 
    Write-Host "---------------" 
    try { 
        $proxySettings = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Amazon\SSM" -ErrorAction SilentlyContinue 
        if ($proxySettings.HttpProxy) { 
            Write-Host "HTTP Proxy: $($proxySettings.HttpProxy)" 
        } 
        else { 
            Write-Host "No proxy configured in SSM settings" 
        } 
    } 
    catch { 
        Write-Host "Unable to retrieve proxy settings" -ForegroundColor Yellow 
    } 
 
    # Check System Environment 
    Write-Host "`nSystem Environment:" 
    Write-Host "------------------" 
    Write-Host "OS Version: $(([System.Environment]::OSVersion.Version))" 
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" 
     
   # Fixed architecture check 
    $arch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" } 
    Write-Host "System Architecture: $arch" 
} 
 
# Run diagnostics 
Get-SSMDiagnostics 