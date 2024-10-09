# windows10-backup
Makes backup of a clean image of a running Windows 10 using powershell

## Synopsis

A powershell script that will use DISM tool to check if image is clean, if not it will try to restore health. Then if will run SFC tool to check if any corrupt files and fix them. Only if both DISM and SFC are ok it will proceed to perform a full backup of C: using wbadmin.exe 

## Variables

Replace value of "bktarget", it can be network location (make sure you have write access) or a different drive
Logs are written to C:\WINDOWS\Logs\WindowsBackup\WindowsBackupAutomation.log but it can be changed

## Usage

You can manually run it with admin privileges or create a Schedule Tasks and with action "powershell.exe" and give argument "-file C:\path\to\WindowsFixandBakcup.ps1"
