<#
  원스토어/구글 플레이 업로드용 빌드 — RELEASE.md 참고.

  사용:
    .\tool\build_store_release.ps1            # AAB(권장) + APK 둘 다
    .\tool\build_store_release.ps1 -AabOnly
    .\tool\build_store_release.ps1 -ApkOnly

  업로드하면 안 되는 결과물을 만들지 않도록 먼저 검사한다:
    - android\key.properties(출시 키)가 없으면 중단 (디버그 키 서명 방지)
    - dart_defines.json의 API_BASE_URL이 localhost/사설 IP면 중단
    - 빌드 후 서명 인증서가 'Android Debug'면 중단
#>
param(
  [switch]$AabOnly,
  [switch]$ApkOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path 'android\key.properties')) {
  Write-Error '출시 키가 없습니다. 먼저 .\tool\create_release_key.ps1 을 실행하세요 (RELEASE.md).'
}

$definesPath = 'dart_defines.json'
if (-not (Test-Path $definesPath)) { Write-Error 'dart_defines.json이 없습니다 (dart_defines.example.json 참고).' }
$defines = Get-Content $definesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$api = [string]$defines.API_BASE_URL
if (-not $api -or $api -match '//(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)' -or $api -notmatch '^https://') {
  Write-Error "API_BASE_URL이 출시용 주소가 아닙니다: '$api' (https 배포 주소여야 함)"
}
if (-not $defines.NAVER_MAP_CLIENT_ID) {
  Write-Warning 'NAVER_MAP_CLIENT_ID가 비어 있습니다 — 지도 화면은 네이버 지도 앱 호출 목록으로 대체됩니다.'
}

$version = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
Write-Host "빌드 버전: $version / API: $api"

$keytool = @(
  'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
  $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' })
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $keytool) { $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source }

$buildTools = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools') -Directory -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending | Select-Object -First 1
$apksigner = if ($buildTools) { Join-Path $buildTools.FullName 'apksigner.bat' } else { $null }

function Assert-ReleaseSigned([string]$artifact) {
  # cmd 경유: 한국어 로캘 출력과 stderr 경고가 PowerShell 5.1 파이프라인에서 깨지거나 오류로 바뀌는 것을 피한다.
  if ($artifact -like '*.apk') {
    # minSdk 24+ APK는 v2/v3 서명만 있어 keytool로는 못 읽는다
    if (-not ($apksigner -and (Test-Path $apksigner))) { Write-Warning "apksigner가 없어 서명 검사를 건너뜁니다: $artifact"; return }
    $out = cmd /c "`"$apksigner`" verify --print-certs `"$artifact`" 2>&1"
    $owner = ($out | Select-String -Pattern 'certificate DN:' | Select-Object -First 1).Line
  } else {
    if (-not $keytool) { Write-Warning "keytool이 없어 서명 검사를 건너뜁니다: $artifact"; return }
    $out = cmd /c "`"$keytool`" -J-Duser.language=en -printcert -jarfile `"$artifact`" 2>&1"
    $owner = ($out | Select-String -Pattern '^Owner:' | Select-Object -First 1).Line
  }
  if (-not $owner) { Write-Error "서명 정보를 읽지 못했습니다: $artifact" }
  if ($owner -match 'Android Debug') { Write-Error "디버그 키로 서명됐습니다 — 업로드 금지: $artifact" }
  Write-Host "  서명 확인: $($owner.Trim())"
}

# flutter/gradle은 경고를 stderr로 출력한다 — Stop 상태면 PowerShell 5.1이 이를 오류로 보고
# 빌드를 끊으므로, 네이티브 명령 구간은 Continue로 두고 종료 코드로만 성공 여부를 판단한다.
function Invoke-Flutter([string[]]$flutterArgs) {
  $ErrorActionPreference = 'Continue'
  & flutter @flutterArgs 2>&1 | ForEach-Object { "$_" } | Out-Host
  return $LASTEXITCODE
}

$outputs = @()
if (-not $ApkOnly) {
  $code = Invoke-Flutter @('build', 'appbundle', '--release', "--dart-define-from-file=$definesPath")
  if ($code -ne 0) { Write-Error 'AAB 빌드 실패' }
  $aab = 'build\app\outputs\bundle\release\app-release.aab'
  Assert-ReleaseSigned $aab
  $outputs += $aab
}
if (-not $AabOnly) {
  $code = Invoke-Flutter @('build', 'apk', '--release', "--dart-define-from-file=$definesPath")
  if ($code -ne 0) { Write-Error 'APK 빌드 실패' }
  $apk = 'build\app\outputs\flutter-apk\app-release.apk'
  Assert-ReleaseSigned $apk
  $outputs += $apk
}

Write-Host ''
Write-Host "업로드용 결과물 (버전 $version):"
$outputs | ForEach-Object { Write-Host ("  {0}  ({1:N1}MB)" -f $_, ((Get-Item $_).Length / 1MB)) }
Write-Host '다음 업데이트 때는 pubspec.yaml의 version 뒤 +숫자(빌드 번호)를 반드시 올리세요.'
