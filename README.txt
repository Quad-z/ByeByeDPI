=== ЧТОБЫ СОБРАТЬ iOS-ПРИЛОЖЕНИЕ БЕЗ MAC ===

ШАГ 1 — Установить Git
https://git-scm.com/download/win
Скачай и установи (галочки все по-умолчанию)

ШАГ 2 — Создать аккаунт на GitHub (если нет)
Зайди на github.com и зарегистрируйся

ШАГ 3 — Запустить deploy.ps1
Нажми правой кнопкой на deploy.ps1 → "Run with PowerShell"
Или открой PowerShell и напиши:
  cd C:\Users\alexe\AppData\Local\Temp\opencode\ByeByeDPI
  .\deploy.ps1

Скрипт создаст репозиторий и зальёт код.

ШАГ 4 — GitHub Actions соберёт IPA
Зайди на github.com/ТВОЙ_ЮЗЕР/ByeByeDPI
Вкладка Actions → Run workflow
Через 5 минут скачай ByeByeDPI.ipa

ШАГ 5 — Установка на iPhone
Скачай Sideloadly (sideloadly.io) на Windows
Подключи iPhone → перетащи IPA → введи Apple ID → Start
На телефоне появится приложение.
В настройках Wi-Fi включи прокси 127.0.0.1:1080
Запусти ByeByeDPI → нажми кнопку → готово.
