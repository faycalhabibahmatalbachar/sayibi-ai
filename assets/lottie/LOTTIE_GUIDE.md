# Animations Lottie — SAYIBI AI

Les fichiers `*.json` dans ce dossier sont **générés automatiquement** par le script :

```bash
cd sayibi_flutter
python tool/generate_lottie_assets.py
```

Le script produit des animations **Bodymovin / Lottie 5.7** (formes vectorielles, images clés d’opacité, échelle, taille) aux couleurs SAYIBI (violet `#6C63FF`, teal `#00D4AA`, etc.).

## Fichiers

| Fichier | Contenu généré |
|---------|----------------|
| `splash.json` | Anneau + noyau pulsés |
| `ai_thinking.json` | Halo + « cerveau » + point lumineux |
| `loading.json` | 3 points violet, déphasés |
| `typing.json` | 3 points teal, déphasés |
| `error.json` | Pastille rouge + croix |
| `success.json` | Pastille verte + check simplifié |
| `voice_wave.json` | 5 barres type égaliseur |
| `file_generating.json` | Feuille + lignes de texte |
| `empty_chat.json` | Visage robot minimal |
| `upload.json` | Nuage + flèche |
| `onboarding_1.json` … `_3.json` | Panneau + icône + pastille (couleurs différentes) |
| `search_web.json` | Loupe stylisée |
| `no_internet.json` | Barres + slash |
| `empty_docs.json` | Dossier + onglet + feuille |

Pour modifier le design, éditez `tool/generate_lottie_assets.py` puis régénérez. Vous pouvez aussi remplacer un JSON par un export After Effects / LottieFiles en conservant le **même nom de fichier** pour que les références `assets/lottie/...` dans le code restent valides.
