#!/usr/bin/env bash
#
# Instalador da skill bulletproof-data para Antigravity / Gemini Code Assist (Linux/macOS)
#

set -e

TARGET_DIR="$HOME/.gemini/config/skills/bulletproof-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

echo "================================================="
echo "  Instalando a skill 'bulletproof-data'..."
echo "================================================="

mkdir -p "$TARGET_DIR"

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/bulletproof-data" ]; then
    echo "[1/2] Copiando arquivos locais para $TARGET_DIR..."
    cp -r "$SCRIPT_DIR/bulletproof-data/"* "$TARGET_DIR/"
else
    echo "[1/2] Baixando a skill do repositório..."
    TMP_DIR=$(mktemp -d)
    REPO_URL="https://github.com/matheusmendez-ask/bulletproof-data/archive/refs/heads/main.tar.gz"
    
    curl -fsSL "$REPO_URL" | tar -xz -C "$TMP_DIR"
    EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    cp -r "$EXTRACTED_DIR/bulletproof-data/"* "$TARGET_DIR/"
    rm -rf "$TMP_DIR"
fi

echo "[2/2] Validando instalação..."
if [ -f "$TARGET_DIR/SKILL.md" ]; then
    echo ""
    echo ">> Sucesso! A skill 'bulletproof-data' foi instalada em:"
    echo "   $TARGET_DIR"
    echo ""
    echo "O Antigravity já pode usar o método bulletproof-data em qualquer projeto!"
else
    echo "Erro: SKILL.md não encontrado no diretório de destino." >&2
    exit 1
fi
