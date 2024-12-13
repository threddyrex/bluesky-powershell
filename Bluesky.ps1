


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

    # Send request
    $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $body
    $responseContent = ConvertFrom-Json $response.Content

    # Create hashtable for return
    $ctx = @{
        "pds" = $pds
        "username" = $username
        "did" = $responseContent.did
        "accessJwt" = $responseContent.accessJwt
        "refreshJwt" = $responseContent.refreshJwt
        "url" = $url
        "response" = $response
    }

    return $ctx;

}

# --------------------------------------------------------------------------------------------------------------------
#
#   assertLoginContext
#
# --------------------------------------------------------------------------------------------------------------------
function assertLoginContext
{
    param
    (
        [Parameter(Mandatory=$true)] $ctx
    )

    if ($ctx -eq $null) { throw "ctx is null"}
    if (($ctx -is [hashtable]) -eq $false) { throw "ctx is not a hashtable"}
    if ($ctx.ContainsKey("pds") -eq $false) { throw "pds missing" }
    if ($ctx.ContainsKey("accessJwt") -eq $false) { throw "accessJwt is missing" }

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
    param
    (
        [Parameter(Mandatory=$true)] $ctx
    )


    # Check stuff
    assertLoginContext -ctx $ctx


    # Setup variables (from global state)
    $pds = $ctx["pds"]
    $accessJwt = $ctx["accessJwt"]
    $url = "https://$pds/xrpc/app.bsky.notification.getUnreadCount"
    $headers = @{
        "Authorization" = "Bearer $accessJwt"
    }

    # Send request
    $response = Invoke-WebRequest -Method GET -Uri $url -Headers $headers
    $responseContent = ConvertFrom-Json $response.Content

    # Create hashtable for return
    $ret = @{
        "url" = $url
        "count" = $responseContent.count
        "response" = $response
    }

    return $ret
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
    param
    (
        [Parameter(Mandatory=$true)] $ctx
    )

    # Check stuff
    assertLoginContext -ctx $ctx


    # Setup variables (from global state)
    $pds = $ctx["pds"]
    $refreshJwt = $ctx["refreshJwt"]
    $url = "https://$pds/xrpc/com.atproto.server.deleteSession"
    $headers = @{"Authorization" = "Bearer $refreshJwt"}

    # Send request
    $response = $null
    $msg = $null

    if(($pds -ne $null) -and ($refreshJwt -ne $null))
    {
        $msg = "Sending request."
        $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers
    }
    else
    {
        $msg = "Not sending request - pds or jwt is null."
    }

    # Create hashtable for return
    $ret = @{
        "url" = $url
        "msg" = $msg
        "response" = $response
    }

    return $ret
}

