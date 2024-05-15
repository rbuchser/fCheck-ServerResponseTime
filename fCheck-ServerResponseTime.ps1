Function fCheck-ServerResponseTime {
	<#
		.NOTES
			Author: Buchser Roger
			
		.SYNOPSIS
			Function will check Ping Reply time to Servers
			
		.DESCRIPTION
			In Case of a possible Network Issue, you can quickly check Ping Reply Time from other Servers. 
			Results will be logged in CSV File.
			
		.PARAMETER Servers
			Enter Servers to check. Default are all Servers in Exchaneg Enviroment.
			
		.PARAMETER Minutes
			Enter Test duration in Minutes. A Result CSV-File will be created.
			
		.PARAMETER Hours
			Enter Test duration in Hours. A Result CSV-File will be created. 
			Note: Test maybe abrupted by System Auto Log Off.
		
		.PARAMETER WarnValueInMs
			Enter the Warn Value in Milliseconds. Used for Console Output in Yellow Color. Default is '10'.
		
		.PARAMETER FailValueInMs
			Enter the Fail Value in Milliseconds. Used for Console Output in Red Color. Default is '100'.
		
		.PARAMETER NoResultFile
			By default, the Check will create a Result CSV-File. Use this Switch to not create a Result CSV-File.
		
		.EXAMPLE
			fCheck-ServerResponseTime -Servers LAB-EX-01,LAB-EX-03
			Will check Ping Reply time every 5 Seconds for the Servers 'LAB-EX-01' and 'LAB-EX-03' during next 30 Seconds.
			For this Quick Test, no Result CSV-File will be created.
		
		.EXAMPLE
			fCheck-ServerResponseTime -Servers LAB-SRV-01 -Minutes 20
			Will check Ping Reply time every 60 Seconds for the Server 'LAB-SRV-01' during next 20 Minutes.
			Result CSV-File will be created.
		
		.EXAMPLE
			fCheck-ServerResponseTime -Servers LAB-EX-01 -Hours 6
			Will check Ping Reply time every 60 Seconds for the Server 'LAB-EX-01' during next 6 Hours.
			Result CSV-File will be created.
		
		.EXAMPLE
			fCheck-ServerResponseTime -Servers LAB-EX-04 -Minutes 5 -WarnValueInMs 5 -FailValueInMs 20 -NoResultFile
			Will check Ping Reply time for the Server 'LAB-EX-04' during next 5 Minutes.
			Reply time over 20 ms will output a Fail (Red Console Text).
			Reply time over 5 ms will output a Warn (Yellow Console Text).
			No Result CSV-File will be created.
	#>
	
	[CmdletBinding(DefaultParameterSetName="Minutes")]
	PARAM (
		[Parameter(Mandatory=$True)][String[]]$Servers,
		[Parameter(ParameterSetName="Minutes")][Int]$Minutes,
		[Parameter(ParameterSetName="Hours")][Int]$Hours,
		[Int]$WarnValueInMs = 10,
		[Int]$FailValueInMs = 100,
		[Switch]$NoResultFile
	)
	
	# Define Target Servers and Result CSV-File
	[String[]]$ServersToCheck = $Servers
	If ($Servers.Count -eq 1) {
		$ResultFile = "$((Get-Date).ToString('yyyy-MM-dd')) - $Servers PingResult.csv"
	} Else {
		$ResultFile = "$((Get-Date).ToString('yyyy-MM-dd')) - PingResult.csv"
	}
	
	# Define Test Duration
	If ($Minutes -OR $Hours) {
		Switch ($PsCmdlet.ParameterSetName)	{
			"Minutes" {
				$EndDate = (Get-Date).AddMinutes($Minutes)
				Write-Host "The Script will check Server Ping Response Time every 5 Seconds from Localhost to total $($ServersToCheck.Count) Server during the next $Minutes Minutes"
				$Sleep = 5
			}
			"Hours" {
				$EndDate = (Get-Date).AddHours($Hours)
				Write-Host "The Script will check Server Ping Response Time every 60 Seconds from Localhost to total $($ServersToCheck.Count) Server during the next $Hours Hours"
				$Sleep = 60
			}
		}
	} Else {
		$EndDate = (Get-Date).AddSeconds(30)
		Write-Host "The Script will check Server Ping Response Time from Localhost to total $($ServersToCheck.Count) Server for next 30 Seconds"
		$Sleep = 1
		$NoResultFile = $True
	}
	
	# Create Result File with Header Line if Result File not exists
	If ((!(Test-Path $ResultFile)) -AND (!($NoResultFile))) {
		Set-Content -Path $ResultFile -Value "Date;Source Computer;Target Computer;Response Message;Reply Time" -Encoding UTF8
	}
	
	# Ping Target Servers during a specified Time
	Do {
		ForEach ($Server in $ServersToCheck) {
			$Response = (ping $Server -n 1 | Select-String "Antwort|Zeitüberschreitung|Ping-Anforderung|Reply|Request").ToString()
			$CurrentDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
			$ResponseTime = ($Response -Split '\s')[-2].Split('=<')[1]
			If (!($NoResultFile)) {
				$Echo = "$CurrentDate;$($Env:COMPUTERNAME);$Server;$Response;$ResponseTime" | Out-File $ResultFile -Encoding UTF8 -Append
			}
			If (!($ResponseTime)) {	
				Write-Host "$CurrentDate | $($Server.PadRight(15,' ')) | Ping Reply Time: $($ResponseTime.PadRight(5,' ')) | Response Message:`'$Response`'" -f Red
			} ElseIf (($ResponseTime.SubString(0,$ResponseTime.Length -2) -as [Int]) -ge $FailValueInMs) {
				Write-Host "$CurrentDate | $($Server.PadRight(15,' ')) | Ping Reply Time: $($ResponseTime.PadRight(5,' ')) | Response Message:`'$Response`'" -f Red
			} ElseIf (($ResponseTime.SubString(0,$ResponseTime.Length -2) -as [Int]) -ge $WarnValueInMs) {
				Write-Host "$CurrentDate | $($Server.PadRight(15,' ')) | Ping Reply Time: $($ResponseTime.PadRight(5,' ')) | Response Message:`'$Response`'" -f Yellow
			} Else {
				Write-Host "$CurrentDate | $($Server.PadRight(15,' ')) | Ping Reply Time: $($ResponseTime.PadRight(5,' ')) | Response Message:`'$Response`'"
			}
		}
		Sleep $Sleep
	} Until ((Get-Date) -gt $EndDate)
	Write-Host
	
	If (!($NoResultFile)) {
		# Open Windows Explorer with Result CSV-File
		Write-Host "`nCheck Result CSV-File `'$ResultFile`'`n" -f White
		Start-Process -FilePath C:\Windows\explorer.exe -ArgumentList "/select, ""$ResultFile"""
	}
}
