###########
# Simple.PowerShell.Logging.psm1
# Author: Olli Jääskeläinen
# Date: 2018-05-09
# Source: https://github.com/ollij/Simple.PowerShell.Logging/blob/master/Simple.PowerShell.Logging.psm1
# Documentation: http://opax.io/simple-powershell-logging-solution-for-azure-functions/
# MIT License


# VARIABLES
[string]$Global:SPL_LogFilePath = $null
[string]$Global:SPL_LogDirPath = $null
[int]$Global:SPL_ErrorCount = 0


# EXPORTED FUNCTIONS
function New-LogFile{
    param(
        [string]$LogFolder="",
        [string]$FileNamePart=""
    )
    $Global:SPL_LogFilePath = "D:\home\site\wwwroot\logs\log"
    if ([string]::IsNullOrEmpty($LogFolder) -ne $null) {
        $Global:SPL_LogFilePath = $LogFolder
    }
    $date = Get-Date     
    if ($Global:SPL_LogFilePath.EndsWith("\") -eq $false) {
        $Global:SPL_LogFilePath = $Global:SPL_LogFilePath + "\"
    }
    $Global:SPL_LogDirPath = $Global:SPL_LogFilePath
    $actualFilenamePart = ""
    if ([string]::IsNullOrEmpty($FileNamePart) -eq $false) {
        $actualFilenamePart = "-"+$FileNamePart
    }
    $Global:SPL_LogFilePath = $Global:SPL_LogFilePath + $date.ToString("yyyy-MM-dd-HHmmss")+$actualFilenamePart+".log"    
    Remove-OldLogFiles -Days 30
}
function Get-LogFilePath{
    return $Global:SPL_LogFilePath
}
function Add-LogFileMessage{
    param(
        [string]$Message        
    )
    Add-LogFileMessageInternal $Message
}
function Reset-ErrorCounter{
    $Global:SPL_ErrorCount = $Global:Error.Count
}

# INTERNAL FUNCTIONS
function Add-LogFileMessageInternal{
    param(
        [string]$Message,
        [switch]$IsException
    )
    if ($Global:SPL_LogFilePath -eq $null) {
        New-LogFile
    }    
    if ($Global:Error.Count -gt $Global:SPL_ErrorCount -and $IsException -eq $false) {
        Flush-ErrorsToLogFile 
    }
    $date = Get-Date
    $lineToWrite = $date.ToUniversalTime().ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'fff'Z'") + " " + $Message
    $lineToWrite | Out-File -FilePath $Global:SPL_LogFilePath -Encoding utf8 -Append    
    if ($IsException -eq $false) {
        Write-Output $Message
    }
}
function Flush-ErrorsToLogFile{    
    for($i = ($Global:Error.Count - $Global:SPL_ErrorCount)-1; $i -ge 0; $i--) {
        $e = $Global:Error[$i]
        $message = $e.Exception.Message
        $stackTrace = $e.Exception.StackTrace
        Add-LogFileMessageInternal "$message\n$stackTrace" -IsException
    }
    $Global:SPL_ErrorCount = $Global:Error.Count    
}
function Remove-OldLogFiles{
    param([int]$Days=30)
    $limit = (Get-Date).AddDays(-$Days)
    $path = $Global:SPL_LogDirPath + "*"
    Get-ChildItem -Path $path -Include "*.log" | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item 
}

Export-ModuleMember -Function New-LogFile
Export-ModuleMember -Function Add-LogFileMessage
Export-ModuleMember -Function Get-LogFilePath
Export-ModuleMember -Function Reset-ErrorCounter
