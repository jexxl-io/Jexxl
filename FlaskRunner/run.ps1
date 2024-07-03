# Import necessary .NET classes for GUI
Add-Type -AssemblyName System.Windows.Forms

# Get the directory of the current script
$scriptDir = (Get-Item -Path ".\").FullName

# Function to start Flask app
function Start-FlaskApp {
    param($appPath, $appName)

    if (Test-FlaskAppRunning -appName $appName) {
        [System.Windows.Forms.MessageBox]::Show("$appName is already running.", "Info", "OK", "Information")
    }
    else {
        # Temporarily change directory to Flask app directory and activate virtual environment
        Push-Location $appPath
        try {
            # Activate virtual environment (assuming .venv exists)
            .\.venv\Scripts\Activate

            # Start Flask app using wsgi.py
            Start-Process python -ArgumentList ".\wsgi.py" -WindowStyle Hidden
        }
        finally {
            Pop-Location
        }
    }
}

# Function to stop Flask app by killing related Python processes
function Stop-FlaskApp {
    param($appName)

    # Get all Python processes related to the Flask app
    $processes = Get-Process python | Where-Object { $_.MainModule.FileName -like "*$appName*" }

    # If processes found, ask for confirmation to terminate
    if ($processes) {
        $confirmResult = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to terminate processes related to $($appName)?", "Confirm", "YesNo", "Question")
        if ($confirmResult -eq "Yes") {
            # Terminate each process forcefully
            foreach ($process in $processes) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
            [System.Windows.Forms.MessageBox]::Show("Processes terminated successfully.", "Success", "OK", "Information")
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("No processes related to $($appName) were found.", "No Processes", "OK", "Information")
    }
}

# Function to check if Flask app is running
function Test-FlaskAppRunning {
    param($appName)

    try {
        # Check if any Python process related to the Flask app is running
        $process = Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.MainModule.FileName -like "*$appName*" }
        return $null -ne $process
    }
    catch {
        return $false
    }
}

# Function to create GUI and handle button clicks
function Show-FlaskAppSelector {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "FlaskRunner"
    $form.Size = [System.Drawing.Size]::new(535, 300)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    # Set the icon for the form
    $iconPath = Join-Path $scriptDir "flask_icon.ico"
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = [System.Drawing.Point]::new(10, 20)
    $label.Size = [System.Drawing.Size]::new(480, 20)
    $label.Text = "Select Flask apps to start or stop:"

    # Get directories containing wsgi.py within the current directory
    $flaskAppDirs = Get-ChildItem -Path $scriptDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "wsgi.py") }

    # Create a ListView for Flask apps
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = [System.Drawing.Point]::new(10, 50)
    $listView.Size = [System.Drawing.Size]::new(500, 150)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true

    # Add columns to ListView
    $listView.Columns.Add("App Name", 90)
    $listView.Columns.Add("File Path", 340)
    $listView.Columns.Add("Running", 90)

    # Populate ListView with Flask app names, file paths, and running status
    foreach ($appDir in $flaskAppDirs) {
        $item = New-Object System.Windows.Forms.ListViewItem($appDir.Name)
        $item.SubItems.Add((Join-Path $appDir.FullName "wsgi.py"))
        $running = Test-FlaskAppRunning -appName $appDir.Name
        $item.SubItems.Add($running.ToString())
        $listView.Items.Add($item)
    }

    # Create Start button
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Location = [System.Drawing.Point]::new(10, 210)
    $startButton.Size = [System.Drawing.Size]::new(100, 30)
    $startButton.Text = "Start"
    $startButton.Enabled = $false
    $startButton.Add_Click({
        # Start selected Flask apps
        foreach ($item in $listView.SelectedItems) {
            $appPath = Join-Path $scriptDir $item.Text
            Start-FlaskApp -appPath $appPath -appName $item.Text
        }
        # Refresh the ListView to show updated running status
        $listView.Items.Clear()
        foreach ($appDir in $flaskAppDirs) {
            $item = New-Object System.Windows.Forms.ListViewItem($appDir.Name)
            $item.SubItems.Add((Join-Path $appDir.FullName "wsgi.py"))
            $running = Test-FlaskAppRunning -appName $appDir.Name
            $item.SubItems.Add($running.ToString())
            $listView.Items.Add($item)
        }
    })

    # Create Stop button
    $stopButton = New-Object System.Windows.Forms.Button
    $stopButton.Location = [System.Drawing.Point]::new(120, 210)
    $stopButton.Size = [System.Drawing.Size]::new(100, 30)
    $stopButton.Text = "Stop"
    $stopButton.Enabled = $false
    $stopButton.Add_Click({
        # Stop selected Flask apps
        foreach ($item in $listView.SelectedItems) {
            Stop-FlaskApp -appName $item.Text
        }
        # Refresh the ListView to show updated running status
        $listView.Items.Clear()
        foreach ($appDir in $flaskAppDirs) {
            $item = New-Object System.Windows.Forms.ListViewItem($appDir.Name)
            $item.SubItems.Add((Join-Path $appDir.FullName "wsgi.py"))
            $running = Test-FlaskAppRunning -appName $appDir.Name
            $item.SubItems.Add($running.ToString())
            $listView.Items.Add($item)
        }
    })

    # Enable/disable buttons based on selection
    $listView.add_ItemSelectionChanged({
        if ($listView.SelectedItems.Count -gt 0) {
            $startButton.Enabled = $true
            $stopButton.Enabled = $true
        }
        else {
            $startButton.Enabled = $false
            $stopButton.Enabled = $false
        }
    })

    # Add controls to the form
    $form.Controls.Add($label)
    $form.Controls.Add($listView)
    $form.Controls.Add($startButton)
    $form.Controls.Add($stopButton)

    # Show the form
    $form.ShowDialog()
}

# Show the Flask app selector GUI
Show-FlaskAppSelector
