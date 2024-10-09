#Requires -RunAsAdministrator
$bktarget = "\\YOURSERVER\yourbackupfolder"
$bklogfile = "C:\WINDOWS\Logs\WindowsBackup\WindowsBackupAutomation.log"

Write-Output "$((Get-Date).ToString()) - #### Windows Backup Automation Start" | Tee-Object -file $bklogfile -Append
# Check for image errors and fix them
Write-Output "$((Get-Date).ToString()) - DISM - Check for image errors" | Tee-Object -file $bklogfile -Append
$dismscan1 = dism /online /cleanup-image /scanhealth

if ($dismscan1 -like "*No component store corruption detected.*") {
    Write-Output "$((Get-Date).ToString()) - DISM - No component store corruption detected." | Tee-Object -file $bklogfile -Append
    $dismcheck = $true
} else {
    Write-Output "$((Get-Date).ToString()) - DISM - Corruption detected running restorehealth." | Tee-Object -file $bklogfile -Append
    $dismrestore = dism /online /cleanup-image /restorehealth
    if ($dismrestore -like "*The restore operation completed successfully.*") {
        Write-Output "$((Get-Date).ToString()) - DISM - Helath restored, running scan again."  | Tee-Object -file $bklogfile -Append
        $dismscan2 = dism /online /cleanup-image /scanhealth
        if ($dismscan2 -like "*No component store corruption detected.*") {
            Write-Output "$((Get-Date).ToString()) - DISM - No component store corruption detected." | Tee-Object -file $bklogfile -Append
            $dismcheck = $true
        }
        else {
            Write-Output "$((Get-Date).ToString()) - DISM - Could not restore health." | Tee-Object -file $bklogfile -Append
            $dismcheck = $false
        }
    }
}

# Image resetbase
Write-Output "$((Get-Date).ToString()) - DISM - Reset base image." | Tee-Object -file $bklogfile -Append
$dismreset = dism /online /cleanup-image /startcomponentcleanup /resetbase
if ($dismreset -like "*The operation completed successfully.*") {
    $dismresetcheck = $true
    Write-Output "$((Get-Date).ToString()) - DISM - Reset base completed successfully." | Tee-Object -file $bklogfile -Append
} else {
    $dismresetcheck = $false
}

# Save the current output encoding and switch to UTF-16LE
$prev = [console]::OutputEncoding
[console]::OutputEncoding = [Text.Encoding]::Unicode
# Check system files
Write-Output "$((Get-Date).ToString()) - SFC - Start scan." | Tee-Object -file $bklogfile -Append
$sfcout = (sfc /scannow) -join "`r`n" -replace "`r`n`r`n", "`r`n" 
# $sfcout = sfc /scannow
# Write-Output $sfcout
if ( $sfcout -like "*did not find any integrity violations*" ) {
    $sfcok = $true
    Write-Output "$((Get-Date).ToString()) - SFC - Check OK" | Tee-Object -file $bklogfile -Append
} elseif( $sfcout -match "*found corrupt files and successfully repaired them*" ) {
    Write-Output "$((Get-Date).ToString()) - SFC - found corrupt files and successfully repaired them. Running scan again." | Tee-Object -file $bklogfile -Append
    $sfcout2 = (sfc /scannow) -join "`r`n" -replace "`r`n`r`n", "`r`n" 
    if ($sfcout2 -like "*did not find any integrity violations*") {
        $sfcok = $true  
        Write-Output "$((Get-Date).ToString()) - SFC - Check OK" | Tee-Object -file $bklogfile -Append
    }
    else {
        $sfcok = $false
        Write-Output "$((Get-Date).ToString()) - SFC - Check FAILED" | Tee-Object -file $bklogfile -Append
    }
}
[console]::OutputEncoding = $prev

if ( ($dismcheck -eq $true) -and ($dismresetcheck -eq $true) -and ($sfcok -eq $true) ) {
    Write-Output "$((Get-Date).ToString()) - Proceed with backup." | Tee-Object -file $bklogfile -Append
    $bkpout = wbAdmin start backup -backupTarget:$bktarget -include:C: -allCritical -quiet
    if ($bkpout -like "*The backup operation successfully completed*") {
        Write-Output "$((Get-Date).ToString()) - Backup completed successfully." | Tee-Object -file $bklogfile -Append
    } else {
        Write-Output "$((Get-Date).ToString()) - Backup failed check logs at C:\WINDOWS\Logs\WindowsBackup\" | Tee-Object -file $bklogfile -Append
    }
} else {
    Write-Output "$((Get-Date).ToString()) - Backup cannot continue, check output of dism and sfc." | Tee-Object -file $bklogfile -Append
}
