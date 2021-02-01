$volPath = "C:\DatabasesVol"

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Common") | Out-Null

$dummy = new-object Microsoft.SqlServer.Management.SMO.Server

$sqlConn = new-object Microsoft.SqlServer.Management.Common.ServerConnection

$smo = new-object Microsoft.SqlServer.Management.SMO.Server($sqlConn)
$dbs = New-Object Collections.Generic.List[object]

foreach ($odb in $smo.Databases) {
    $dbs.Add($odb)
}

$tenantDb = $dbs | where Name -eq "tenant"

#if ($tenantDb) {
#    $dbs.Remove($tenantDb)
#    $dbs.Insert(0, $tenantDb)
#}

$dbs | ForEach-Object {
    if ($_.Name -ne 'master' -and $_.Name -ne 'model' -and $_.Name -ne 'msdb' -and $_.Name -ne 'tempdb' -and $_.Name -ne 'default') {
        $toCopy = @()
        $dbPath = Join-Path -Path $volPath -ChildPath $_.Name
        mkdir $dbPath -Force | Out-Null

        write-host "name: $($_.Name)"

        $_.FileGroups | ForEach-Object {
            $_.Files | ForEach-Object {
                $destination = (Join-Path -Path $dbPath -ChildPath ($_.Name + '.' +  $_.FileName.SubString($_.FileName.LastIndexOf('.') + 1)))
                $toCopy += ,@($_.FileName, $destination)
                $_.FileName = $destination
                write-host "dest: $destination"
            } 
        }
        $_.LogFiles | ForEach-Object {
            $destination = (Join-Path -Path $dbPath -ChildPath ($_.Name + '.' +  $_.FileName.SubString($_.FileName.LastIndexOf('.') + 1)))
            $toCopy += ,@($_.FileName, $destination)
            $_.FileName = $destination
            write-host "log dest: $destination"
        }

        $_.Alter()
        $_.SetOffline()

        $toCopy | ForEach-Object {
            Write-host "Moving from $($_[0]) to $($_[1])"
            Move-Item -Path $_[0] -Destination $_[1]
        }

        if ($_.Name -ne 'tenant') {
            $_.SetOnline()
        }

        Write-host "-----------"
    }
}

if ($tenantDb) {
    $tenantDb.SetOnline();
}

$smo.ConnectionContext.Disconnect()
