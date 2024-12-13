


# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-Login
#
#   Creates a session on the server
#   TODO: email 2fa
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-Login 
{
    param
    (
        [Parameter(Mandatory=$true)] $pds, [Parameter(Mandatory=$true)] $username, [Parameter(Mandatory=$true)] $password
    )

    # Setup variables
    $url = "https://$pds/xrpc/com.atproto.server.createSession"
    $body = "{`"identifier`":`"$username`", `"password`":`"$password`"}"
    $headers = @{
        "Content-Type" = "application/json"
    }

    # Log
    ""
    "url: $url"
    ""

    # Send request
    $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $body
    $responseContent = ConvertFrom-Json $response.Content


    # Update global state
    $global:Bluesky_pds = $pds
    $global:Bluesky_accessJwt = $responseContent.accessJwt
    $global:Bluesky_refreshJwt = $responseContent.refreshJwt


    # More logging
    "did: $($responseContent.did)"
    "email: $($responseContent.email)"
    "active: $($responseContent.active)"
    "status: $($responseContent.status)"
    ""
    ""
}




# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-GetUnreadCount
#
#   Get the number of unread notifications.
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-GetUnreadCount
{
    # Setup variables (from global state)
    $pds = $global:Bluesky_pds
    $accessJwt = $global:Bluesky_accessJwt
    $url = "https://$pds/xrpc/app.bsky.notification.getUnreadCount"
    $headers = @{
        "Authorization" = "Bearer $accessJwt"
    }

    # Log
    ""
    "url: $url"
    ""

    # Check stuff
    if ($pds -eq $null) { throw "pds is null" }
    if ($accessJwt -eq $null) { throw "accessJwt is null" }

    # Send request
    $response = Invoke-WebRequest -Method GET -Uri $url -Headers $headers
    $responseContent = ConvertFrom-Json $response.Content

    # Log
    ""
    ("unread count: " + $responseContent.count)
    ""
    ""
}


# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-Logout
#
#   Clears global state.
#   (Calling deleteSession can delete the refreshJwt, but not the accessJwt - the latter just needs to expire.)
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-Logout
{
    # Setup variables (from global state)
    $pds = $global:Bluesky_pds
    $refreshJwt = $global:Bluesky_refreshJwt
    $url = "https://$pds/xrpc/com.atproto.server.deleteSession"
    $headers = @{"Authorization" = "Bearer $refreshJwt"}

    # Log
    ""
    "url: $url"
    ""

    # Send request
    if(($pds -ne $null) -and ($refreshJwt -ne $null))
    {
        Invoke-WebRequest -Method POST -Uri $url -Headers $headers
    }
    else
    {
        "Not sending request - pds or jwt is null."
        ""
    }


    # Update (clear) global state
    $global:Bluesky_pds = $null
    $global:Bluesky_accessJwt = $null
    $global:Bluesky_refreshJwt = $null

}

