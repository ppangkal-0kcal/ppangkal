<#
  실기기(Android) 테스트 실행 도우미 — DEVICE_TESTING.md 참고.

  사용:
    .\tool\run_on_device.ps1              # USB 연결: adb reverse 후 localhost로 백엔드 접속
    .\tool\run_on_device.ps1 -Wifi        # 같은 Wi-Fi: PC의 LAN IP로 백엔드 접속
    .\tool\run_on_device.ps1 -Release     # 릴리스 모드(성능 확인용)로 실행

  dart_defines.json(없으면 dart_defines.example.json 복사)의 NAVER_MAP_CLIENT_ID를 사용한다.
#>
param(
  [switch]$Wifi,
  [switch]$Release
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }

$devices = & $adb devices | Select-String -Pattern '\tdevice$'
if (-not $devices) {
  Write-Error '연결된 Android 기기가 없습니다. USB 디버깅을 켜고 "이 컴퓨터 허용"을 눌렀는지 확인하세요.'
}

$definesPath = Join-Path $root 'dart_defines.json'
if (-not (Test-Path $definesPath)) {
  Copy-Item (Join-Path $root 'dart_defines.example.json') $definesPath
  Write-Host 'dart_defines.json을 만들었습니다. 네이버 지도 키가 있으면 NAVER_MAP_CLIENT_ID를 채우세요.'
}
$defines = Get-Content $definesPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($Wifi) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.*' } | Select-Object -First 1).IPAddress
  if (-not $ip) { Write-Error 'Wi-Fi IPv4 주소를 찾지 못했습니다. -Wifi 없이 USB 방식으로 실행하세요.' }
  $apiBaseUrl = "http://${ip}:4000/api"
  Write-Host "Wi-Fi 모드: $apiBaseUrl (Windows 방화벽에서 TCP 4000 인바운드 허용 필요)"
} else {
  & $adb reverse tcp:4000 tcp:4000 | Out-Null
  $apiBaseUrl = 'http://localhost:4000/api'
  Write-Host 'USB 모드: adb reverse tcp:4000 설정 완료 (USB 재연결 시 다시 실행)'
}

try {
  Invoke-RestMethod ($apiBaseUrl -replace '/api$', '/health') -TimeoutSec 5 | Out-Null
} catch {
  Write-Warning "PC에서 백엔드에 접속되지 않습니다. backend 폴더에서 'npm run dev'를 먼저 실행하세요."
}

$flutterArgs = @('run', "--dart-define=API_BASE_URL=$apiBaseUrl", "--dart-define=NAVER_MAP_CLIENT_ID=$($defines.NAVER_MAP_CLIENT_ID)")
if ($Release) { $flutterArgs += '--release' }
flutter @flutterArgs
