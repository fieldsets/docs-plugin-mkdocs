#!/usr/bin/env pwsh

<###
 # Init Phase Scipt
 # This plugin will be run on the first startup with the priority defined in plugin.json
 ###>

$plugin_path = (Get-Location).Path

Write-Output "## Fieldsets MkDocs Documentation Plugin Init Phase ##"
Write-Output "$($plugin_path)"

$plugin = Get-Content -Raw -Path "$($plugin_path)/plugin.json" | ConvertFrom-Json -AsHashtable
$plugin_token = $null
if ($plugin.ContainsKey('token') -and ($null -ne $plugin['token'])) {
    $plugin_token = $plugin['token']
}

$log_path = "/usr/local/fieldsets/data/logs/plugins"
# Create our log path if it does not exist
if (!(Test-Path -Path "$($log_path)/$($plugin_token)/")) {
    New-Item -Path "$($log_path)" -Name "$($plugin_token)" -ItemType Directory | Out-Null
}
if (!(Test-Path -Path "$($log_path)/$($plugin_token)/$($plugin_token).log")) {
    New-Item -Path "$($log_path)/$($plugin_token)" -Name "$($plugin_token).log" -ItemType File | Out-Null
}

Exit
