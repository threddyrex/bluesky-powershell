


# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-Login
#
#   Creates a session on the server.
#   https://docs.bsky.app/docs/api/com-atproto-server-create-session
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-Login
{
    param
    (
        [Parameter(Mandatory=$true)] $UserName, [Parameter(Mandatory=$true)] $Password, $PDS = "bsky.social", $AuthFactorToken = $null
    )

    # Setup variables
    $url = "https://$PDS/xrpc/com.atproto.server.createSession"
    $headers = @{
        "Content-Type" = "application/json"
    }
    $body = $null
    if ($authFactorToken -eq $null)
    {
        $body = "{`"identifier`":`"$UserName`", `"password`":`"$password`"}"
    }
    else
    {
        $body = "{`"identifier`":`"$UserName`", `"password`":`"$password`", `"authFactorToken`":`"$authFactorToken`"}"
    }


    # Send request
    try
    {
        $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body $body
        $responseContent = ConvertFrom-Json $response.Content

        # Create hashtable for return
        $session = @{
            "PDS" = $PDS
            "UserName" = $UserName
            "did" = $responseContent.did
            "accessJwt" = $responseContent.accessJwt
            "refreshJwt" = $responseContent.refreshJwt
            "url" = $url
            "response" = $response
        }

        return $session;
    }
    catch
    {
        # Failed. Either user/pass was incorrect, or maybe they need email token.
        throw "Login failed. $_"
    }
}



# --------------------------------------------------------------------------------------------------------------------
#
#   assertUserSession
#
# --------------------------------------------------------------------------------------------------------------------
function assertUserSession
{
    param
    (
        [Parameter(Mandatory=$true)] $UserSession
    )

    if ($UserSession -eq $null) { throw "UserSession is null"}
    if (($UserSession -is [hashtable]) -eq $false) { throw "UserSession is not a hashtable"}
    if ($UserSession.ContainsKey("pds") -eq $false) { throw "pds missing" }
    if ($UserSession.ContainsKey("accessJwt") -eq $false) { throw "accessJwt is missing" }

}



# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-GetUnreadCount
#
#   Get the number of unread notifications.
#   https://docs.bsky.app/docs/api/app-bsky-notification-get-unread-count
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-GetUnreadCount
{
    param
    (
        [Parameter(Mandatory=$true)] $UserSession
    )


    # Check stuff
    assertUserSession -UserSession $UserSession


    # Setup variables (from global state)
    $pds = $UserSession["pds"]
    $accessJwt = $UserSession["accessJwt"]
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
        [Parameter(Mandatory=$true)] $UserSession
    )

    # Check stuff
    assertUserSession -UserSession $UserSession


    # Setup variables
    $pds = $UserSession["pds"]
    $refreshJwt = $UserSession["refreshJwt"]
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

