#!/usr/bin/env pwsh

<###
 # Run Phase Scipt
 # This plugin will be at the end of every startup with the priority defined in plugin.json
 ###>

$plugin_token = 'docs-plugin-mkdocs'
$plugin_path = '/usr/local/fieldsets/plugins/docs-plugin-mkdocs'

$plugin = Get-Content -Raw -Path "$($plugin_path)/plugin.json" | ConvertFrom-Json -AsHashtable
if ($plugin.ContainsKey('token') -and ($null -ne $plugin['token'])) {
    $plugin_token = $plugin['token']
}

Write-Output "## Fieldsets MkDocs Documentation Plugin Run Phase ##"
Write-Output "$($plugin_path)"

$app_path = '/usr/local/fieldsets/apps'
$log_path = "/usr/local/fieldsets/data/logs/plugins"
$log_file = "$($log_path)/$($plugin_token)/$($plugin_token).log"
Set-Location -Path $app_path
if (Test-Path -Path "$($plugin_path)/config.json") {
    $config = Get-Content -Raw -Path "$($plugin_path)/config.json" | ConvertFrom-Json -AsHashtable
    if ($config.ContainsKey('sites')) {
        $site_configs = $config['sites']

        foreach ($site_config in $site_configs) {
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

                # Only run if build path exists
                if (Test-Path -Path "$($app_path)/$($site_path)/$($build_dir)") {
                    $build_options = '--use-directory-urls'
                    if ($site_config.ContainsKey('options')) {
                        $build_options = $site_config.('options')
                    }

                    $config_file = "$($app_path)/$($site_path)/mkdocs.yml"
                    if ($site_config.ContainsKey('config_file')) {
                        $config_file = "$($app_path)/$($site_path)/$($site_config.('config_file'))"
                    }

                    $site_url = "0.0.0.0:8000"
                    if ($site_config.ContainsKey('host')) {
                        if ($site_config.ContainsKey('uri')) {
                            $site_url = "$($site_config.('host'))"
                        } else {
                            $site_url = "$($site_config.('host'))"
                        }
                    }

                    $theme = "mkdocs"
                    if ($site_config.ContainsKey('theme')) {
                        $theme = $site_config.('theme')
                    }

                    $python3 = (Get-Command python3).Source
                    $mkdocs = (Get-Command mkdocs).Source
                    $nohup = (Get-Command nohup).Source
                    $processOptions = @{
                        Filepath = $nohup
                        ArgumentList = "$($python3) $($mkdocs) serve --config-file $($config_file) --theme $($theme) --dev-addr $($site_url) --watch $($app_path)/$($site_path)/$($source_dir) $($build_options)"
                        RedirectStandardInput = "/dev/null"
                        RedirectStandardError = "/dev/tty"
                        RedirectStandardOutput = $log_file
                    }

                    Start-Process @processOptions
                }
            }
        }
    }
}
Set-Location -Path $app_path
Exit