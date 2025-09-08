param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

$nameProjects = ".projects"
$filePriority = ".filesPriority"
$listFoldersOrFilesForPriority = @() 
$newParts = $NewVersion.Split('.')
$patternsVersion = @(
    '(?<=AssemblyVersion\(")\d+\.\d+\.\d+(\.\d+)?(?="\))',
    '(?<=AssemblyFileVersion\(")\d+\.\d+\.\d+(\.\d+)?(?="\))',
    '(?<=<AssemblyVersion>)\d+\.\d+\.\d+(\.\d+)?(?=</AssemblyVersion>)',
    '(?<=<FileVersion>)\d+\.\d+\.\d+(\.\d+)?(?=</FileVersion>)',
    '(?<=<Version>)\d+\.\d+\.\d+(\.\d+)?(?=</Version>)',
    '(?<="version":\s*")\d+\.\d+\.\d+(\.\d+)?(?=")'
)

Function Main {
    if (-not (Test-Path $nameProjects)) {
        Write-Host "El archivo .projects no se encontró en la ruta: $nameProjects"
        return
    }

    if (-not (Test-Path $filePriority)) {
        Write-Host "La lista de archivos prioritarios no se encuentra en la ruta $filePriority"
        return
    }

    $listFoldersOrFilesForPriority = Get-ListFilesPriority

    if($listFoldersOrFilesForPriority.Count -eq 0) {
        Write-Host "La lista de archivos prioritarios no se encuentra ninguna carpeta o archivo, total:$($listFoldersOrFilesForPriority.Count)"
        return
    }

    $listPathAssemblys = Get-ListPathTotalAssemblys

    $listPathAssemblys | ForEach-Object {
        $content = Get-Content $_ -Raw
        foreach($pattern in $patternsVersion) {
            $content = [regex]::Replace($content, $pattern, {
                param($match)
                Adjust-VersionFormat $match.Value $NewParts
            })
        }
        $content | Out-File -FilePath $_ -Encoding utf8 -NoNewline
        Write-Host "Assembly actualizado: $_"
    }
}

function Get-ListFilesPriority {
    $listFilesPriority = @()
    Get-Content $filePriority | ForEach-Object {
        $listFilesPriority += [string]$_
    }
    return $listFilesPriority
}

Function Get-ListPathTotalAssemblys {
    $listPathsAux = @()
    foreach($project in Get-ListPathsProjects) {
        $pathBuilder = Build-PathsAssemblys -pathProject $project.path

        $result = Verify-IsFileOrIsFolder -path $pathBuilder

        if($result.Item1) {
            $listPathsAux += $pathBuilder
        }

        if ($result.Item2) {
            $listPathsAux += Get-ListChildFolderAssembly -path $pathBuilder
        }
    }
    return $listPathsAux
}

function Get-ListPathsProjects {
    $listPathsProjects = @()
    Get-Content $nameProjects | ForEach-Object {
        $parts = $_.Split("=", 2)
        if ($parts.Length -eq 2) {
            $listPathsProjects += [pscustomobject]@{name=$parts[0];path=$parts[1]}
        }
    }
    return $listPathsProjects
}

function Build-PathsAssemblys {
    param(
        [string]$pathProject
    )
    $listPathAssembly = @()

    if (-not ([string]::IsNullOrWhiteSpace($pathProject))) {
        foreach($fileOrFolder in $listFoldersOrFilesForPriority) {
            $pathTemp = Join-Path $pathProject $fileOrFolder

            if(Test-Path $pathTemp) {
                $listPathAssembly += $pathTemp
                break;
            }
        }
    }
    return $listPathAssembly
}

function Verify-IsFileOrIsFolder {
    param(
        [string]$path
    )
    $isFile = $false
    $isFolder = $false

    if (Test-Path $path -PathType Container) {
        $isFolder = $true
    } elseif (Test-Path $path -PathType Leaf) {
        $isFile = $true
    }

    return [System.Tuple]::Create($isFile, $isFolder)
}

function Get-ListChildFolderAssembly {
    param(
        [string]$path
    )
    $listPathChildAssembly = Get-ChildItem -Path $path | Where-Object { $_.Name -notmatch "Test|.sln$" } | ForEach-Object {
        Join-Path $path $_.Name "$($_.Name).csproj"
    }
    return $listPathChildAssembly
}

function Adjust-VersionFormat {
    param(
        [string]$OldVersion,
        [string[]]$NewParts
    )

    $oldParts = $OldVersion.Split('.')
    $count = $oldParts.Count

    if ($count -le $NewParts.Count) {
        return ($NewParts[0..($count-1)] -join '.')
    }
    else {
        throw "La nueva versión tiene menos segmentos que la versión antigua ($OldVersion)"
    }
}

Main
