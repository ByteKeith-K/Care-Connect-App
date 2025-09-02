# PowerShell script to run analytics pipeline
$venvPath = "C:\Users\Lax\AndroidStudioProjects\care_connect_app\.venv\Scripts\activate.ps1"
$analyticsScript = "C:\Users\Lax\AndroidStudioProjects\care_connect_app\scripts\firestore_to_analytics.py"

# Activate virtual environment and run analytics
& $venvPath
python $analyticsScript
