$path = "main.tf"
$s = Get-Content -Raw $path
$s = $s -replace "`r`n","`n"
[System.IO.File]::WriteAllText($path,$s)
Write-Output "converted"
