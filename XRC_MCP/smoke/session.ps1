<#
    session.ps1 - end-to-end smoke session for XRC_MCP.exe.

    Drives one live JSON-RPC-over-stdio session against _Out\BIN\XRC_MCP.exe in a
    throwaway work directory and calls every one of the 16 tools at least once.
    Long-running tools are driven the way a client drives them: submit, poll
    job_status until the state is terminal, then job_result; one job is submitted
    only to be stopped with cancel_job.

    Checks (the first failure exits non-zero with a message):
      * tools/list names exactly the 16 expected tools
      * calc_reflectivity puts the first Ru/C Bragg peak at 0.687 deg +/- 0.01
        (refraction-corrected; the Bragg-law estimate 0.644 deg is not what the
        engine gives)
      * optimize_mirror twice with the same seed -> identical figure of merit
      * fit_xrr twice with the same seed -> identical chi-squared and structure
      * load_project with "..\..\x.xrcx" -> error code path_outside_workdir
      * the inbox is byte-for-byte unchanged (SHA-256 before and after)
      * log\calls.jsonl holds exactly one "tool" line per tools/call request sent

    The inbox is built BEFORE the server starts, from a curve produced by a
    separate preparation run of the same exe in its own work directory, so the
    session's journal counts only the session's own calls.

    Usage:  pwsh -File XRC_MCP\smoke\session.ps1 [-Exe <path>] [-KeepWorkdir]
    Exit code 0 = every check passed.
#>

[CmdletBinding()]
param(
    [string] $Exe,
    [switch] $KeepWorkdir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------- infrastructure

$script:Proc      = $null
$script:NextId    = 100
$script:CallCount = 0          # tools/call requests sent - the journal must match

function Say([string] $Text) { Write-Host $Text }

function Fail([string] $Text) {
    Write-Host ''
    Write-Host "FAIL: $Text" -ForegroundColor Red
    Stop-Server
    exit 1
}

function Stop-Server {
    if ($null -eq $script:Proc) { return }
    try {
        if (-not $script:Proc.HasExited) {
            $script:Proc.StandardInput.Close()
            if (-not $script:Proc.WaitForExit(15000)) { $script:Proc.Kill() }
        }
    } catch { }
    $script:Proc = $null
}

function Start-Server([string] $ExePath, [string] $WorkDir) {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName               = $ExePath
    $psi.Arguments              = '--workdir "' + $WorkDir + '"'
    $psi.UseShellExecute         = $false
    $psi.RedirectStandardInput   = $true
    $psi.RedirectStandardOutput  = $true
    # stderr is deliberately NOT redirected: it carries the server's diagnostics
    # straight to this console and cannot fill a pipe nobody is draining.
    $psi.StandardInputEncoding  = [System.Text.UTF8Encoding]::new($false)
    $psi.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $script:Proc = [System.Diagnostics.Process]::Start($psi)
}

function Read-Line([int] $TimeoutSec = 300) {
    $task = $script:Proc.StandardOutput.ReadLineAsync()
    if (-not $task.Wait($TimeoutSec * 1000)) { Fail "no response within $TimeoutSec s" }
    $line = $task.Result
    if ($null -eq $line) { Fail 'the server closed stdout (it died?)' }
    return $line
}

function Send-Rpc([string] $Method, $Params, [switch] $Notification, [int] $TimeoutSec = 300) {
    $req = [ordered]@{ jsonrpc = '2.0' }
    if (-not $Notification) {
        $script:NextId++
        $req['id'] = $script:NextId
    }
    $req['method'] = $Method
    if ($null -ne $Params) { $req['params'] = $Params }

    $json = $req | ConvertTo-Json -Depth 30 -Compress
    $script:Proc.StandardInput.WriteLine($json)
    $script:Proc.StandardInput.Flush()
    if ($Notification) { return $null }

    $resp = Read-Line -TimeoutSec $TimeoutSec | ConvertFrom-Json
    if ($resp.id -ne $req['id']) { Fail "response id $($resp.id) does not match request id $($req['id'])" }
    return $resp
}

# Calls one tool and returns the parsed payload object. -ExpectError demands an
# isError result and returns the error object instead.
function Invoke-Tool([string] $Name, $Arguments, [switch] $ExpectError, [int] $TimeoutSec = 300) {
    if ($null -eq $Arguments) { $Arguments = @{} }
    $script:CallCount++
    $resp = Send-Rpc 'tools/call' @{ name = $Name; arguments = $Arguments } -TimeoutSec $TimeoutSec

    if ($null -ne $resp.PSObject.Properties['error']) {
        Fail "$Name returned a JSON-RPC error: $($resp.error | ConvertTo-Json -Depth 6 -Compress)"
    }
    $text    = $resp.result.content[0].text
    $payload = $text | ConvertFrom-Json
    $isError = ($null -ne $resp.result.PSObject.Properties['isError']) -and $resp.result.isError

    if ($ExpectError) {
        if (-not $isError) { Fail "$Name was expected to fail but returned: $text" }
        return $payload
    }
    if ($isError) { Fail "$Name failed: $text" }
    return $payload
}

function Wait-JobDone([string] $JobId, [int] $TimeoutSec = 300) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        $st = Invoke-Tool 'job_status' @{ job_id = $JobId }
        if ($st.state -in @('finished', 'failed', 'cancelled', 'unknown')) { return $st }
        if ($sw.Elapsed.TotalSeconds -gt $TimeoutSec) {
            Fail "job $JobId still '$($st.state)' after $TimeoutSec s (iteration $($st.iteration)/$($st.max_iterations))"
        }
        Start-Sleep -Milliseconds 400
    }
}

# ---------------------------------------------------------------- the test model

# The Ru/C multilayer the plan uses throughout: d = 68.5 A, gamma = 0.215,
# N = 30, Ru buffer, SiO2 substrate.
function New-Ruc([double] $DRu = 14.7, [double] $DC = 53.8) {
    return [ordered]@{
        substrate = [ordered]@{ material = 'SiO2'; density = 2.2; sigma = 3.0 }
        stacks    = @(
            [ordered]@{
                N      = 30
                layers = @(
                    [ordered]@{ material = 'Ru'; thickness = $DRu; sigma = 3.0; density = 12.4 },
                    [ordered]@{ material = 'C';  thickness = $DC;  sigma = 3.0; density = 2.2  }
                )
            }
        )
        cap    = [ordered]@{ material = 'Ru'; thickness = 20.0;  sigma = 3.0; density = 12.4 }
        buffer = [ordered]@{ material = 'Ru'; thickness = 197.0; sigma = 3.0; density = 12.4 }
    }
}

$OPT_CONFIG = [ordered]@{
    lines        = @('Al', 'Si')
    element_pool = @('W', 'Si', 'B4C', 'Sc', 'C', 'Mo')
    substrate    = 'Si'
    structure    = [ordered]@{
        d     = [ordered]@{ min = 30; max = 80 }
        gamma = [ordered]@{ min = 0.15; max = 0.70 }
        N     = [ordered]@{ min = 40; max = 200 }
        sigma = 3
    }
    fitness   = [ordered]@{ scan_points = 60 }
    optimizer = [ordered]@{ population = 20; iterations = 3 }
}

$EXPECTED_TOOLS = @(
    'describe_server', 'list_materials', 'optical_constants', 'list_templates',
    'calc_reflectivity', 'evaluate_lines', 'optimize_mirror', 'job_status',
    'job_result', 'cancel_job', 'fit_xrr', 'list_measurements', 'get_measurement',
    'save_project', 'load_project', 'list_projects'
)

# ---------------------------------------------------------------- 0. locate the exe

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $Exe) { $Exe = Join-Path $repoRoot '_Out\BIN\XRC_MCP.exe' }
if (-not (Test-Path -LiteralPath $Exe)) { Fail "server executable not found: $Exe" }

$stamp   = 'xrcmcp_session_{0}' -f $PID
$work    = Join-Path $env:TEMP $stamp
$prep    = Join-Path $env:TEMP ($stamp + '_prep')
foreach ($d in @($work, $prep)) {
    if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force }
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

Say "XRC_MCP end-to-end session"
Say "  exe     : $Exe"
Say "  workdir : $work"
Say ''

# ------------------------------------------- 1. build the inbox BEFORE the server

# A separate one-shot run of the same exe, in its own work directory, produces a
# calculated Ru/C curve; that curve becomes the measured file in the session's
# read-only inbox.
Say '[prep] generating the measured curve'
$prepReq = @(
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}',
    (@{ jsonrpc = '2.0'; id = 2; method = 'tools/call'; params = @{
        name = 'calc_reflectivity'
        arguments = [ordered]@{
            structure   = (New-Ruc)
            lambda      = 1.5406
            theta_min   = 0.1
            theta_max   = 4.0
            points      = 400
            delta_theta = 0.015
            max_inline_points = 0
        } } } | ConvertTo-Json -Depth 30 -Compress)
) -join "`n"

$prepOut = $prepReq | & $Exe --workdir $prep 2>$null
if ($LASTEXITCODE -ne 0) { Fail "the preparation run exited with $LASTEXITCODE" }
$prepResp = ($prepOut | Select-Object -Last 1) | ConvertFrom-Json
$prepPayload = $prepResp.result.content[0].text | ConvertFrom-Json
$prepCurve = Join-Path $prep $prepPayload.file
if (-not (Test-Path -LiteralPath $prepCurve)) { Fail "the preparation run wrote no curve at $prepCurve" }

$inboxDir = Join-Path $work 'inbox\S1'
New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
$xrrPath  = Join-Path $inboxDir 'xrr.dat'
$metaPath = Join-Path $inboxDir 'meta.json'
Copy-Item -LiteralPath $prepCurve -Destination $xrrPath
[System.IO.File]::WriteAllText($metaPath,
    '{"lambda":1.5406,"date":"2026-09-09","instrument":"test","theta_unit":"theta"}',
    [System.Text.UTF8Encoding]::new($false))

$inboxBefore = Get-ChildItem -LiteralPath $inboxDir -File |
    Sort-Object Name |
    ForEach-Object { '{0}={1}' -f $_.Name, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
Say "[prep] inbox\S1 prepared:"
$inboxBefore | ForEach-Object { Say "         $_" }
Say ''

# ---------------------------------------------------------------- 2. the session

Start-Server $Exe $work

$init = Send-Rpc 'initialize' @{}
if ($init.result.serverInfo.name -ne 'xraca') { Fail "serverInfo.name is '$($init.result.serverInfo.name)', expected 'xraca'" }
Send-Rpc 'notifications/initialized' $null -Notification | Out-Null

$list  = Send-Rpc 'tools/list' $null
$names = @($list.result.tools | ForEach-Object { $_.name })
if ($names.Count -ne $EXPECTED_TOOLS.Count) { Fail "tools/list returned $($names.Count) tools, expected $($EXPECTED_TOOLS.Count)" }
$missing = @($EXPECTED_TOOLS | Where-Object { $_ -notin $names })
$extra   = @($names | Where-Object { $_ -notin $EXPECTED_TOOLS })
if ($missing.Count -or $extra.Count) { Fail "tools/list mismatch. missing: $($missing -join ',') extra: $($extra -join ',')" }
Say "[1/16] tools/list  : $($names.Count) tools, all expected names present"

# --- the four reference tools ------------------------------------------------
$desc = Invoke-Tool 'describe_server' @{}
Say "[2/16] describe_server   : version $($desc.server.version), git $($desc.server.git_revision), engine $($desc.server.xraycalc3_exe_version)"

$mats = Invoke-Tool 'list_materials' @{ filter = @('Ru', 'C') }
if ($mats.count -lt 1) { Fail 'list_materials returned nothing for the Ru/C filter' }
Say "[3/16] list_materials    : $($mats.count) tables for [Ru,C]"

$oc = Invoke-Tool 'optical_constants' @{ material = 'Ru'; lambda = 1.5406 }
if ($oc.delta -le 0) { Fail "optical_constants gave delta = $($oc.delta) for Ru, expected a positive number" }
Say "[4/16] optical_constants : Ru delta=$($oc.delta) beta=$($oc.beta) rho=$($oc.density_used)"

$tpl = Invoke-Tool 'list_templates' @{}
Say "[5/16] list_templates    : $(@($tpl.templates).Count) templates"

# --- calc_reflectivity: the Bragg-peak check ---------------------------------
$calc = Invoke-Tool 'calc_reflectivity' ([ordered]@{
    structure = (New-Ruc); lambda = 1.5406; theta_min = 0.1; theta_max = 4.0
    points = 2000; max_inline_points = 0 })
if ($calc.bragg_peaks.Count -lt 1) { Fail 'calc_reflectivity found no Bragg peaks in the Ru/C curve' }
$peak1 = $calc.bragg_peaks[0].theta_deg
if ([Math]::Abs($peak1 - 0.687) -gt 0.01) {
    Fail "the first Ru/C Bragg peak is at $peak1 deg, expected 0.687 +/- 0.01"
}
Say "[6/16] calc_reflectivity : first Bragg peak $peak1 deg (R=$($calc.bragg_peaks[0].r_peak)), theta_c=$($calc.critical_angle_deg), $($calc.points) points"

# --- evaluate_lines ----------------------------------------------------------
$ev = Invoke-Tool 'evaluate_lines' ([ordered]@{
    structure = (New-Ruc)
    lines     = @([ordered]@{ name = 'B'; lambda = 67.6 }, [ordered]@{ name = 'Si'; lambda = 7.126 })
    fitness   = [ordered]@{ scan_points = 120 } })
if ([double]::IsNaN([double]$ev.fom)) { Fail 'evaluate_lines returned a NaN figure of merit' }
Say "[7/16] evaluate_lines    : fom=$($ev.fom), Si theta_bragg=$($ev.lines[1].theta_bragg_deg) deg"

# --- optimize_mirror twice with the same seed --------------------------------
$optFoms = @()
foreach ($run in 1, 2) {
    $sub = Invoke-Tool 'optimize_mirror' ([ordered]@{ config = $OPT_CONFIG; seed = 12345; top_k = 2 })
    $st = Wait-JobDone $sub.job_id 300
    if ($st.state -ne 'finished') { Fail "optimize_mirror run $run ended '$($st.state)': $($st.last_message)" }
    $res = Invoke-Tool 'job_result' @{ job_id = $sub.job_id }
    $optFoms += [double] $res.best.fom
    Say "[8/16] optimize_mirror r$run : $($sub.job_id) fom=$($res.best.fom) d=$($res.best.genome.d) gamma=$($res.best.genome.gamma) N=$($res.best.genome.N) iter=$($st.iteration)"
}
if ($optFoms[0] -ne $optFoms[1]) {
    Fail "optimize_mirror is not deterministic: seed 12345 gave $($optFoms[0]) and $($optFoms[1])"
}
Say "[9/16] job_status/job_result: both optimize runs report fom = $($optFoms[0]) (identical)"

# --- cancel_job on a job submitted only to be stopped ------------------------
$bigConfig = [ordered]@{
    lines        = $OPT_CONFIG['lines']
    element_pool = $OPT_CONFIG['element_pool']
    substrate    = $OPT_CONFIG['substrate']
    structure    = $OPT_CONFIG['structure']
    fitness      = [ordered]@{ scan_points = 100 }
    optimizer    = [ordered]@{ population = 60; iterations = 500 }
}
$big = Invoke-Tool 'optimize_mirror' ([ordered]@{ config = $bigConfig; seed = 999; top_k = 1 })
Start-Sleep -Milliseconds 600
$cancel = Invoke-Tool 'cancel_job' @{ job_id = $big.job_id }
$st = Wait-JobDone $big.job_id 120
if ($st.state -ne 'cancelled') { Fail "the cancelled job ended '$($st.state)', expected 'cancelled'" }
Say "[10/16] cancel_job       : $($big.job_id) cancel returned '$($cancel.state)', job settled 'cancelled' at iteration $($st.iteration)"

# --- fit_xrr twice with the same seed ----------------------------------------
$fitArgs = [ordered]@{
    structure      = (New-Ruc 13.5 55.0)
    measurement_id = 'S1/xrr.dat'
    resolution     = 0.015
    free           = @(
        [ordered]@{ target = 'layer'; stack = 0; layer = 0; parameters = @('thickness') },
        [ordered]@{ target = 'layer'; stack = 0; layer = 1; parameters = @('thickness') }
    )
    # tolerance below anything this fit can reach, so the run uses its whole
    # budget: an early stop at iteration 1 would make the determinism check
    # trivially true.
    optimizer         = [ordered]@{ population = 20; iterations = 5; tolerance = 1e-9 }
    seed              = 7
    points_inline_max = 0
}
$fitChi = @()
$fitStruct = @()
foreach ($run in 1, 2) {
    $sub = Invoke-Tool 'fit_xrr' $fitArgs
    $st  = Wait-JobDone $sub.job_id 600
    if ($st.state -ne 'finished') { Fail "fit_xrr run $run ended '$($st.state)': $($st.last_message)" }
    $res = Invoke-Tool 'job_result' @{ job_id = $sub.job_id }
    $fitChi    += [double] $res.chi2
    $fitStruct += ($res.fitted_structure | ConvertTo-Json -Depth 20 -Compress)
    Say "[11/16] fit_xrr r$run     : $($sub.job_id) chi2=$($res.chi2) (start $($res.chi2_start)) iter=$($res.iterations_run) xrcx=$($res.files.xrcx)"
}
if ($fitChi[0] -ne $fitChi[1]) { Fail "fit_xrr is not deterministic: seed 7 gave chi2 $($fitChi[0]) and $($fitChi[1])" }
if ($fitStruct[0] -ne $fitStruct[1]) { Fail 'fit_xrr with seed 7 produced two different fitted structures' }
Say "[12/16] fit determinism  : both runs report chi2 = $($fitChi[0]) and the same fitted structure"

# --- the inbox tools ---------------------------------------------------------
$meas = Invoke-Tool 'list_measurements' @{}
$specimens = @($meas.specimens)
if ($specimens.Count -lt 1) { Fail 'list_measurements found no specimen in the inbox' }
$firstFile = @($specimens[0].files)[0]
if ($firstFile.id -ne 'S1/xrr.dat') { Fail "list_measurements reported '$($firstFile.id)', expected 'S1/xrr.dat'" }
Say "[13/16] list_measurements: $($specimens.Count) specimen(s), first file '$($firstFile.id)' sha $($firstFile.sha256.Substring(0,12))..."

$one = Invoke-Tool 'get_measurement' @{ measurement_id = 'S1/xrr.dat'; max_points = 100 }
if ($one.points_returned -gt 100) { Fail "get_measurement returned $($one.points_returned) points for max_points 100" }
Say "[14/16] get_measurement  : $($one.points) points in the file, $($one.points_returned) returned, lambda $($one.lambda), theta_unit $($one.theta_unit)"

# --- the project tools -------------------------------------------------------
$save = Invoke-Tool 'save_project' ([ordered]@{
    structure = (New-Ruc); name = 'smoke'; overwrite = $true
    lambda = 1.5406; theta_min = 0.1; theta_max = 4.0; points = 400
    note = 'written by XRC_MCP\smoke\session.ps1' })
Say "[15/16] save_project     : $($save.file) ($($save.size) bytes, project version $($save.version))"

$load = Invoke-Tool 'load_project' @{ name = 'smoke' }
if ($load.structure.stacks[0].N -ne 30) { Fail "load_project returned N = $($load.structure.stacks[0].N), expected 30" }
Say "[16/16] load_project     : $($load.structure.stacks[0].N) periods, $($load.structure.stacks[0].layers.Count) layers per period"

# The sandbox check: a path that climbs out of the work directory.
$bad = Invoke-Tool 'load_project' @{ path = '..\..\x.xrcx' } -ExpectError
if ($bad.code -ne 'path_outside_workdir') {
    Fail "load_project '..\..\x.xrcx' returned code '$($bad.code)', expected 'path_outside_workdir'"
}
Say "        sandbox         : load_project '..\..\x.xrcx' -> $($bad.code)"

$projects = Invoke-Tool 'list_projects' @{}
$projList = @($projects.projects)
if ($projList.Count -lt 1) { Fail 'list_projects found no project after save_project' }
Say "        list_projects   : $($projList.Count) project(s), first '$($projList[0].name)'"

Stop-Server

# ---------------------------------------------------------------- 3. after checks

Say ''
Say '--- post-session checks ---'

# The inbox is the one folder the server must never write to.
$inboxAfter = Get-ChildItem -LiteralPath $inboxDir -File |
    Sort-Object Name |
    ForEach-Object { '{0}={1}' -f $_.Name, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
if (($inboxBefore -join '|') -ne ($inboxAfter -join '|')) {
    Fail "the inbox changed during the session.`n  before: $($inboxBefore -join '; ')`n  after : $($inboxAfter -join '; ')"
}
Say "inbox SHA-256 unchanged ($($inboxAfter.Count) files):"
$inboxAfter | ForEach-Object { Say "  $_" }

# One journal line per tools/call. Job lifecycle events share the file but carry
# an "event" key instead of a "tool" key, so they are counted separately.
$journalPath = Join-Path $work 'log\calls.jsonl'
if (-not (Test-Path -LiteralPath $journalPath)) { Fail "no journal at $journalPath" }
$lines     = @(Get-Content -LiteralPath $journalPath | Where-Object { $_.Trim() -ne '' })
$entries   = @($lines | ForEach-Object { $_ | ConvertFrom-Json })
$toolLines = @($entries | Where-Object { $null -ne $_.PSObject.Properties['tool'] })
$evtLines  = @($entries | Where-Object { $null -ne $_.PSObject.Properties['event'] })
if ($toolLines.Count -ne $script:CallCount) {
    Fail "the journal holds $($toolLines.Count) tool lines but $($script:CallCount) tools/call requests were sent"
}
Say "journal: $($toolLines.Count) tool lines == $($script:CallCount) tools/call requests sent (+ $($evtLines.Count) job event lines, $($lines.Count) lines total)"

$distinct = @($toolLines | ForEach-Object { $_.tool } | Sort-Object -Unique)
$notCalled = @($EXPECTED_TOOLS | Where-Object { $_ -notin $distinct })
if ($notCalled.Count) { Fail "these tools were never called: $($notCalled -join ', ')" }
Say "journal: all 16 tools appear ($($distinct.Count) distinct names)"

if (-not $KeepWorkdir) {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $prep -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Say "work directories kept: $work  /  $prep"
}

Say ''
Say 'PASS - every check succeeded.'
exit 0
