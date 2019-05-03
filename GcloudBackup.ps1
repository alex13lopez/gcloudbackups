# Name: Gcloud Backup
# Author: Alex López <arendevel@gmail.com> || <alopez@hidalgosgroup.com>
# Version: 6.3.2b

########## Var & parms declaration #####################################################
param(
    [Parameter(Mandatory = $false)][switch]$all       = $false,
	[Parameter(Mandatory = $false)][switch]$clean     = $false, 
	[Parameter(Mandatory = $false)][switch]$removeOld = $false,
	[Parameter(Mandatory = $false)][switch]$dryRun    = $false
	)
	
$dateLogs          = Get-Date -UFormat "%Y%m%d"
$logDir            = "C:\Gcloud\GcloudLogs"
$logFile           = "$logDir\$dateLogs\logFile.txt"
$errorLog          = "$logDir\$dateLogs\errorLog.txt"
$cleanLog          = "$logDir\$dateLogs\cleanLogFile.txt"
$removeLogFile     = "$logDir\$dateLogs\removeLogFile.txt"
$removeErrorLog    = "$logDir\$dateLogs\removeOldErrorLog.txt"
$backupPaths       = @("\\172.26.0.97\VeeamBackup\Backup-AX_QV_DC-F","\\172.26.0.97\VeeamBackup\Backup-Resto-F") 
$serverPath        = "gs://srvbackuphidreborn/backups"
$daysToKeepBK      = 8 # 8 days because in case it's Sunday we'll keep the last full backup made on last Saturday

#########################################################################################

function getTime() {
	return Get-Date -UFormat "%d-%m-%Y @ %H:%M"
}

function createLogFolder() {
	mkdir "$logDir\$dateLogs" -ErrorAction Continue 2>&1> $null
}

function autoClean() {

		$currYear = Get-Date -UFormat "%Y"
		$prevYear = $currYear - 1	
		
		&{
			if ($dryRun) {
				echo "Running in 'dryRun' mode: No changes will be made."
			}
				
			$timeNow = getTime
			echo ("Autocleaning started at " + $timeNow)
			
			if (!$dryRun) {
				rm "$logDir\*$prevYear*"
			}
				
			$timeNow = getTime
			echo ("Autocleaning finished at " + $timeNow)
			
		} 2>> $errorLog 1>> $logFile
		
		
}


function removeOldBackups() {
	
	$lastWeek = (Get-Date (Get-Date).AddDays($daysToKeepBK * (-1)) -UFormat "%Y%m%d") # Cambiamos a negativo el $daysToKeepBK para restar dias
	
	$files = @(gsutil ls -R "$serverPath" | Select-String -Pattern "\..*$")
	
	if (! [string]::IsNullOrEmpty($files)) { 
	
		$timeNow = getTime
	    echo ("Removing old backup files' job started at " + $timeNow) 1>> $logFile
		
		&{
			if ($dryRun) {
				echo "Running in 'dryRun' mode: No changes will be made."
			}
		
			foreach ($file in $files) {
			
				$fileName = ($file -Split "/")[-1]
				$fileDate = ((($file -Split "F")[-1] -Split "T")[0]) -Replace '-'
				$fileExt  = ($fileName -Split "\.")[-1]
				
					if ($fileExt -ne "vbm") { # We skip '.vbm' files since they are always the same and don't have date on it					
							
							if ($fileDate -lt $lastWeek) {
								echo "The file: '$fileName' is older than $daysToKeepBK days... Wiping out!"
													
								if (!$dryRun) {				
									gsutil -m -q rm -a "$file" # -m makes the operation multithreaded. -q causes gsutil to be quiet, basically: No progress reporting, only errors
								}
							}
											
					}
				 
			}
			
		} 2>> $removeErrorLog 1> $removeLogFile
		
		$timeNow = getTime
	    echo ("Removing old backup files' job finished at " + $timeNow) 1>> $logFile 
	}
	else {echo "Could not get the files"}
	
}


function doUpload() {

	# We wrap all the code so we can send all the stdout and stderr to files in a single line
	&{
		if ($dryRun) {
				echo "Running in 'dryRun' mode: No changes will be made."
		}
		
		$timeNow = getTime
		echo ("Uploading Backups to Gcloud... Job started at " + $timeNow)

		foreach ($path in $backupPaths) {
			$dirName = $path -replace '.*\\'
			
			$timeNow = getTime
			echo ("Uploading $dirName to Gcloud... Job started at " + $timeNow)
			
			# In case the first upload takes more than 24h we make sure that there is a folder for today's logs
			try {
				createLogFolder
			}
			catch {
				continue
			}
			
			if (!$dryRun) {
				# Changed back to rsync because copy does copy all the files whether they are changed or not
				# But now, -d option is skipped since we deal with the old backup files manually with removeOldBackups
				gsutil -m -q rsync -r "$path" "$serverPath/$dirName"
			}
			
			$timeNow = getTime
			echo ("Uploading $dirName to Gcloud... Job Finished at " + $timeNow)
			
		}

		$timeNow = getTime
		echo ("Uploading Backups to Gcloud... Job Finished at " + $timeNow)

	}  2>> $errorLog 1>> $logFile
	
}

try {
	if ($clean) {
		createLogFolder
		autoClean
	} 
	elseif ($removeOld) {
		createLogFolder
		removeOldBackups
	}
	elseif ($All) {
		createLogFolder
		autoClean
		doUpload
		removeOldBackups
	}
	else {
		createLogFolder
		doUpload
	}
}
catch [System.IO.DirectoryNotFoundException] {
	Write-Host 'Please, check that file paths are well configured' -fore red -back black
}
catch {
	# We catch all exceptions and show the fullname of the exception so we can handle it better
	Write-Host 'Unknown error. Caught exception:' $_.Exception.GetType().FullName -fore red -back black
}



