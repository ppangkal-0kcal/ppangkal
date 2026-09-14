<#
  빵칼 출시용 업로드 키 생성 — 한 번만 실행한다. RELEASE.md 참고.

  - 키스토어는 저장소 밖(기본: %USERPROFILE%\.ppangkal-release\)에 만든다.
    git clean이나 폴더 삭제로 사라지지 않게 하기 위해서다.
  - 비밀번호는 무작위로 만들어 android/key.properties(git 제외)와 같은 폴더의 백업 파일에만 저장하고
    화면에 출력하지 않는다.
  - 이 키를 잃어버리면 스토어에 같은 앱으로 업데이트를 올릴 수 없다. 만든 직후 폴더 전체를
    비밀번호 관리자/개인 클라우드 등 안전한 곳에 백업할 것.

  사용: .\tool\create_release_key.ps1 [-KeyDir <폴더>]
#>
param(
  [string]$KeyDir = (Join-Path $env:USERPROFILE '.ppangkal-release')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$keyProperties = Join-Path $root 'android\key.properties'
$keystore = Join-Path $KeyDir 'ppangkal-upload.jks'
$alias = 'upload'

if ((Test-Path $keystore) -or (Test-Path $keyProperties)) {
  Write-Error "이미 키가 있습니다 ($keystore 또는 android\key.properties). 덮어쓰면 기존 키로 서명된 앱을 업데이트할 수 없게 되므로 중단합니다."
}

$keytool = @(
  'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
  $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' })
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $keytool) { $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source }
if (-not $keytool) { Write-Error 'keytool을 찾지 못했습니다. Android Studio(JBR) 또는 JDK를 설치하세요.' }

# 영숫자만 사용 — properties 파일/keytool 인자에서 이스케이프 문제를 피한다
$alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$sb = New-Object System.Text.StringBuilder
foreach ($b in $bytes) { [void]$sb.Append($alphabet[[int]$b % $alphabet.Length]) }
$password = $sb.ToString()
if ($password.Length -ne 32) { Write-Error '비밀번호 생성 실패' }

New-Item -ItemType Directory -Force -Path $KeyDir | Out-Null

# keytool은 진행 메시지를 stderr로 쓴다 — PowerShell 5.1이 이를 오류로 보고 중단하지 않도록
# 이 구간만 Continue로 두고 성공 여부는 종료 코드와 파일 존재로 판단한다.
$ErrorActionPreference = 'Continue'
& $keytool -genkeypair -keystore $keystore -storetype PKCS12 -alias $alias `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass $password -keypass $password `
  -dname 'CN=Ppangkal, OU=Mobile, O=Ppangkal, L=Daejeon, C=KR' 2>$null | Out-Null
$keytoolExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($keytoolExit -ne 0 -or -not (Test-Path $keystore)) { Write-Error "keytool 키 생성 실패 (exit $keytoolExit)" }

$utf8 = New-Object System.Text.UTF8Encoding $false
$storeFile = $keystore -replace '\\', '/'
$props = "storeFile=$storeFile`nstorePassword=$password`nkeyAlias=$alias`nkeyPassword=$password`n"
[IO.File]::WriteAllText($keyProperties, $props, $utf8)
# 키스토어와 같은 폴더에 백업 사본 (폴더째 백업하면 복구에 필요한 것이 모두 들어간다)
[IO.File]::WriteAllText((Join-Path $KeyDir 'key.properties.backup'), $props, $utf8)

$ErrorActionPreference = 'Continue'
$fingerprint = (& $keytool -list -v -keystore $keystore -alias $alias -storepass $password 2>$null |
  Select-String 'SHA256:' | Select-Object -First 1).Line
$ErrorActionPreference = 'Stop'
if ($fingerprint) { $fingerprint = $fingerprint.Trim() }

Write-Host ''
Write-Host '출시용 업로드 키를 만들었습니다.'
Write-Host "  키스토어: $keystore"
Write-Host "  설정:     android\key.properties (git 제외)"
Write-Host "  $fingerprint"
Write-Host ''
Write-Host "지금 바로 '$KeyDir' 폴더 전체를 안전한 곳에 백업하세요. 잃어버리면 앱 업데이트가 불가능합니다."
