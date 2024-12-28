


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
    $body = @{ 
        "identifier" = $UserName 
        "password" = $Password
    }

    if ($AuthFactorToken -ne $null)
    {
        $body["authFactorToken"] = $AuthFactorToken
    } 


    # Send request
    try
    {
        $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body ($body | ConvertTo-Json)
        $responseContent = ConvertFrom-Json $response.Content

        $ret = @{
            "UserName" = $UserName
            "PDS" = $PDS
            "Response" = $responseContent
        }

        return $ret
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
    if ($UserSession.PDS -eq $null) { throw "PDS is null"}
    if ($UserSession.UserName -eq $null) { throw "UserName is null"}
    if ($UserSession.Response.did -eq $null) { throw "did is null"}
    if ($UserSession.Response.didDoc -eq $null) { throw "didDoc is null"}
    if ($UserSession.Response.accessJwt -eq $null) { throw "accessJwt is null"}

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
    $pds = $UserSession.PDS
    $accessJwt = $UserSession.Response.accessJwt
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
        "Response" = $responseContent
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
    $pds = $UserSession.PDS
    $refreshJwt = $UserSession.Response.refreshJwt
    $url = "https://$pds/xrpc/com.atproto.server.deleteSession"
    $headers = @{"Authorization" = "Bearer $refreshJwt"}

    # Send request
    if(($pds -ne $null) -and ($refreshJwt -ne $null))
    {
        Invoke-WebRequest -Method POST -Uri $url -Headers $headers
    }
}



# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-GetProfile
#
#   https://docs.bsky.app/docs/api/app-bsky-actor-get-profile
#   https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$Actor
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-GetProfile
{
    param
    (
        [Parameter(Mandatory=$true)] $Actor
    )

    # Setup variables
    $url = "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$Actor"

    # Send request
    try
    {
        $response = Invoke-WebRequest -Method GET -Uri $url
        $responseContent = ConvertFrom-Json $response.Content

        # Create hashtable for return
        $ret = @{
            "url" = $url
            "Actor" = $Actor
            "Response" = $responseContent
        }

        return $ret;
    }
    catch
    {
        # Failed.
        throw "getProfile failed. $_"
    }

}
