$from = $args[0];
$to = $args[1];
Get-ChildItem -Recurse -File | Select-String -Pattern $from -List | Select Path | Get-Item | ForEach-Object -Process {
    Write-Host $_.FullName
	(Get-Content $_) -Replace $from, $to | Set-Content $_
}