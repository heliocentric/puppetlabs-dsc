function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [parameter(Mandatory = $true)]
        [System.String]
        $Destination,

        [System.String]
        $LogOutput
    )


    $returnValue = @{
        Source = if (Test-Path $Source){$Source};
        Destination = if (Test-Path $Destination){$Destination};
        LogOutput = if ($LogOutput){
                        if(Test-Path $LogOutput){$LogOutput}
                        }
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [parameter(Mandatory = $true)]
        [System.String]
        $Destination,

        [System.String]
        $Files,

        [System.UInt32]
        $Retry,

        [System.UInt32]
        $Wait,

        [System.Boolean]
        $SubdirectoriesIncludingEmpty = $False,

        [System.Boolean]
        $Restartable = $False,

        [System.Boolean]
        $MultiThreaded = $False,

        [System.String]
        $ExcludeFiles,

        [System.String]
        $LogOutput,

        [System.Boolean]
        $AppendLog = $False,

        [System.String]
        $AdditionalArgs
    )

    [string]$Arguments = ''
    if ($Retry -ne '') {$Arguments += " /R:$Retry"}
    if ($Wait -ne '') {$Arguments += " /W:$Wait"}
    if ($SubdirectoriesIncludingEmpty) {$Arguments += ' /E'}
    if ($Restartable) {$Arguments += ' /Z'}
    if ($MultiThreaded) {$Arguments += ' /MT'}
    if ($ExcludeFiles -ne '') {$Arguments += " /XF $ExcludeFiles"}
    if ($ExcludeDirs -ne '') {$Arguments += " /XD $ExcludeDirs"}
    if ($LogOutput -ne '' -AND $AppendLog) {
        $Arguments += " /LOG+:$LogOutput"
        }
    if ($LogOutput -ne '' -AND -not $AppendLog) {
        $Arguments += " /LOG:$LogOutput"
     }
    if ($AdditionalArgs -ne $null) {$Arguments += " $AdditionalArgs"}

    try {
        Write-Verbose "Executing: Robocopy.exe `"$($Source)`" `"$($Destination)`" $($Arguments)"
        Invoke-Robocopy $Source $Destination $Arguments
        }
    catch {
        Write-Warning "An error occured executing Robocopy.exe.  ERROR: $_"
        }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Source,

        [parameter(Mandatory = $true)]
        [System.String]
        $Destination,

        [System.String]
        $Files,

        [System.UInt32]
        $Retry,

        [System.UInt32]
        $Wait,

        [System.Boolean]
        $SubdirectoriesIncludingEmpty,

        [System.Boolean]
        $Restartable,

        [System.Boolean]
        $MultiThreaded,

        [System.String]
        $ExcludeFiles,

        [System.String]
        $LogOutput,

        [System.Boolean]
        $AppendLog,

        [System.String]
        $AdditionalArgs
    )

    try {
        $result = Invoke-RobocopyTest $Source $Destination
        }
    catch {
        Write-Warning "An error occured while getting the file list from Robocopy.exe.  ERROR: $_"
        }
    
    # https://support.microsoft.com/en-us/kb/954404
    # ROBOCOPY $LASTEXITCODE is a bitflag:
    #  0: Source and destination are completely synchronized
    #  1: One or more files were copied successfully (new files present)
    #  2: extra files/directories detected
    #  4: mismatched files/directories
    #  8: copy errors and retries exceeded
    # 16: serious error
    if ($result -ge 0 -and $result -lt 8) {[system.boolean]$result = $true}
    else {[system.boolean]$result = $false}
    
    $result
}

# Helper Functions

function Invoke-RobocopyTest {
param (
    [parameter(Mandatory = $true)]
    [System.String]
    $source,

    [parameter(Mandatory = $true)]
    [System.String]
    $destination
)
    $output = & robocopy.exe /L $source $destination
    $LASTEXITCODE
}
 # Invoke-RobocopyTest C:\DSCTestMOF C:\DSCTestMOF2

function Invoke-Robocopy {
param (
    [parameter(Mandatory = $true)]
    [System.String]
    $source,

    [parameter(Mandatory = $true)]
    [System.String]
    $destination,

    [System.String]
    $Arguments
)

    # This is a safe use of invoke-expression.  Input is only passed as parameters to Robocopy.exe, it cannot be executed directly
    $output = Invoke-Expression "Robocopy.exe `"$Source`" `"$Destination`" $Arguments"

    $LASTEXITCODE
}
 # Invoke-Robocopy -source C:\DSCTestMOF -destination C:\DSCTestMOF2 -Arguments '/E /MT'

Export-ModuleMember -Function *-TargetResource
