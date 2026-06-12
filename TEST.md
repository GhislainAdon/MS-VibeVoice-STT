# VibeVoice - Guide de démarrage rapide

## Pré-requis validés avant de lancer le script
- [ ] `python --version` → Python 3.12.9
- [ ] `nvidia-smi` → RTX 4060 visible
- [ ] `uv --version` → uv installé
- [ ] Drivers NVIDIA récents (≥ 525.x)

---

## Installation (une seule fois)
Install de python 
```powershell
# installation de scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install python@3.12.10
# Méthode install uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   winget install ffmpeg
# Prérequis : Python 3.9+, CUDA installé
pip install openai-whisper
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
whisper audio.m4a --language fr --model medium
```
Ouvre **PowerShell en administrateur** et lance :

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser   # si pas encore fait
.\setup_vibevoice.ps1
```

### Options disponibles

```powershell
# Ignorer Flash Attention (si problème de compilation)
.\setup_vibevoice.ps1 -SkipFlashAttn

# Créer aussi le script 7B en 4-bit (expérimental, 8GB VRAM)
.\setup_vibevoice.ps1 -Try7B
```

---

## Lancement

Depuis `C:\Users\adon1\vibevoice\` :

| Fichier | Description |
|--------|-------------|
| `launch_demo_1.5B.bat` | Démo complète + lien public Gradio |
| `launch_demo_local.bat` | Démo locale uniquement (http://127.0.0.1:7860) |
| `launch_demo_7B_4bit.bat` | 7B quantisé 4-bit (si `-Try7B` utilisé) |

---

## Utilisation de la démo Gradio

1. Ouvre http://127.0.0.1:7860 dans ton navigateur
2. Choisis le nombre de locuteurs (1 à 4)
3. **Clonage de voix** : dépose un fichier `.wav` ou `.mp3` dans `demo/voices/`
4. Tape ton script dans la zone de texte
5. Ajuste le **CFG slider** entre 1.30 et 1.35 pour de meilleurs résultats
6. Clique sur **Generate**

---

## Ajouter des voix personnalisées

```
vibevoice/
└── demo/
    └── voices/
        ├── ma_voix.wav       ← fichier court 5-10s suffit
        ├── voix_client.mp3
        └── ...
```

Les fichiers apparaissent automatiquement dans le dropdown Speaker.

---

## Modèles disponibles

| Modèle | VRAM | Qualité | Ton RTX 4060 |
|--------|------|---------|-------------|
| VibeVoice-1.5B | ~7 GB | Bonne | ✅ Recommandé |
| VibeVoice-7B FP16 | ~19 GB | Excellente | ❌ |
| VibeVoice-7B 4-bit | ~8 GB | Très bonne | ⚠️ Limite |

---

## Dépannage

### `CUDA out of memory`
→ Ferme Ollama, VS Code avec extensions GPU, autres applis avant de lancer.

### `VIDEO_TDR_FAILURE` (BSOD)
→ Limite la charge GPU : utilise des textes courts lors des premiers tests.  
→ Vérifie que le mode d'alimentation PCIe est en **Maximum Performance** dans les options NVIDIA.

### Flash Attention ne compile pas
→ Relance avec `-SkipFlashAttn` : VibeVoice fonctionne sans, juste un peu plus lent.

### Le modèle ne se télécharge pas
→ Vérifie ta connexion. Les poids (~3 GB pour 1.5B) sont téléchargés depuis Hugging Face au premier lancement.

---

