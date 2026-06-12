# =============================================================
#  VibeVoice Setup Script - Windows + uv
#  RTX 4060 8GB | Python 3.12 | CUDA 12.x
# =============================================================

param(
    [switch]$SkipFlashAttn,
    [switch]$Try7B
)

$ErrorActionPreference = "Stop"
$VV_DIR = "$HOME\vibevoice"
$MODEL_1_5B = "vibevoice/VibeVoice-1.5B"
$MODEL_7B   = "vibevoice/VibeVoice-7B"

function Write-Step($msg) {
    Write-Host "`n===> $msg" -ForegroundColor Cyan
}
function Write-OK($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}
function Write-Warn($msg) {
    Write-Host "  [!!] $msg" -ForegroundColor Yellow
}

# -------------------------------------------------------------
# 0. Vérifications préalables
# -------------------------------------------------------------
Write-Step "Vérification des prérequis"

# Python
$pyVer = python --version 2>&1
if ($pyVer -notmatch "3\.12") {
    Write-Warn "Python 3.12 non détecté ($pyVer). Assure-toi que scoop reset python@3.12.9 a été fait."
    exit 1
}
Write-OK "Python : $pyVer"

# uv
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Step "Installation de uv"
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:PATH += ";$HOME\.local\bin"
}
Write-OK "uv : $(uv --version)"

# ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Step "Installation de ffmpeg via winget"
    winget install --id Gyan.FFmpeg -e --silent
} else {
    Write-OK "ffmpeg déjà présent"
}

# nvidia-smi
$smi = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warn "nvidia-smi introuvable. Vérifie tes drivers NVIDIA."
    exit 1
}
Write-OK "GPU détecté : $smi"

# -------------------------------------------------------------
# 1. Cloner le repo community fork
# -------------------------------------------------------------
Write-Step "Clonage du repo VibeVoice (community fork)"

if (Test-Path $VV_DIR) {
    Write-Warn "Dossier $VV_DIR déjà existant, pull des dernières mises à jour..."
    Set-Location $VV_DIR
    git pull
} else {
    git clone https://github.com/vibevoice-community/VibeVoice.git $VV_DIR
    Set-Location $VV_DIR
}
Write-OK "Repo prêt dans $VV_DIR"

# -------------------------------------------------------------
# 2. Créer un venv uv isolé
# -------------------------------------------------------------
Write-Step "Création du venv Python 3.12 avec uv"

uv venv .venv --python 3.12
$env:PATH = "$VV_DIR\.venv\Scripts;$env:PATH"
Write-OK "Venv créé : $VV_DIR\.venv"

# -------------------------------------------------------------
# 3. Installer PyTorch CUDA 12.1
# -------------------------------------------------------------
Write-Step "Installation de PyTorch avec support CUDA 12.1"

uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
Write-OK "PyTorch installé"

# -------------------------------------------------------------
# 4. Installer les dépendances VibeVoice
# -------------------------------------------------------------
Write-Step "Installation des dépendances VibeVoice"

# Versions pinées requises pour la compatibilité
uv pip install transformers==4.51.3 accelerate==1.6.0
uv pip install -e .
uv pip install gradio huggingface_hub sentencepiece openai
Write-OK "Dépendances installées"

# -------------------------------------------------------------
# 5. Flash Attention (optionnel mais recommandé)
# -------------------------------------------------------------
if (-not $SkipFlashAttn) {
    Write-Step "Installation de Flash Attention (wheel précompilé)"
    Write-Warn "Cette étape peut prendre quelques minutes..."

    # Wheel précompilé pour Python 3.12 + CUDA 12.x + Windows
    $faUrl = "https://github.com/kingbri1/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu124torch2.6.0cxx11abiFALSE-cp312-cp312-win_amd64.whl"
    $faFile = "$env:TEMP\flash_attn.whl"

    try {
        Invoke-WebRequest -Uri $faUrl -OutFile $faFile -UseBasicParsing
        uv pip install $faFile
        Write-OK "Flash Attention installé"
    } catch {
        Write-Warn "Flash Attention non disponible pour cette combinaison. Skipped (VibeVoice fonctionne sans)."
    }
} else {
    Write-Warn "Flash Attention ignoré (--SkipFlashAttn). Légèrement plus lent, mais fonctionnel."
}

# -------------------------------------------------------------
# 6. Créer les dossiers de voix
# -------------------------------------------------------------
Write-Step "Préparation du dossier de voix personnalisées"

$voicesDir = "$VV_DIR\demo\voices"
if (-not (Test-Path $voicesDir)) {
    New-Item -ItemType Directory -Path $voicesDir | Out-Null
}
Write-OK "Dossier de voix : $voicesDir"
Write-Host "  --> Dépose tes fichiers .wav / .mp3 dans ce dossier pour le clonage de voix" -ForegroundColor DarkCyan

# -------------------------------------------------------------
# 7. Créer les scripts de lancement
# -------------------------------------------------------------
Write-Step "Création des scripts de lancement"

# Lance le démo Gradio (1.5B)
@"
@echo off
cd /d "$VV_DIR"
call .venv\Scripts\activate
python demo\gradio_demo.py --model_path $MODEL_1_5B --device cuda --share
pause
"@ | Set-Content "$VV_DIR\launch_demo_1.5B.bat"

# Lance le démo Gradio (1.5B, local uniquement, sans --share)
@"
@echo off
cd /d "$VV_DIR"
call .venv\Scripts\activate
python demo\gradio_demo.py --model_path $MODEL_1_5B --device cuda
pause
"@ | Set-Content "$VV_DIR\launch_demo_local.bat"

if ($Try7B) {
    @"
@echo off
cd /d "$VV_DIR"
call .venv\Scripts\activate
python demo\gradio_demo.py --model_path $MODEL_7B --device cuda --load-in-4bit
pause
"@ | Set-Content "$VV_DIR\launch_demo_7B_4bit.bat"
    Write-OK "Script 7B 4-bit créé (expérimental sur 8GB VRAM)"
}

Write-OK "Scripts créés dans $VV_DIR"

# -------------------------------------------------------------
# 8. Résumé final
# -------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor Magenta
Write-Host "  VibeVoice prêt !" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Dossier          : $VV_DIR"
Write-Host "  Voix custom      : $voicesDir"
Write-Host ""
Write-Host "  Lancer la démo   :" -ForegroundColor White
Write-Host "    -> Double-clic sur : launch_demo_1.5B.bat  (avec lien public)" -ForegroundColor Green
Write-Host "    -> Double-clic sur : launch_demo_local.bat  (local uniquement)" -ForegroundColor Green
Write-Host ""
Write-Host "  Ou depuis Git Bash / PowerShell :" -ForegroundColor White
Write-Host "    cd $VV_DIR" -ForegroundColor DarkCyan
Write-Host "    .venv\Scripts\activate" -ForegroundColor DarkCyan
Write-Host "    python demo\gradio_demo.py --model_path $MODEL_1_5B --device cuda" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Interface Gradio : http://127.0.0.1:7860" -ForegroundColor Yellow
Write-Host ""
Write-Warn "Rappel : surveille tes températures GPU (BSODs VIDEO_TDR_FAILURE)"
Write-Host ""
