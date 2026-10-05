# setup-l1.ps1 - MERN Bookstore, Laborator L1
# Put this file in C:\Facultate\ANUL 2\SEM 1\Sisteme web\project and run it from there:
#   powershell -ExecutionPolicy Bypass -File .\setup-l1.ps1

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

function Run-Npm {
    # npm.cmd avoids the npm.ps1 execution-policy problem
    & npm.cmd @args
    if ($LASTEXITCODE -ne 0) { throw "npm $($args -join ' ') failed (exit $LASTEXITCODE)" }
}

function Write-Utf8NoBom($path, $text) {
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

# --- 0. Prerequisites ---------------------------------------------------------
Step "Checking prerequisites"
foreach ($tool in 'node', 'npm.cmd', 'git') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not found. Install Node (via nvm-windows) and Git first."
    }
}
Write-Host "node: $(node --version)"
Write-Host "npm:  $(npm.cmd --version)"
Write-Host "git:  $(git --version)"

$gitName  = git config --global user.name
$gitEmail = git config --global user.email
if (-not $gitName -or -not $gitEmail) {
    Write-Warning "Git identity is not set. Run these first, then re-run the script:"
    Write-Host '  git config --global user.name "Prenume Nume"'
    Write-Host '  git config --global user.email "adresa.voastra@student.uaic.ro"'
    Write-Host '  git config --global init.defaultBranch main'
    throw "Git identity missing."
}

# --- 1. Folders ---------------------------------------------------------------
Step "Creating folders"
foreach ($d in 'backend', 'frontend', 'docs', 'backend\data', 'backend\__tests__') {
    New-Item -ItemType Directory -Force -Path (Join-Path $root $d) | Out-Null
}

if (-not (Test-Path (Join-Path $root '.git'))) {
    git init -b main | Out-Null
}

# --- 2. Root .gitignore -------------------------------------------------------
Step "Writing .gitignore"
$gitignore = @'
# Dependente (se reinstaleaza cu npm install)
node_modules/

# Variabile de mediu - contin secrete
.env
.env.local
.env.*.local

# Build-uri si rapoarte
dist/
build/
coverage/

# Jurnale
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Fisiere de sistem si de editor
.DS_Store
Thumbs.db
.idea/
.vscode/
'@
Write-Utf8NoBom (Join-Path $root '.gitignore') $gitignore

# --- 3. Backend ---------------------------------------------------------------
Step "Backend: package.json"
Set-Location (Join-Path $root 'backend')
if (-not (Test-Path 'package.json')) { Run-Npm init -y | Out-Null }

Run-Npm pkg set 'name=mern-bookstore-backend'
Run-Npm pkg set 'description=Backend API pentru aplicatia MERN BookStore ECommerce'
Run-Npm pkg set 'main=server.js'
Run-Npm pkg set 'type=commonjs'
Run-Npm pkg set 'author=SDBIS'
Run-Npm pkg set 'license=MIT'
Run-Npm pkg set 'scripts.start=node server.js'
Run-Npm pkg set 'scripts.dev=nodemon server.js'
Run-Npm pkg set 'scripts.test=vitest'
Run-Npm pkg set 'scripts.test:run=vitest run'

Step "Backend: installing dependencies"
Run-Npm install express cors helmet compression morgan dotenv
Run-Npm install jsonwebtoken bcryptjs express-rate-limit validator
Run-Npm install --save-dev nodemon vitest supertest

Step "Backend: files"
foreach ($f in 'server.js', 'data\books.json', 'data\cart.json') {
    if (-not (Test-Path $f)) { New-Item -ItemType File -Path $f | Out-Null }
}

$jwtSecret = (& node -e "console.log(require('crypto').randomBytes(32).toString('hex'))").Trim()

$envFile = @"
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:5173
# Completate in laboratoarele urmatoare:
JWT_SECRET=$jwtSecret
STRIPE_SECRET_KEY=sk_test_completati_in_L5
"@
if (-not (Test-Path '.env')) { Write-Utf8NoBom (Join-Path (Get-Location) '.env') $envFile }
else { Write-Host ".env already exists, left untouched" }

$envExample = @'
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:5173
JWT_SECRET=
STRIPE_SECRET_KEY=
'@
Write-Utf8NoBom (Join-Path (Get-Location) '.env.example') $envExample

Step "Backend: npm ls --depth=0"
& npm.cmd ls --depth=0

# --- 4. Frontend --------------------------------------------------------------
Step "Frontend: Vite + React"
Set-Location (Join-Path $root 'frontend')
if (-not (Test-Path 'package.json')) {
    Run-Npm create vite@latest . -- --template react --no-interactive
}
Run-Npm install
Run-Npm install react-router-dom axios
Run-Npm install --save-dev vitest jsdom @testing-library/react @testing-library/dom @testing-library/jest-dom @testing-library/user-event

Run-Npm pkg set 'name=mern-bookstore-frontend'
Run-Npm pkg set 'description=Frontend pentru aplicatia MERN BookStore ECommerce'
Run-Npm pkg set 'scripts.test=vitest'
Run-Npm pkg set 'scripts.test:run=vitest run'

# --- 5. Docs + README ---------------------------------------------------------
Step "README and docs"
Set-Location $root
Write-Utf8NoBom (Join-Path $root 'README.md') "# MERN Bookstore`n"

$answers = @'
# L1 - Raspunsuri

## 1. Diferenta dintre dependencies si devDependencies

(completati)

## 2. De ce se urca package-lock.json in Git, dar nu node_modules/ si .env?

(completati)

## 3. Scriptul optional "dev:watch": "node --watch server.js" ca alternativa la nodemon

(completati)
'@
Write-Utf8NoBom (Join-Path $root 'docs\L1-raspunsuri.md') $answers

# --- 6. First commit ----------------------------------------------------------
Step "Git status check (node_modules/ and .env must NOT appear)"
git status --short

$tracked = git ls-files --others --exclude-standard
if ($tracked -match 'node_modules' -or $tracked -match '(^|/)\.env$') {
    throw "node_modules/ or .env would be committed. Check .gitignore."
}

git add .
git commit -m "L1: structura proiectului, backend si frontend initializate"

Step "git log"
git log --oneline

Write-Host "`nDone. Test the frontend with:  cd frontend; npm run dev   (http://localhost:5173)" -ForegroundColor Green
