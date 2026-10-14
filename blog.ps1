# Use an installed Hugo, or the checkout-local binary used for development.
[CmdletBinding()]
param(
    [ValidateSet('serve', 'build', 'new')]
    [string]$Command = 'serve',
    [string]$Path,
    [switch]$Drafts
)

$ErrorActionPreference = 'Stop'
$installedHugo = Get-Command hugo -ErrorAction SilentlyContinue
$localHugo = Join-Path $PSScriptRoot '.tools/hugo/hugo.exe'
if ($installedHugo) {
    $hugoExecutable = $installedHugo.Source
} elseif (Test-Path -LiteralPath $localHugo) {
    $hugoExecutable = $localHugo
} else {
    throw 'Install Hugo 0.158.0 or newer: https://gohugo.io/installation/'
}

switch ($Command) {
    'serve' {
        $hugoArguments = @('server', '--source', $PSScriptRoot, '--bind', '127.0.0.1')
        if ($Drafts) { $hugoArguments += '--buildDrafts' }
    }
    'build' {
        $hugoArguments = @('--source', $PSScriptRoot, '--minify')
        if ($Drafts) { $hugoArguments += '--buildDrafts' }
    }
    'new' {
        if (-not $Path -or $Path -notmatch '^posts/[a-zA-Z0-9][a-zA-Z0-9/-]*\.md$' -or $Path.Contains('..')) {
            throw 'Provide a post path, for example: ./blog.ps1 new -Path posts/my-first-post.md'
        }
        $hugoArguments = @('new', 'content', '--source', $PSScriptRoot, $Path)
    }
}
& $hugoExecutable @hugoArguments
if ($LASTEXITCODE -ne 0) { throw "Hugo exited with code $LASTEXITCODE" }
