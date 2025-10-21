# VS Code + GitHub Workspace Guide

**Workspace root:**
`C:\Users\TylerGates\Dev\GitHub`

Everything lives inside this folder as separate repositories:

* `Microsoft_Powershell_Projects`
* `Bash_Projects`
* `HTML_Projects`
* `Python_Projects`
* `.vscode` (workspace settings)
* `Tyler-GitHub.code-workspace`

---

## 1) Daily Workflow (Short Version)

1. **Open VS Code** at `C:\Users\TylerGates\Dev\GitHub`.
2. **Sync before work**

   ```powershell
   git status
   git switch main
   git pull --ff-only
   ```
3. **Create a branch**

   ```powershell
   git checkout -b <type>/<short-name>
   ```

   Examples: `docs/update-readme`, `feat/new-script`, `fix/typo`.
4. **Make changes** → save (auto-format + lint).
5. **Commit**

   ```powershell
   git add .
   git commit -m "<type>: clear message"
   ```
6. **Push + Pull Request**

   ```powershell
   git push -u origin <branch>
   gh pr create --fill --web
   ```

   Merge PR in browser.
7. **Sync and clean up**

   ```powershell
   git switch main
   git pull --ff-only
   git branch -d <branch>
   ```

---

## 2) Best Practices

* **Pull first** every session (`git pull --ff-only` on `main`).
* **One task = one branch**; keep changes small and focused.
* **Commit messages** use prefixes: `docs:`, `feat:`, `fix:`, `chore:`.
* **Never commit secrets** (passwords, keys, tokens).
* **Let the linter help**; yellow squiggles are guidance.
* **Use PowerShell 7** (default everywhere in this workspace).

---

## 3) Create a New Repository (GitHub + Local)

1. On GitHub (web): **New → Repository** (empty repo).

2. Clone into the workspace:

```powershell
cd "C:\Users\TylerGates\Dev\GitHub"
gh repo clone NerdyOreo/<RepoName>
```

3. Optional starter structure:

```powershell
cd .\<RepoName>
mkdir Scripts, Docs
ni README.md -ItemType File -Force
Add-Content README.md "# <RepoName>`n`nPurpose: ..."
```

4. First commit:

```powershell
git add .
git commit -m "chore: initial structure (Scripts, Docs, README)"
git push -u origin main
```

---

## 4) Add a New Folder to an Existing Repo

Example: `Microsoft_Powershell_Projects` → `Intune\Deployment_Guides`

```powershell
cd "C:\Users\TylerGates\Dev\GitHub\Microsoft_Powershell_Projects"
git switch main
git pull --ff-only
git checkout -b docs/add-intune-deployment-guides

mkdir ".\Intune\Deployment_Guides" -Force
ni ".\Intune\Deployment_Guides\README.md" -ItemType File -Force
Add-Content ".\Intune\Deployment_Guides\README.md" @"
# Intune – Deployment Guides
Purpose: step-by-step runbooks for repeatable, auditable deployments.
Owner: Tyler
Last updated: $(Get-Date -Format yyyy-MM-dd)
"@

git add .
git commit -m "docs: add Intune/Deployment_Guides with starter README"
git push -u origin docs/add-intune-deployment-guides
gh pr create --fill --web
# merge PR in browser
git switch main
git pull --ff-only
git branch -d docs/add-intune-deployment-guides
```

---

## 5) Run, Lint, and Format (VS Code)

* **Run current script:** `Ctrl + Shift + B` → *PS: Run active script*
* **Lint workspace:** `Terminal → Run Task… → PS: Lint workspace`
* **Format all PowerShell files:** `Terminal → Run Task… → PS: Format all (*.ps1, *.psm1)`
* **Debug current script:** `F5` (breakpoints supported)

*(Tasks and debug profile are defined in `.vscode\tasks.json` and `.vscode\launch.json`.)*

---

## 6) Keep Everything in Sync (Safe Procedures)

**A) No local changes**

```powershell
git switch main
git pull --ff-only
```

**B) Local edits block pull**

```powershell
git stash push -u -m "temp before sync"
git switch main
git pull --ff-only
git stash pop
```

**C) Local `main` diverged from `origin/main`**

```powershell
git fetch origin
git reset --hard origin/main
```

*(Use only when work is safely stashed or on a branch.)*

---

## 7) Recommended Repo Structure

```
<RepoName>
├─ Scripts/          # .ps1, .py, .sh
├─ Modules/          # reusable PowerShell modules
├─ Docs/             # READMEs, procedures, screenshots
├─ .vscode/          # optional repo-specific settings
└─ README.md         # purpose, how to run, where files go
```

---

## 8) Quick Troubleshooting

* **“Pull would overwrite local changes”** → Stash, pull, pop (see 6B).
* **“Branches have diverged”** → `git fetch` + `git reset --hard origin/main` (6C).
* **PowerShell 7 not active** → `PowerShell: Restart PowerShell Session` in VS Code.
* **Yellow squiggles** → linter suggestions; save to auto-format.
* **Wrong repo folder** → `git rev-parse --show-toplevel`.

---

## 9) Command Reference

```powershell
# Identify repo root
git rev-parse --show-toplevel

# Current branch
git rev-parse --abbrev-ref HEAD

# Remotes
git remote -v

# Recent commits
git log --oneline -5

# Start clean
git switch main
git pull --ff-only

# New branch
git checkout -b <type>/<short-scope>

# Stage + commit
git add .
git commit -m "<type>: message"

# Push + PR
git push -u origin <branch>
gh pr create --fill --web

# Finish
git switch main
git pull --ff-only
git branch -d <branch>
```

---

## 10) Files That Power This Workspace (already created)

**`C:\Users\TylerGates\Dev\GitHub\.vscode\settings.json`**

* PowerShell 7 default terminal
* Auto-format on save
* Linting rules enabled
* Git quality-of-life defaults

**`C:\Users\TylerGates\Dev\GitHub\.vscode\PSScriptAnalyzerSettings.psd1`**

* PowerShell lint rules (indentation, spacing, approved verbs, no aliases, avoid `Write-Host`)

**`C:\Users\TylerGates\Dev\GitHub\.vscode\tasks.json`**

* Run active script
* Lint workspace
* Format all
* Git sync

**`C:\Users\TylerGates\Dev\GitHub\.vscode\launch.json`**

* F5 to debug current PowerShell file

**`C:\Users\TylerGates\Dev\GitHub\.editorconfig`**

* LF endings, trim trailing whitespace, 4-space indent

**`C:\Users\TylerGates\Dev\GitHub\.gitattributes`**

* Normalize line endings across OS (LF)

---