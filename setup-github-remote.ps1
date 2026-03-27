# =============================================================================
# 1) ქვემოთ ჩაწერე შენი GitHub username და რეპოზიტორიის სახელი (რაც github.com-ზე შექმენი)
# 2) PowerShell: უფლება სკრიპტებზე თუ საჭიროა: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
# 3) გაშვება: .\setup-github-remote.ps1
# =============================================================================
$GitHubUser = "CHANGE_ME_USERNAME"
$RepoName   = "CHANGE_ME_REPO"

if ($GitHubUser -match "CHANGE_ME" -or $RepoName -match "CHANGE_ME") {
  Write-Error "ჯერ ფაილში ჩაწერე `$GitHubUser` და `$RepoName` (GitHub username და რეპოს სახელი)."
  exit 1
}

$originUrl = "https://github.com/$GitHubUser/$RepoName.git"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "origin უკვე არის: $existing"
  Write-Host "განახლება -> $originUrl"
  git remote set-url origin $originUrl
} else {
  git remote add origin $originUrl
  Write-Host "დაემატა origin: $originUrl"
}

Write-Host ""
Write-Host "შემდეგი ნაბიჯი (ატვირთვა):"
Write-Host "  git push -u origin main"
Write-Host ""
