# Bulk transform Roact -> React + drop withHooks for @rbxts/react migration
$ErrorActionPreference = 'Stop'

$root = 'c:\Users\mouss\Documents\orca\roblox-script\src'
$files = Get-ChildItem -Path $root -Recurse -Include *.ts, *.tsx | Where-Object { $_.FullName -notmatch '\\node_modules\\' }

$totalChanged = 0
foreach ($f in $files) {
    $orig = Get-Content -LiteralPath $f.FullName -Raw
    $t = $orig

    # 1. Imports: Roact -> React
    $t = $t -replace 'from "@rbxts/roact-hooked"', 'from "@rbxts/react"'
    $t = $t -replace 'from "@rbxts/roact"', 'from "@rbxts/react"'
    $t = $t -replace 'import\s+Roact\s+from\s+"@rbxts/react"', 'import React from "@rbxts/react"'
    # Aliased default import case (e.g. import Roact, { Binding } from "...")
    $t = $t -replace 'import\s+Roact\s*,\s*\{', 'import React, {'

    # 2. Drop withHooks / withHooksPure from imports (handle leading comma, trailing comma, alone)
    $t = $t -replace ',\s*withHooksPure\b', ''
    $t = $t -replace 'withHooksPure\s*,\s*', ''
    $t = $t -replace '\bwithHooksPure\b', ''
    $t = $t -replace ',\s*withHooks\b', ''
    $t = $t -replace 'withHooks\s*,\s*', ''
    $t = $t -replace '\bwithHooks\b', ''

    # 3. useMutable -> useRef (1:1 in api shape)
    $t = $t -replace '\buseMutable\b', 'useRef'

    # 4. Roact namespace -> React
    $t = $t -replace '\bRoact\.', 'React.'

    # 5. Drop withHooks(X) and withHooksPure(X) wrapper calls -> X
    #    (After step 2 these are just bare identifiers we now also need to remove the call)
    #    Step 2 already removed `withHooks` from imports. The CALL sites still say `withHooks(X)`.
    #    Replace `withHooks(Identifier)` -> `Identifier`, same for `withHooksPure`
    #    Re-add the names temporarily - actually we deleted import names but call site references
    #    still match the regex. Replace calls FIRST then strip imports:
    # Since our regex above stripped IDENTIFIERS too, restore for call replacement.
    # Easiest: do call-site replacement again on text that may still have it.
    $t = $t -replace 'withHooksPure\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)', '$1'
    $t = $t -replace 'withHooks\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)', '$1'

    # 6. [React.Children]: children pattern -> children (destructure)
    $t = $t -replace '\[React\.Children\]:\s*children', 'children'

    # 7. JsxInstanceChangeEvents -> InstanceChangeEvent
    $t = $t -replace '\bJsxInstanceChangeEvents\b', 'InstanceChangeEvent'

    # 8. Empty import braces cleanup: `import { } from "..."` -> remove line
    $t = [regex]::Replace($t, '(?m)^import\s+\{\s*\}\s+from\s+"[^"]+";\s*\r?\n', '')
    # Cleanup `import {  ,  X }` style mess from our replacements
    $t = $t -replace 'import\s+\{\s*,', 'import {'
    $t = $t -replace ',\s*,', ','
    $t = $t -replace '\{\s*,\s*', '{ '

    if ($t -ne $orig) {
        Set-Content -LiteralPath $f.FullName -Value $t -NoNewline
        $totalChanged++
        Write-Host "modified: $($f.FullName.Substring($root.Length+1))"
    }
}
Write-Host "`nTotal files modified: $totalChanged"
