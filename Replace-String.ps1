$from = $args[0];
$to = $args[1];
Get-ChildItem -Recurse -File | Select-String $from -List | Select Path | Get-Item | ForEach-Object -Process {
	(Get-Content $_) -Replace $from, $to | Set-Content $_
}