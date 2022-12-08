$file = "some path"
$array = Get-Content $file
foreach ($item in $array) {if ($item -like "https://*") {invoke-webrequest $item}}