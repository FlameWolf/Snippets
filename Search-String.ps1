$text = $args[0];
Get-ChildItem -Recurse | Select-String $text -List | Select Path