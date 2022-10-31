Write-Host ""
Write-Host "Welcome to Dylan's File Access Monitor or FIM in short"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"

$choice = Read-Host -Prompt "Please enter 'A' or 'B'"

Function calculateFileHash($filepath) {

    $fileHash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $fileHash
}

Function resetBaselineIfExist() {

    $checkBaselineExists = Test-Path -Path .\baseline.txt

    # Checks if baseline already exists
    if ($checkBaselineExists) {
        Remove-Item -Path .\baseline.txt
    }

}

if ($choice -eq "A".ToUpper()) {

    # Delete baseline if exists
        resetBaselineIfExist
    
    # Collect all files stored in the target folder
    $files = Get-ChildItem -Path .\Files

    # For each files, calculate the hash and write it to baseline.txt
    foreach ($i in $files) {
        $hash = calculateFileHash $i.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}

elseif ($choice -eq "B".ToUpper()) {

    # Create an empty dictionary to store hash values
    $hashDictionary = @{}

    # Load file|hash from baseline.txt and stores them into a dictionary
    $pathsAndHashes = Get-Content -Path .\baseline.txt

    # Appends the files and Hash value from baseline.txt and append into the dictionary
    foreach($i in $pathsAndHashes) {
        $hashDictionary.add($i.Split("|")[0].Trim(), $i.Split("|")[1].Trim())
    }

    #Loops continuously to monitor files against the saved baseline
    While ($true) {
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path .\Files

        foreach ($i in $files) {
            $hash = calculateFileHash $i.FullName

            # Checks if new file has been created
            if ($null -eq $hashDictionary[$hash.Path]) {
                # If a new file is created, notify user
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }

            # Checks if a file has been changes
            elseif ($hashDictionary[$hash.Path] -ne $hash.Hash) {
                # If the file has been changed, notify user
                Write-Host "$($hash.Path) has been changed!" -ForegroundColor Yellow
            }
    }
        foreach ($keys in $hashDictionary.Keys) {
            $baselineFileExists = Test-Path -Path $keys
            if (-Not $baselineFileExists) {
                # If the file has been deleted, notify user
                Write-Host "$($keys) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}