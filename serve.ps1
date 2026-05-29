$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8080
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "Servidor rodando em http://localhost:$port" -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para parar." -ForegroundColor Gray

$mimeTypes = @{
  '.html' = 'text/html; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.js'   = 'application/javascript; charset=utf-8'
  '.svg'  = 'image/svg+xml'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.ico'  = 'image/x-icon'
  '.woff2'= 'font/woff2'
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response

  $urlPath = $req.Url.LocalPath
  if ($urlPath -eq '/') { $urlPath = '/index.html' }

  $filePath = Join-Path $root ($urlPath.TrimStart('/').Replace('/', '\'))

  if (Test-Path $filePath -PathType Leaf) {
    $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
    $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { 'application/octet-stream' }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $res.ContentType   = $mime
    $res.ContentLength64 = $bytes.Length
    $res.StatusCode    = 200
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $res.StatusCode = 404
    $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
    $res.OutputStream.Write($msg, 0, $msg.Length)
  }
  $res.OutputStream.Close()
}
