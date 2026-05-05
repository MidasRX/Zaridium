# Second pass: fix dispatch sites, Key->key, story files, ripple migration leftovers.
$ErrorActionPreference = 'Stop'
$root = 'c:\Users\mouss\Documents\orca\roblox-script\src'
$files = Get-ChildItem -Path $root -Recurse -Include *.ts, *.tsx

# Map of action-creator names that are now producer methods.
# (All exported from old store/actions/* files.)
$actionNames = @(
    # dashboard
    'setDashboardPage', 'toggleDashboard', 'setHint', 'clearHint',
    'playerSelected', 'playerDeselected',
    # jobs
    'setJobActive', 'setJobValue',
    # options
    'setConfig', 'setShortcut', 'removeShortcut', 'setTheme'
)

$totalChanged = 0
foreach ($f in $files) {
    $orig = Get-Content -LiteralPath $f.FullName -Raw
    $t = $orig

    # 1. Strip imports from store/actions/*
    $t = [regex]::Replace($t, '(?m)^import\s+\{[^}]+\}\s+from\s+"store/actions/[^"]+";\s*\r?\n', '')

    # 2. Convert `dispatch(actionName(args))` -> `dispatch.actionName(args)`
    foreach ($name in $actionNames) {
        $t = $t -replace ("dispatch\(\s*$name\s*\(([^)]*)\)\s*\)"), ("dispatch.$name(`$1)")
    }

    # 3. JSX Key= -> key=
    $t = $t -replace '(\s)Key=', '$1key='

    # 4. Story files: rodux-hooked StoreProvider import + mount/unmount
    $t = $t -replace 'import\s+\{\s*StoreProvider\s+as\s+Provider\s*\}\s+from\s+"@rbxts/roact-rodux-hooked";\s*\r?\n', "import { ReflexProvider } from `"@rbxts/react-reflex`";`r`nimport { createRoot } from `"@rbxts/react-roblox`";`r`n"
    $t = $t -replace '<Provider\s+store=\{store\}>', '<ReflexProvider producer={store}>'
    $t = $t -replace '</Provider>', '</ReflexProvider>'
    # React.mount(elem, container) -> { const root = createRoot(container); root.render(elem); }
    # The pattern is: const handle = React.mount( <elem>, container, );  return () => React.unmount(handle);
    $t = $t -replace 'React\.mount\(', 'createReactMount('
    $t = $t -replace 'React\.unmount\(', 'unmountReactMount('

    if ($t -ne $orig) {
        Set-Content -LiteralPath $f.FullName -Value $t -NoNewline
        $totalChanged++
        Write-Host "modified: $($f.FullName.Substring($root.Length+1))"
    }
}
Write-Host "`nTotal files modified: $totalChanged"
