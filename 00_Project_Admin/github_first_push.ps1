# github_first_push.ps1 - first upload of the project to a NEW, EMPTY, PRIVATE GitHub repository.
# Run once, after: (1) Git for Windows is installed (winget install --id Git.Git -e), (2) you have created an empty private repository on github.com
# (no README, no .gitignore, no licence), and (3) you replaced the URL below. Sign-in happens in the window that Git opens (Git Credential Manager);
# no password or token is written in this file.
param([Parameter(Mandatory = $true)][string]$RepoUrl)   # e.g. https://github.com/<your-user>/transformer-dga-mphil.git
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
git init -b main
git config user.name  "<your name>"            # TO FILL
git config user.email "silasasare246@gmail.com"
git add -A
git status --short | Select-Object -First 20
git commit -m "Project snapshot 2026-10-17: thesis draft v3, dashboard redesign (D43), code, results, tests"
git remote add origin $RepoUrl
git push -u origin main