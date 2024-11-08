﻿<#
.SYNOPSIS
    Checks if passwords are set to expire

.DESCRIPTION
    Passwords should not be set to expire
    CIS Microsoft 365 Foundations Benchmark v3.1.0

.EXAMPLE
    Test-MtCisPasswordExpiry

    Returns true if no passwords are set to expire

.LINK
    https://maester.dev/docs/commands/Test-MtCisPasswordExpiry
#>
function Test-MtCisPasswordExpiry {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (!(Test-MtConnection Graph)) {
        Add-MtTestResultDetail -SkippedBecause NotConnectedGraph
        return $null
    }

    $scopes = (Get-MgContext).Scopes
    $permissionMissing = "Domain.Read.All" -notin $scopes
    if ($permissionMissing) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "Missing Scope Domain.Read.All"
        return $null
    }

    Write-Verbose "Get domain details the password expiry period"
    $domains = Get-MgDomain

    Write-Verbose "Get domains where passwords are set to expire"
    $result = $domains | Where-Object { $_.PasswordValidityPeriodInDays -ne "2147483647" }

    $testResult = ($result | Measure-Object).Count -eq 0

    if ($testResult) {
        $testResultMarkdown = "Well done. Your tenant passwords are not set to expire:`n`n%TestResult%"
    }
    else {
        $testResultMarkdown = "Your tenant has 1 or more domains which expire passwords:`n`n%TestResult%"
    }

    $resultMd = "| Display Name | Domain |`n"
    $resultMd += "| --- | --- |`n"
    foreach ($item in $domains) {
        $itemResult = "❌ Fail"
        if ($item.id -notin $result.id) {
            $itemResult = "✅ Pass"
        }
        $resultMd += "| $($item.Id) | $($itemResult) |`n"
    }

    $testResultMarkdown = $testResultMarkdown -replace "%TestResult%", $resultMd

    Add-MtTestResultDetail -Result $testResultMarkdown

    return $testResult
}