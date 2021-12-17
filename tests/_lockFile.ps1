#Specify the file name
$fileName = "atlas\cavesofgallet_tiles.png"

#Open the file in read only mode, without sharing (I.e., locked as requested)
$file = [System.io.File]::Open($fileName, 'Open', 'Read', 'None')

#Wait in the above (file locked) state until the user presses a key
Write-Host "Press any key to continue ..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

#Close the file (This releases the current handle and unlocks the file)
$file.Close()