<#
.SYNOPSIS
    Validates the MgContext to ensure a valid connection to Microsoft Graph including the required permissions.
#>

function Test-MtContext {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # If specified, the scope will be checked to send email.
        [Parameter(Mandatory = $false)]
        [switch] $SendMail
    )

    $validContext = $true
    if (!(Get-MgContext)) {
        $message = "Not connected to Microsoft Graph. Please use 'Connect-Maester' or 'Connect-MtGraph'. For more information, use 'Get-Help Connect-MtGraph'."
        $validContext = $false
    } else {
        $requiredScopes = Get-MtGraphScope -SendMail:$SendMail
        $currentScopes = Get-MgContext | Select-Object -ExpandProperty Scopes
        $missingScopes = $requiredScopes | Where-Object { $currentScopes -notcontains $_ }

        if ($missingScopes) {
            $message = "These Graph permissions are missing in the current connection => ($($missingScopes))."
            $authType = (Get-MgContext).AuthType
            if ($authType -eq  'Delegated') {
                $message += " Please use 'Connect-Maester' or 'Connect-MtGraph'. For more information, use 'Get-Help Connect-MtGraph'."
            } else {
                $clientId = (Get-MgContext).ClientId
                $urlTemplate = "https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$clientId/isMSAApp~/false"
                $message += " Add the missing 'Application' permissions in the Microsoft Entra portal and grant consent. You will also need to Disconnect-Graph to refresh the permissions."
                $message += " Click here to open the 'API Permissions' blade for this app (GitHub/Azure DevOps might prevent this link from working): $urlTemplate"
            }
            $validContext = $false
        }
    }

    if (!$validContext) {
        throw $message
    }
    return $validContext
}