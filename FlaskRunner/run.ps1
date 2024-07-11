# Import necessary .NET classes for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Get the directory of the current script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Path to the configuration JSON file
$configFile = Join-Path $ScriptDir "config.json"

# Read the JSON file and parse it
Write-Host "Reading configuration from $configFile"
$config = Get-Content $configFile | ConvertFrom-Json

# Get the paths from the JSON file
$venvActivatePath = $config.venv_activate
$wsgiPaths = $config.wsgis

# Function to start Flask app
function Start-FlaskApp {
    param($appPath)

    # Temporarily change directory to Flask app directory
    Push-Location (Split-Path $appPath)
    try {
        # Debug output
        Write-Host "Starting Flask app in $appPath"

        # Start Flask app using wsgi.py
        Start-Process -FilePath "python" -ArgumentList $appPath -NoNewWindow -PassThru | Out-File -FilePath "$ScriptDir/log.txt" -Append
    }
    catch {
        Write-Error "Failed to start Flask app at $appPath. Error: $_"
    }
    finally {
        Pop-Location
    }
}

# Function to stop Flask apps by killing all Python processes
function Stop-FlaskApps {
    # Debug output
    Write-Host "Stopping all Flask apps"

    # Get all Python processes
    $processes = Get-Process python -ErrorAction SilentlyContinue

    # Terminate each process forcefully
    foreach ($process in $processes) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
}

# Function to create and show GUI
function Show-FlaskAppGUI {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "FlaskRunner"
    $form.Size = [System.Drawing.Size]::new(335, 160)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    # Set the icon for the form
    $iconPath = Join-Path $ScriptDir "flask_icon.ico"
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)

    # Create a ListView for Flask apps
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = [System.Drawing.Point]::new(10, 10)
    $listView.Size = [System.Drawing.Size]::new(300, 100)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.Columns.Add("App Name", 150)
    $listView.Columns.Add("Status", 146)

    # Create an ImageList for status icons
    $imageList = New-Object System.Windows.Forms.ImageList
    $greenDot = New-Object System.Drawing.Bitmap 15, 15
    $g = [System.Drawing.Graphics]::FromImage($greenDot)
    $g.FillEllipse([System.Drawing.Brushes]::Green, 2, 4.5, 8, 8)
    $imageList.Images.Add($greenDot)

    $listView.SmallImageList = $imageList

    # Add status "running"
    foreach ($path in $wsgiPaths) {
        $appName = (Split-Path (Split-Path $path -Parent) -Leaf)
        $item = New-Object System.Windows.Forms.ListViewItem($appName)
        $item.ImageIndex = 0
        $item.SubItems.Add("Running")
        $listView.Items.Add($item)
    }

    # Create event handler to stop Flask apps when form is closed
    $form.Add_FormClosing({
        Stop-FlaskApps
    })

    # Add controls to the form
    $form.Controls.Add($listView)

    # Show the form
    $form.ShowDialog()
}

try {
    # Set the current directory to the script directory
    Set-Location $ScriptDir

    # Activate virtual environment (assuming .venv exists)
    Write-Host "Activating virtual environment at $venvActivatePath"
    & $venvActivatePath

    # Verify virtual environment activation
    Write-Host "Virtual environment activated. Python path: $(Get-Command python).Path"

    # Ensure necessary packages are installed
    Write-Host "Installing necessary packages"
    pip install -r "C:\Jexxl\requirements.txt" | Out-File -FilePath "$ScriptDir/log.txt" -Append

    # Start each Flask app
    foreach ($path in $wsgiPaths) {
        Write-Host "Starting Flask app: $path"
        Start-FlaskApp -appPath $path
    }

    # Show the GUI
    Show-FlaskAppGUI
}
catch {
    Write-Error "An error occurred: $_"
    Read-Host "Press Enter to exit"
}
