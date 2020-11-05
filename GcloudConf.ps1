# Conf File Version: 1.3.2.2

# General options	
$dateLogs          = Get-Date -UFormat '%Y%m%d' # A more powershelly way of doing this is: '{0:yyyyMMdd}' -f (Get-Date)  
$installDir		   = 'C:\Gcloud'
$logDir            = Join-Path -Path $installDir -ChildPath 'Logs' # We use join path so we force powershell to expand $installDir
$logFile           = [System.IO.Path]::Combine($logDir, $dateLogs, "logFile.txt") # With Join-Path the var $dateLogs was not expanding so I changed it to [System.IO.Path]::Combine()
$errorLog          = [System.IO.Path]::Combine($logDir, $dateLogs, "errorLog.txt")
$cleanLog          = [System.IO.Path]::Combine($logDir, $dateLogs, "cleanLog.txt")
$removeLogFile     = [System.IO.Path]::Combine($logDir, $dateLogs, "removeLogFile.txt")
$removeErrorLog    = [System.IO.Path]::Combine($logDir, $dateLogs, "removeErrorLog.txt")
$credErrorLog	   = [System.IO.Path]::Combine($logDir, $dateLogs, "credErrorLog.txt")
$driveLetter       = '' # e.g.: D: - If it is already busy and mountShare feature enabled, the next letter will be used
$backupPaths       = @('', '') # Comma-separated values without trailing backslashes and without the $driveLetter
$serverPath        = 'gs://' # Google cloud path to your bucket without trailing forwardslashes
$daysToKeepBK      = 8 # 8 days because in case it's Sunday we'll keep the last full backup made on last Saturday
$credDir           = Join-Path -Path $installDir -ChildPath 'Credentials'

# Mailing Options
$mailUsrFile     = Join-Path -Path $credDir -ChildPath 'MailUsername'
$mailPwFile      = Join-Path -Path $credDir -ChildPath 'MailPassword'
$isMailingOn     = $false
$mailTo 	     = ''

# CygWin Options
$cygWinBash     = 'C:\cygwin64\bin\bash.exe'
$cygWinSDKPath  = '~/google-cloud-sdk/bin' # Must not end with trailing backslash (path of the sdk installation in CygWin)
$useCygWin      = $false # Set to true if you wish to use the CygWin implementation.

# We moved the instructions on how to use CygWin to the README.md because some Anti-Virus detected the instructions as Obfuscated Code 
# (Since the instructions have links and such, some paranoid Anti-Virus like Kaspersky Endpoint detected it as Obfuscated Code)

# Mount share options
$mountShare       = $false
$sharePath        = '' # Full path to the share, including the directory (e.g.: \\server\SharedDirectory)
$shareUsrFile     = Join-Path -Path $credDir -ChildPath 'ShareUsername'
$sharePwFile      = Join-Path -Path $credDir -ChildPath 'SharePassword'
$permanentShare   = $false # Default: $false. Change to true to permanently mount the share as a Drive
