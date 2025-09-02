#!/usr/bin/env pwsh
# Run backend Flask API directly with Python

# Change to the scripts directory
Set-Location -Path $PSScriptRoot

# Activate virtual environment if exists (optional, uncomment if needed)
# if (Test-Path ".venv/Scripts/Activate.ps1") { . .venv/Scripts/Activate.ps1 }

# Run the backend Flask API
python backend_api.py
