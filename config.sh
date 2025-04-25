#!/usr/bin/env pwsh

<###
 # Config Phase Scipt
 # This plugin will be run at the beginning every startup with the priority defined in plugin.json
 ###>

$plugin_path = (Get-Location).Path

Write-Output "## Fieldsets MkDocs Documentation Plugin Config Phase ##"
Write-Output "$($plugin_path)"

$plugin = Get-Content -Raw -Path "$($plugin_path)/plugin.json" | ConvertFrom-Json -AsHashtable
$plugin_token = $null
if ($plugin.ContainsKey('token') -and ($null -ne $plugin['token'])) {
    $plugin_token = $plugin['token']
}
$app_path = '/usr/local/fieldsets/apps'

$log_file = "$($log_path)/$($plugin_token)/$($plugin_token).log"

$python3 = (Get-Command python3).Source
$mkdocs = (Get-Command mkdocs).Source

Set-Location -Path $app_path
# You can utilize a custom config.json file
if (Test-Path -Path "$($plugin_path)/config.json") {
    $config = Get-Content -Raw -Path "$($plugin_path)/config.json" | ConvertFrom-Json -AsHashtable
    if ($config.ContainsKey('sites')) {
        $site_configs = $config['sites']
        foreach ($site_config in $site_configs) {
            Set-Location -Path $app_path
            if ($site_config.ContainsKey('app_path')) {
                $site_path = $site_config.('app_path')
                if (!(Test-Path -Path "$($app_path)/$($site_path)")) {
                    $processOptions = @{
                        Filepath = $python3
                        ArgumentList = "$($mkdocs) new $($site_path)"
                        RedirectStandardInput = "/dev/null"
                        RedirectStandardError = "/dev/tty"
                        RedirectStandardOutput = $log_file
                    }

                    Start-Process @processOptions
                }
                Set-Location -Path "$($app_path)/$($site_path)"
                $config_file = 'mkdocs.yml'
                if ($site_config.ContainsKey('config_file')) {
                    $config_file = $site_config.('config_file')
                }
                if (!(Test-Path -Path "$($app_path)/$($site_path)/$($config_file)")) {
                    New-Item -Path "$($app_path)/$($site_path)" -Name "$($config_file)" -ItemType File | Out-Null
                    $site_name = $site_path
                    if ($site_config.ContainsKey('name')) {
                        $site_name = $site_config.('name')
                    }
                    "site_name: $($site_name)`n" | Out-File -FilePath "$($app_path)/$($site_path)/$($config_file)" -Append -Encoding utf8

                    $site_url = "0.0.0.0:8000/$($site_path)"
                    if ($site_config.ContainsKey('host')) {
                        if ($site_config.ContainsKey('uri')) {
                            $site_url = "$($site_config.('host'))/$($site_config.('uri'))"
                        } else {
                            $site_url = "$($site_config.('host'))/$($site_path)"
                        }
                    }
                    "site_url: http://$($site_url)`n" | Out-File -FilePath "$($app_path)/$($site_path)/$($config_file)" -Append -Encoding utf8

                    $docs_dir = "$($app_path)/$($site_path)/docs"
                    if ($site_config.ContainsKey('source_path')) {
                        $docs_dir = "$($app_path)/$($site_path)/$($site_config.('source_path'))"
                    }
                    "docs_dir: $($docs_dir)`n" | Out-File -FilePath "$($app_path)/$($site_path)/$($config_file)" -Append -Encoding utf8

                    $site_dir = "$($app_path)/$($site_path)/site"
                    if ($site_config.ContainsKey('build_path')) {
                        $docs_dir = "$($app_path)/$($site_path)/$($site_config.('build_path'))"
                    }
                    "site_dir: $($site_dir)`n" | Out-File -FilePath "$($app_path)/$($site_path)/$($config_file)" -Append -Encoding utf8
                }
            }
        }
    }
} else {
    Write-Output "Missing config.json file for plugin: $($plugin_token)"
}
Set-Location -Path $app_path

Exit
