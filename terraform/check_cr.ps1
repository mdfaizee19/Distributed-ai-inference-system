$path = 'main.tf'
$b = [System.IO.File]::ReadAllBytes($path)
$has = $false
foreach($x in $b){ if($x -eq 13){ $has = $true; break } }
if($has){ Write-Output 'hasCR' } else { Write-Output 'noCR' }
