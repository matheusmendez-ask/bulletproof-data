<#
.SYNOPSIS
    Instalador da skill bulletproof-data para Antigravity / Gemini Code Assist (Windows)
.DESCRIPTION
    Instala a skill bulletproof-data na pasta global de configurações (~/.gemini/config/skills/bulletproof-data).
#>

$ErrorActionPreference = "Stop"

$TargetDir = Join-Path $HOME ".gemini\config\skills\bulletproof-data"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Instalando a skill 'bulletproof-data'..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verifica se os arquivos estao locais (executado a partir do repo clonado)
$LocalSkillDir = Join-Path $ScriptDir "bulletproof-data"
if ($ScriptDir -and (Test-Path -Path $LocalSkillDir)) {
    Write-Host "[1/2] Copiando arquivos locais para $TargetDir..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    Copy-Item -Path "$LocalSkillDir\*" -Destination $TargetDir -Recurse -Force
} else {
    # Download direto do repositório
    Write-Host "[1/2] Baixando a skill do GitHub..." -ForegroundColor Yellow
    $RepoZipUrl = "https://github.com/matheus/bulletproof-data/archive/refs/heads/main.zip"
    $TempZip = Join-Path $env:TEMP "bulletproof-data.zip"
    $TempExtract = Join-Path $env:TEMP "bulletproof-data-extract"

    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $TempZip
    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract

    $SourceFolder = Get-ChildItem -Path $TempExtract -Directory | Select-Object -First 1
    $ExtractedSkill = Join-Path $SourceFolder.FullName "bulletproof-data"

    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    Copy-Item -Path "$ExtractedSkill\*" -Destination $TargetDir -Recurse -Force

    Remove-Item -Force $TempZip
    Remove-Item -Recurse -Force $TempExtract
}

Write-Host "[2/2] Validando instalacao..." -ForegroundColor Yellow
if (Test-Path (Join-Path $TargetDir "SKILL.md")) {
    Write-Host ""
    Write-Host ">> Sucesso! A skill 'bulletproof-data' foi instalada em:" -ForegroundColor Green
    Write-Host "   $TargetDir" -ForegroundColor White
    Write-Host ""
    Write-Host "O Antigravity ja pode usar o metodo bulletproof-data em qualquer projeto!" -ForegroundColor Green
} else {
    Write-Host "Erro: SKILL.md nao encontrado no destino." -ForegroundColor Red
}
