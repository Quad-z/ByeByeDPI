Write-Host "=== ByeByeDPI - Deploy & Build ===" -ForegroundColor Cyan

$repoName = "ByeByeDPI"

# 1. Проверка git
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "Git не найден. Скачай: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

# 2. Инициализация репозитория
Set-Location "$PSScriptRoot"
git init
git add -A
git commit -m "init"

# 3. GitHub CLI логин (если установлен)
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    gh auth status 2>$null
    if ($LASTEXITCODE -ne 0) {
        gh auth login
    }
    gh repo create $repoName --public --push --source .
    Write-Host "Репозиторий создан и код запушен!" -ForegroundColor Green
} else {
    Write-Host "=== GitHub CLI не найден ===" -ForegroundColor Yellow
    Write-Host "Сделай вручную:" -ForegroundColor Yellow
    Write-Host "1. Зайди на github.com/new" -ForegroundColor Yellow
    Write-Host "2. Создай репозиторий: $repoName" -ForegroundColor Yellow
    Write-Host "3. Выполни в терминале:" -ForegroundColor Yellow
    Write-Host "   git remote add origin https://github.com/ТВОЙ_ЮЗЕР/$repoName.git" -ForegroundColor White
    Write-Host "   git push -u origin main" -ForegroundColor White
}

Write-Host ""
Write-Host "=== После пуша ===" -ForegroundColor Cyan
Write-Host "1. Открой github.com/ТВОЙ_ЮЗЕР/$repoName в браузере"
Write-Host "2. Перейди во вкладку Actions"
Write-Host "3. Нажми 'Run workflow' на 'Build IPA'"
Write-Host "4. Через 5 минут скачай IPA (артефакт)"
Write-Host ""
Write-Host "=== Установка на iPhone (Sideloadly) ===" -ForegroundColor Cyan
Write-Host "1. Скачай Sideloadly.io на этот ПК"
Write-Host "2. Подключи iPhone по USB"
Write-Host "3. Перетащи IPA в Sideloadly, введи Apple ID"
Write-Host "4. Нажми Start — приложение на телефоне"
