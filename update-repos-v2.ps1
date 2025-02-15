# Set the current directory to the base directory
$baseDir = "D:\source\repos"
Set-Location $baseDir

# Get all subdirectories
$repositories = Get-ChildItem -Directory

# Function to update a single repository
$scriptBlock = {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.DirectoryInfo]$Repository
    )
    
    $repoPath = $Repository.FullName
    $repoName = $Repository.Name
    $results = @{
        Name = $repoName
        Status = "Success"
        Details = @()
        CommitsBehind = 0
        Error = $null
    }
    
    try {
        Push-Location $repoPath
        
        if (-not (Test-Path ".git")) {
            $results.Status = "Skipped"
            $results.Details += "Not a git repository"
            return $results
        }

        # Store initial commit hash
        $beforeHash = git rev-parse HEAD
        
        # Get current branch
        $currentBranch = git branch --show-current
        $results.Details += "Current branch: $currentBranch"
        
        # Get status before fetch
        $initialStatus = git status -s
        if ($initialStatus) {
            $results.Details += "Uncommitted changes: $($initialStatus.Count) files"
        }
        
        # Fetch updates
        git fetch 2>&1 | Out-Null
        
        # Get number of commits behind
        $commitsBehind = git rev-list --count HEAD..@{u} 2>$null
        $results.CommitsBehind = $commitsBehind
        $results.Details += "Commits behind remote: $commitsBehind"
        
        if ($commitsBehind -gt 0) {
            # Perform pull
            $pullResult = git pull 2>&1
            $results.Details += "Pull result: $pullResult"
            
            # Get new commit hash
            $afterHash = git rev-parse HEAD
            
            if ($beforeHash -ne $afterHash) {
                $commitDiff = git log --oneline $beforeHash..$afterHash
                $results.Details += "New commits: $($commitDiff.Count)"
                $results.Details += $commitDiff
            }
        } else {
            $results.Details += "Repository is up to date"
        }
        
        # Get final status
        $finalStatus = git status -s
        if ($finalStatus) {
            $results.Details += "Final status: $($finalStatus.Count) uncommitted files"
        }
    }
    catch {
        $results.Status = "Error"
        $results.Error = $_.Exception.Message
    }
    finally {
        Pop-Location
    }
    
    return $results
}

# Create a runspace pool
$maxThreads = [int]$env:NUMBER_OF_PROCESSORS
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
$runspacePool.Open()

# Create an array to hold the running jobs
$jobs = @()

Write-Host "Starting parallel repository updates using $maxThreads threads...`n" -ForegroundColor Cyan

# Start jobs for each repository
foreach ($repo in $repositories) {
    $powerShell = [powershell]::Create().AddScript($scriptBlock).AddArgument($repo)
    $powerShell.RunspacePool = $runspacePool
    
    $jobs += @{
        PowerShell = $powerShell
        Handle = $powerShell.BeginInvoke()
    }
}

# Collection for results
$results = @()

# Wait for all jobs to complete and collect results
foreach ($job in $jobs) {
    $results += $job.PowerShell.EndInvoke($job.Handle)
    $job.PowerShell.Dispose()
}

# Display results
Write-Host "`nRepository Update Summary:" -ForegroundColor Cyan
Write-Host "========================`n"

foreach ($result in $results) {
    $color = switch ($result.Status) {
        "Success" { "Green" }
        "Skipped" { "Yellow" }
        "Error" { "Red" }
    }
    
    Write-Host "Repository: $($result.Name)" -ForegroundColor $color
    Write-Host "Status: $($result.Status)"
    if ($result.CommitsBehind -gt 0) {
        Write-Host "Commits pulled: $($result.CommitsBehind)" -ForegroundColor Yellow
    }
    Write-Host "Details:"
    foreach ($detail in $result.Details) {
        Write-Host "  - $detail"
    }
    if ($result.Error) {
        Write-Host "Error: $($result.Error)" -ForegroundColor Red
    }
    Write-Host ""
}

# Clean up
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "All repositories have been processed" -ForegroundColor Green