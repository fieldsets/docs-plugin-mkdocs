#!/usr/bin/env pwsh

<###
 # Import Phase Scipt
 # This plugin will be run on every startup with the priority defined in plugin.json
 # To prevent data from being re-imported after the inital startup create a lockfile.
 ###>

Param(
    [Parameter(Mandatory=$false)][Switch]$preimport
)

$plugin_path = (Get-Location).Path

Write-Output "## Fieldsets MkDocs Documentation Plugin Import Phase ##"
Write-Output "$($plugin_path)"

$plugin = Get-Content -Raw -Path "$($plugin_path)/plugin.json" | ConvertFrom-Json -AsHashtable
$plugin_token = $null
if ($plugin.ContainsKey('token') -and ($null -ne $plugin['token'])) {
    $plugin_token = $plugin['token']
}

$app_path = '/usr/local/fieldsets/apps'
$log_path = "/usr/local/fieldsets/data/logs/plugins"
Set-Location -Path $app_path
if ($preimport) {

    if (Test-Path -Path "$($plugin_path)/config.json") {
        $config = Get-Content -Raw -Path "$($plugin_path)/config.json" | ConvertFrom-Json -AsHashtable
        Write-Output $config
        if ($config.ContainsKey('sites')) {
            $site_configs = $config['sites']
            foreach ($site_config in $site_configs) {
                Write-Output $site_config
                if ($site_config.ContainsKey('app_path')) {
                    $site_path = $site_config.('app_path')
                    Set-Location -Path "$($app_path)/$($site_path)"
                    $source_dir = 'docs'
                    $build_dir = 'build'

                    if ($site_config.ContainsKey('source_path')) {
                        $source_dir = $site_config.('source_path')
                    }
                    if ($site_config.ContainsKey('build_path')) {
                        $build_dir = $site_config.('build_path')
                    }

                    # Create build directory if it doesn't exist
                    if (!(Test-Path -Path "$($app_path)/$($site_path)/$($build_dir)")) {
                        New-Item -Path "$($app_path)/$($site_path)" -Name "$($build_dir)" -ItemType Directory | Out-Null
                    }

                    # Only buuild if source path exists
                    if (Test-Path -Path "$($app_path)/$($site_path)/$($source_dir)") {
                        $build_options = '--use-directory-urls'
                        if ($site_config.ContainsKey('options')) {
                            $build_options = $site_config.('options')
                        }

                        $config_file = "$($app_path)/$($site_path)/mkdocs.yml"
                        if ($site_config.ContainsKey('config_file')) {
                            $config_file = "$($app_path)/$($site_path)/$($site_config.('config_file'))"
                        }

                        $theme = "mkdocs"
                        if ($site_config.ContainsKey('theme')) {
                            $theme = $site_config.('theme')
                        }

                        $python3 = (Get-Command python3).Source
                        $mkdocs = (Get-Command mkdocs).Source

                        & "$($python3)" "$($mkdocs) build --config-file '$($config_file)' --theme '$($theme)' --site-dir '$($app_path)/$($site_path)/$($build_dir)' $($build_options)"

                    }
                }
            }
        }
    }
}
Set-Location -Path $app_path

Exit
