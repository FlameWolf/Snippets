# Set the current directory to the base directory
$baseDir = "D:\source\repos"
Set-Location $baseDir

# Get all subdirectories
$repositories = Get-ChildItem -Directory

foreach ($repo in $repositories) {
    Write-Host "`nUpdating repository: $($repo.Name)" -ForegroundColor Cyan
    
    try {
        # Change to the repository directory
        Set-Location $repo.FullName
        
        # Check if this is actually a git repository
        if (Test-Path ".git") {
            # Run git fetch
            Write-Host "Fetching updates..." -ForegroundColor Yellow
            git fetch
            
            # Run git pull
            Write-Host "Pulling changes..." -ForegroundColor Yellow
            git pull
            
            Write-Host "Repository $($repo.Name) updated successfully" -ForegroundColor Green
        } else {
            Write-Host "Skipping $($repo.Name) - Not a git repository" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error updating $($repo.Name): $_" -ForegroundColor Red
    }
    finally {
        # Always return to the base directory
        Set-Location $baseDir
    }
}

Write-Host "`nAll repositories have been processed" -ForegroundColor Green