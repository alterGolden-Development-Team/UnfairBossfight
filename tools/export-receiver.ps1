# One-shot receiver for the Studio script export (see README).
# Studio POSTs JSON batches [{path, content}, ...] to http://localhost:34999/files; each path is written
# under the project root (relative paths only, no "..", nothing outside the root). POST /done stops it.
param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = "Stop"
$rootFull = [System.IO.Path]::GetFullPath($Root)
$utf8 = New-Object System.Text.UTF8Encoding $false
Add-Type -AssemblyName System.Web.Extensions
$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength = 64MB

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:34999/")
$listener.Start()
$written = 0
Write-Output "listening on http://localhost:34999/ - writing under $rootFull"

function Reply($ctx, [int]$code, [string]$text) {
    $bytes = $utf8.GetBytes($text)
    $ctx.Response.StatusCode = $code
    $ctx.Response.ContentType = "text/plain"
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
        $path = $ctx.Request.Url.AbsolutePath
        if ($path -eq "/ping") { Reply $ctx 200 "pong"; continue }
        if ($path -eq "/done") { Reply $ctx 200 "done $written"; break }
        if ($path -ne "/files") { Reply $ctx 404 "unknown"; continue }
        $reader = New-Object System.IO.StreamReader($ctx.Request.InputStream, $utf8)
        $files = $json.DeserializeObject($reader.ReadToEnd())
        $count = 0
        foreach ($f in $files) {
            $rel = [string]$f["path"]
            if ([string]::IsNullOrWhiteSpace($rel) -or $rel.Contains("..") -or [System.IO.Path]::IsPathRooted($rel)) { continue }
            $full = [System.IO.Path]::GetFullPath((Join-Path $rootFull ($rel -replace '/', '\')))
            if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
            New-Item -ItemType Directory -Force -Path (Split-Path $full) | Out-Null
            [System.IO.File]::WriteAllText($full, [string]$f["content"], $utf8)
            $count++
        }
        $written += $count
        Write-Output "batch: $count files ($written total)"
        Reply $ctx 200 "ok $count"
    } catch {
        Reply $ctx 500 $_.Exception.Message
    }
}
$listener.Stop()
Write-Output "stopped after writing $written files"
