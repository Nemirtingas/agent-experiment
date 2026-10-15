<#
.SYNOPSIS
Install the agent workflow skills and commands from PowerShell (Windows PowerShell 5.1 or PowerShell 7).

.DESCRIPTION
  install.ps1 install   [-Copy] [-Project DIR] [-NoBin] [-AddToPath] [TARGET...]
  install.ps1 uninstall [-Project DIR] [TARGET...]
  install.ps1 project   DIR [-Base BRANCH]
  install.ps1 list

TARGET (default: agents claude)
  agents     ~\.agents\skills           Codex, OpenCode
  claude     ~\.claude\skills           Claude Code, OpenCode
  opencode   ~\.config\opencode\skills  OpenCode
  <dir>      any directory that an agent scans for <name>\SKILL.md
With -Project DIR the targets become DIR\.agents\skills, DIR\.claude\skills and DIR\.opencode\skills.

install links each skill as a symbolic link, as a directory junction when this session may not create
symbolic links, or copies it with -Copy. It also installs the commands plan-lifecycle and resource-lock
into ~\.local\bin (WORKFLOW_BIN overrides): on Windows a .cmd shim for PowerShell and cmd plus an
extensionless wrapper for Git Bash, both running the POSIX scripts with the sh.exe of Git for Windows;
elsewhere a symbolic link. -AddToPath appends that directory to the user PATH on Windows.
uninstall removes what install created and nothing else. project copies the AGENTS.md template into a
repository, creates its plan directory and records the base branch.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'uninstall', 'project', 'list', 'help')]
    [string]$Command = 'help',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),

    [switch]$Copy,
    [string]$Project,
    [switch]$NoBin,
    [switch]$AddToPath,
    [string]$Base
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

$Here = $PSScriptRoot
$OnWindows = ($PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows
$UserHome = [Environment]::GetFolderPath('UserProfile')
if (-not $UserHome) { $UserHome = $env:HOME }
if ($env:WORKFLOW_BIN) { $Bin = $env:WORKFLOW_BIN } else { $Bin = Join-Path (Join-Path $UserHome '.local') 'bin' }
$KitSkills = Join-Path $Here 'skills'
$CommandScripts = @{
    'plan-lifecycle' = Join-Path (Join-Path (Join-Path $KitSkills 'plan-lifecycle') 'scripts') 'plan.sh'
    'resource-lock'  = Join-Path (Join-Path (Join-Path $KitSkills 'resource-lock') 'scripts') 'lock.sh'
}
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail([string]$Message) {
    [Console]::Error.WriteLine("install.ps1: $Message")
    exit 1
}

function Invoke-Git([string[]]$GitArgs) {
    # Runs git without turning its stderr into a terminating error; the caller checks $LASTEXITCODE.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git @GitArgs 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
        return @($output)
    } finally {
        $ErrorActionPreference = $previous
    }
}

function Get-SkillDirs {
    Get-ChildItem -LiteralPath $KitSkills -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }
}

function Resolve-Target([string]$Target, [string]$ProjectDir) {
    if ($ProjectDir) { $root = $ProjectDir } else { $root = $UserHome }
    switch ($Target) {
        'agents' { return Join-Path (Join-Path $root '.agents') 'skills' }
        'claude' { return Join-Path (Join-Path $root '.claude') 'skills' }
        'opencode' {
            if ($ProjectDir) { return Join-Path (Join-Path $root '.opencode') 'skills' }
            return Join-Path (Join-Path (Join-Path $root '.config') 'opencode') 'skills'
        }
        default { return $Target }
    }
}

function Get-Existing([string]$Path) {
    # Returns the item, including a dangling link, or $null.
    return Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Get-LinkTarget($Item) {
    if (-not $Item -or -not $Item.LinkType) { return $null }
    $target = @($Item.Target)[0]
    if (-not $target) { return $null }
    return ($target -replace '^\\\\\?\\', '')
}

function Test-UnderKit([string]$Path) {
    if (-not $Path) { return $false }
    $normalized = $Path.TrimEnd('\', '/')
    if ($OnWindows) { $comparison = [StringComparison]::OrdinalIgnoreCase }
    else { $comparison = [StringComparison]::Ordinal }
    return $normalized.StartsWith($Here, $comparison)
}

function Test-Ours([string]$Path) {
    # True when install.ps1 or install.sh put this skill here: a link into the kit or a marked copy.
    $item = Get-Existing $Path
    if (-not $item) { return $false }
    $target = Get-LinkTarget $item
    if ($target) { return Test-UnderKit $target }
    return Test-Path -LiteralPath (Join-Path $Path '.agent-workflow')
}

function Remove-Installed([string]$Path) {
    $item = Get-Existing $Path
    if (-not $item) { return }
    if ($item.LinkType) {
        # Remove the link or junction itself, never the content it points to.
        if ($OnWindows -and $item.PSIsContainer) { [System.IO.Directory]::Delete($Path) }
        else { [System.IO.File]::Delete($Path) }
    } else {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function New-Link([string]$Source, [string]$Dest) {
    try {
        New-Item -ItemType SymbolicLink -Path $Dest -Target $Source -ErrorAction Stop | Out-Null
        return 'linked'
    } catch {
        if (-not $OnWindows) { throw }
        New-Item -ItemType Junction -Path $Dest -Target $Source -ErrorAction Stop | Out-Null
        return 'joined by junction'
    }
}

function Install-Skills([string[]]$Targets, [bool]$CopyMode, [string]$ProjectDir) {
    if (-not $Targets -or $Targets.Count -eq 0) { $Targets = @('agents', 'claude') }
    foreach ($t in $Targets) {
        $dir = Resolve-Target $t $ProjectDir
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $modes = @{}
        foreach ($skill in Get-SkillDirs) {
            $dest = Join-Path $dir $skill.Name
            if (Get-Existing $dest) {
                if (-not (Test-Ours $dest)) {
                    Fail "$dest exists and was not installed by this script; remove it first"
                }
                Remove-Installed $dest
            }
            if ($CopyMode) {
                Copy-Item -LiteralPath $skill.FullName -Destination $dest -Recurse
                New-Item -ItemType File -Path (Join-Path $dest '.agent-workflow') -Force | Out-Null
                $mode = 'copied'
            } else {
                $mode = New-Link $skill.FullName $dest
            }
            $modes[$mode] = $true
        }
        Write-Output ("skills {0} into {1}" -f (($modes.Keys | Sort-Object) -join ' and '), $dir)
    }
}

function Find-Sh {
    $sh = Get-Command sh.exe -ErrorAction SilentlyContinue
    if ($sh) { return $sh.Source }
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
        $candidates = @(
            (Join-Path (Join-Path $gitRoot 'bin') 'sh.exe'),
            (Join-Path (Join-Path (Join-Path $gitRoot 'usr') 'bin') 'sh.exe')
        )
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }
    return $null
}

function Test-OnPath([string]$Dir) {
    $wanted = $Dir.TrimEnd('\', '/')
    foreach ($entry in ($env:PATH -split [System.IO.Path]::PathSeparator)) {
        if (-not $entry) { continue }
        $candidate = $entry.TrimEnd('\', '/')
        if ($OnWindows) { if ($candidate -ieq $wanted) { return $true } }
        elseif ($candidate -ceq $wanted) { return $true }
    }
    return $false
}

function Install-Commands([bool]$AppendToPath) {
    New-Item -ItemType Directory -Path $Bin -Force | Out-Null
    if ($OnWindows) {
        $sh = Find-Sh
        if (-not $sh) {
            Write-Output "note: sh.exe of Git for Windows not found; the commands were not installed."
            Write-Output "      Install Git for Windows, then run install again."
            return
        }
        foreach ($name in $CommandScripts.Keys) {
            $script = $CommandScripts[$name] -replace '\\', '/'
            $cmd = "@echo off`r`n`"$sh`" `"$script`" %*`r`n"
            [System.IO.File]::WriteAllText((Join-Path $Bin "$name.cmd"), $cmd, $Utf8NoBom)
            $wrapper = "#!/bin/sh`n# agent-workflow: $Here`nexec sh `"$script`" `"`$@`"`n"
            [System.IO.File]::WriteAllText((Join-Path $Bin $name), $wrapper, $Utf8NoBom)
        }
        Write-Output "commands plan-lifecycle and resource-lock written into $Bin"
        Write-Output "  (.cmd shims and Git Bash wrappers, using $sh)"
    } else {
        foreach ($name in $CommandScripts.Keys) {
            $dest = Join-Path $Bin $name
            if (Get-Existing $dest) { Remove-Installed $dest }
            New-Item -ItemType SymbolicLink -Path $dest -Target $CommandScripts[$name] | Out-Null
        }
        Write-Output "commands plan-lifecycle and resource-lock linked into $Bin"
    }
    if ($AppendToPath -and $OnWindows) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $entries = @()
        if ($userPath) { $entries = $userPath -split ';' | Where-Object { $_ } }
        if (-not ($entries | Where-Object { $_.TrimEnd('\') -ieq $Bin.TrimEnd('\') })) {
            [Environment]::SetEnvironmentVariable('Path', (($entries + $Bin) -join ';'), 'User')
            Write-Output "added $Bin to the user PATH; open a new terminal to use it"
        }
    } elseif (-not (Test-OnPath $Bin)) {
        Write-Output "note: $Bin is not on PATH"
    }
}

function Test-OurCommand([string]$Path) {
    $item = Get-Existing $Path
    if (-not $item) { return $false }
    $target = Get-LinkTarget $item
    if ($target) { return Test-UnderKit $target }
    if ($item.PSIsContainer) { return $false }
    $content = [System.IO.File]::ReadAllText($Path)
    return $content.Contains($Here) -or $content.Contains(($Here -replace '\\', '/'))
}

function Uninstall-Skills([string[]]$Targets, [string]$ProjectDir) {
    if (-not $Targets -or $Targets.Count -eq 0) { $Targets = @('agents', 'claude', 'opencode') }
    foreach ($t in $Targets) {
        $dir = Resolve-Target $t $ProjectDir
        foreach ($skill in Get-SkillDirs) {
            $dest = Join-Path $dir $skill.Name
            if ((Get-Existing $dest) -and (Test-Ours $dest)) {
                Remove-Installed $dest
                Write-Output "removed $dest"
            }
        }
    }
    if ($ProjectDir) { return }
    foreach ($name in $CommandScripts.Keys) {
        foreach ($file in @($name, "$name.cmd")) {
            $path = Join-Path $Bin $file
            if ((Get-Existing $path) -and (Test-OurCommand $path)) {
                Remove-Installed $path
                Write-Output "removed $path"
            }
        }
    }
}

function Initialize-Project([string]$Dir, [string]$BaseBranch) {
    if (-not $Dir) { Fail "usage: project DIR [-Base BRANCH]" }
    if (-not (Test-Path -LiteralPath $Dir)) { Fail "$Dir does not exist" }
    $Dir = (Resolve-Path -LiteralPath $Dir).Path
    Invoke-Git @('-C', $Dir, 'rev-parse', '--show-toplevel') | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "$Dir is not a git worktree" }
    $plans = (Invoke-Git @('-C', $Dir, 'config', '--get', 'workflow.plans')) -join ''
    if ($LASTEXITCODE -ne 0 -or -not $plans) { $plans = 'docs/plans' }
    $agents = Join-Path $Dir 'AGENTS.md'
    if (Test-Path -LiteralPath $agents) {
        Write-Output "AGENTS.md exists; merge $(Join-Path (Join-Path $Here 'templates') 'AGENTS.md') into it by hand"
    } else {
        Copy-Item -LiteralPath (Join-Path (Join-Path $Here 'templates') 'AGENTS.md') -Destination $agents
        Write-Output "AGENTS.md created from the template: fill in every <placeholder>"
    }
    $plansDir = $Dir
    foreach ($part in ($plans -split '/')) { if ($part) { $plansDir = Join-Path $plansDir $part } }
    New-Item -ItemType Directory -Path $plansDir -Force | Out-Null
    $keep = Join-Path $plansDir '.gitkeep'
    if (-not (Test-Path -LiteralPath $keep)) { New-Item -ItemType File -Path $keep | Out-Null }
    if ($BaseBranch) {
        Invoke-Git @('-C', $Dir, 'config', 'workflow.base', $BaseBranch) | Out-Null
    } else {
        $BaseBranch = (Invoke-Git @('-C', $Dir, 'config', '--get', 'workflow.base')) -join ''
        if ($LASTEXITCODE -ne 0 -or -not $BaseBranch) { $BaseBranch = '(unset)' }
    }
    Write-Output "plan directory $plans; base branch $BaseBranch"
    Write-Output "next: commit AGENTS.md and $plans/.gitkeep on the integration branch"
}

function Show-Usage {
    @'
usage: install.ps1 install   [-Copy] [-Project DIR] [-NoBin] [-AddToPath] [TARGET...]
       install.ps1 uninstall [-Project DIR] [TARGET...]
       install.ps1 project   DIR [-Base BRANCH]
       install.ps1 list

TARGET (default: agents claude)
  agents     ~\.agents\skills           Codex, OpenCode
  claude     ~\.claude\skills           Claude Code, OpenCode
  opencode   ~\.config\opencode\skills  OpenCode
  <dir>      any directory that an agent scans for <name>\SKILL.md
With -Project DIR the targets become DIR\.agents\skills, DIR\.claude\skills and DIR\.opencode\skills.
Get-Help .\install.ps1 -Detailed prints the full description.
'@
}

$projectDir = ''
if ($Project) {
    if (-not (Test-Path -LiteralPath $Project)) { Fail "$Project does not exist" }
    $projectDir = (Resolve-Path -LiteralPath $Project).Path
}

switch ($Command) {
    'install' {
        Install-Skills $Arguments $Copy.IsPresent $projectDir
        if (-not $NoBin -and -not $projectDir) { Install-Commands $AddToPath.IsPresent }
    }
    'uninstall' { Uninstall-Skills $Arguments $projectDir }
    'project' { Initialize-Project (@($Arguments) | Select-Object -First 1) $Base }
    'list' { Get-SkillDirs | ForEach-Object { $_.Name } }
    default { Show-Usage }
}
