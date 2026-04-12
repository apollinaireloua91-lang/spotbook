# Extension Stitch pour Gemini CLI

## Installation effectuée (depuis `stitch-main.zip`)

Les fichiers ont été déployés dans :

```text
~/.gemini/extensions/Stitch/
```

Contenu attendu : `commands/stitch.toml`, `gemini-extension.json`, `gemini-extension-apikey.json`, `gemini-extension-adc.json`, `README.md`, etc.

## Prérequis

- **Gemini CLI** ≥ **0.19.0** : [geminicli.com](https://geminicli.com/) / [documentation extensions](https://google-gemini.github.io/gemini-cli/docs/extensions/)

Vérifier dans un terminal :

```bash
gemini --version
```

Si la commande est absente, installe la CLI puis rouvre le terminal.

## Alternative : installation officielle (GitHub)

```bash
gemini extensions install https://github.com/gemini-cli-extensions/stitch --auto-update
```

## Authentification (obligatoire)

### Option A — Clé API Stitch

1. [Stitch](https://stitch.withgoogle.com/) → profil → **Stitch Settings** → **API Keys** → **Create Key**
2. Générer `gemini-extension.json` :

```bash
export API_KEY="ta-clé-ici"
sed "s/YOUR_API_KEY/$API_KEY/g" ~/.gemini/extensions/Stitch/gemini-extension-apikey.json > ~/.gemini/extensions/Stitch/gemini-extension.json
```

### Option B — ADC (Google Cloud)

Suivre les étapes du `README.md` dans `~/.gemini/extensions/Stitch/` (gcloud, quota project, `gcloud beta services mcp enable stitch.googleapis.com`, IAM, `gcloud auth application-default login`), puis :

```bash
export PROJECT_ID="ton-project-gcp"
sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" ~/.gemini/extensions/Stitch/gemini-extension-adc.json > ~/.gemini/extensions/Stitch/gemini-extension.json
```

## Utilisation

```bash
gemini
```

Dans la CLI :

- `/mcp list` / `/mcp desc` — outils MCP Stitch
- `/stitch …` — commandes décrites dans le README de l’extension (projets, écrans, téléchargements, etc.)

## Mise à jour manuelle depuis un nouveau zip

```bash
rm -rf ~/.gemini/extensions/Stitch
unzip -q -o ~/Downloads/stitch-main.zip -d ~/.gemini/extensions
mv ~/.gemini/extensions/stitch-main ~/.gemini/extensions/Stitch
# Puis refaire la section Authentification (sed) si besoin
```

## Sécurité

Ne commite **jamais** `gemini-extension.json` s’il contient une vraie clé ; ce fichier reste sous `~/.gemini/`, hors du dépôt Spotbook.
