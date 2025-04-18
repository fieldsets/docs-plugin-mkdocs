#!/usr/bin/env pwsh

<###
 # Run Phase Scipt
 # This plugin will be at the end of every startup with the priority defined in plugin.json
 ###>

$plugin_path = (Get-Location).Path

Write-Output "## Fieldsets Plugin Boilerplate Run Phase ##"
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
        if ($config.ContainsKey('sites')) {
            $site_configs = $config['sites']
            foreach ($site_config in $site_configs) {
                if ($site_config -contains 'app_path') {
                    $site_path = $site_config.('app_path')
                    Set-Location -Path "$($app_path)/$($site_path)"
                    $source_dir = 'docs'
                    $build_dir = 'build'

                    if ($site_config -contains 'source_path') {
                        $source_dir = $site_config.('source_path')
                    }
                    if ($site_config -contains 'build_path') {
                        $build_dir = $site_config.('build_path')
                    }

                    # Create build directory if it doesn't exist
                    if (!(Test-Path -Path "$($app_path)/$($site_path)/$($build_dir)")) {
                        New-Item -Path "$($app_path)/$($site_path)" -Name "$($build_dir)" -ItemType Directory | Out-Null
                    }

                    # Only buuild if source path exists
                    if (Test-Path -Path "$($app_path)/$($site_path)/$($source_dir)") {
                        $build_options = '--use-directory-urls --dirty True'
                        if ($site_config -contains 'options') {
                            $build_options = $site_config.('options')
                        }

                        $config_file = "$($app_path)/$($site_path)/$($source_dir)/mkdocs.yml"
                        if ($site_config -contains 'config_file') {
                            $config_file = "$($app_path)/$($site_path)/$($source_dir)/$($site_config.('config_file'))"
                        }

                        $site_url = "localhost:8000/$($site_path)"
                        if ($site_config -contains 'host') {
                            if ($site_config -contains 'uri') {
                                $site_url = "$($site_config.('host'))/$($site_config.('uri'))"
                            } else {
                                $site_url = "$($site_config.('host'))/$($site_path)"
                            }
                        }

                        $theme = "mkdocs"
                        if ($site_config -contains 'theme') {
                            $theme = $site_config.('theme')
                        }

                        $processOptions = @{
                            Filepath ="mkdocs"
                            ArgumentList = "serve --config-file '$($config_file)' --theme '$($theme)' --dev-addr '$($site_url)' --watch '$($app_path)/$($site_path)/$($source_dir)' $($build_options)"
                            RedirectStandardInput = "/dev/null"
                            RedirectStandardOutput = "$($log_path)/$($plugin_token)/$($plugin_token).log"
                            RedirectStandardError = "$($log_path)/$($plugin_token)/$($plugin_token).error.log"
                        }
                        Start-Process @processOptions
                    }
                }
            }
        }
    }
}
Set-Location -Path $app_path
Exit