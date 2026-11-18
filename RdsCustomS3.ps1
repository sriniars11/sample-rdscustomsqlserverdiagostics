# Initialize variables 
$bucketName = $null 
$dbResourceId = $null 
 
# Get all subkeys under HKEY_USERS 
$userSIDs = Get-ChildItem -Path "Registry::HKEY_USERS" | Select-Object -ExpandProperty Name 
 
# Loop through each SID to find the correct path 
foreach ($sid in $userSIDs) { 
    $registryPath = "Registry::$sid\Software\Amazon\Custom" 
     
   # Check if the path exists 
    if (Test-Path $registryPath) { 
        try { 
            # Try to get both registry values 
            $registryValues = Get-ItemProperty -Path $registryPath -ErrorAction Stop 
             
           # If found, store both values 
            if ($registryValues.RdsCustomS3BucketName -and $registryValues.DbResourceId) { 
                $bucketName = $registryValues.RdsCustomS3BucketName 
                $dbResourceId = $registryValues.DbResourceId 
                Write-Host "Found S3 bucket name: $bucketName" 
                Write-Host "Found DbResourceId: $dbResourceId" 
                break 
            } 
        } 
        catch { 
            continue 
        } 
    } 
} 
 
if ($bucketName -and $dbResourceId) { 
    try { 
        # Set the S3 key for readonly.txt 
        $s3Key = "RDSCustomForSQLServer/Instances/$dbResourceId/readonly.txt" 
         
       Write-Host "`nAttempting to get readonly.txt file..." 
        try { 
            $tempGetFile = [System.IO.Path]::GetTempFileName() 
            Read-S3Object -BucketName $bucketName -Key $s3Key -File $tempGetFile 
             
           if (Test-Path $tempGetFile) { 
                $content = Get-Content $tempGetFile -Raw 
                Write-Host "`nFile retrieved successfully!" -ForegroundColor Green 
                Write-Host "File path: $s3Key" -ForegroundColor Green 
                Write-Host "Content: $content" -ForegroundColor Green 
                Remove-Item $tempGetFile 
            } else { 
                Write-Host "Get operation failed: File not downloaded" -ForegroundColor Red 
            } 
        } 
        catch { 
            Write-Host "Get operation failed: $_" -ForegroundColor Red 
        } 
    } 
    catch { 
        Write-Host "Error during S3 operations: $_" -ForegroundColor Red 
    } 
} 
else { 
    if (-not $bucketName) { 
        Write-Host "Could not find S3 bucket name in registry" -ForegroundColor Red 
    } 
    if (-not $dbResourceId) { 
        Write-Host "Could not find DbResourceId in registry" -ForegroundColor Red 
    } 
} 
