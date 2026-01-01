#!/bin/bash

# Скрипт для быстрого запуска локального сервера

echo "🚀 Запуск локального сервера..."
echo ""
echo "📂 Рабочая директория: $(pwd)"
echo ""

# Проверяем наличие Python
if command -v python3 &> /dev/null; then
    echo "✅ Python 3 найден"
    echo ""
    echo "🌐 Открывайте в браузере:"
    echo "   👉 http://localhost:8000/index.html"
    echo "   👉 http://localhost:8000/direct.html (без кеша)"
    echo ""
    echo "⏹️  Для остановки: Ctrl+C"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    echo "✅ Python найден"
    echo ""
    echo "🌐 Открывайте в браузере:"
    echo "   👉 http://localhost:8000/index.html"
    echo "   👉 http://localhost:8000/direct.html (без кеша)"
    echo ""
    echo "⏹️  Для остановки: Ctrl+C"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    python -m http.server 8000
else
    echo "❌ Python не найден"
    echo ""
    echo "Установите Python:"
    echo "  • Windows: https://www.python.org/downloads/"
    echo "  • macOS: brew install python3"
    echo "  • Linux: sudo apt install python3"
    echo ""
    exit 1
fi
