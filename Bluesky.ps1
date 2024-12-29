


$InformationPreference = "Continue"


# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-CreateSession
#
#   Creates a session on the server.
#   https://docs.bsky.app/docs/api/com-atproto-server-create-session
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-CreateSession
{
    param
    (
        [Parameter(Mandatory=$true)] $UserName, [Parameter(Mandatory=$true)] $Password, $PDS = "bsky.social", $AuthFactorToken = $null
    )

    # Set up variables
    $url = "https://$PDS/xrpc/com.atproto.server.createSession"
    $headers = @{
        "Content-Type" = "application/json"
    }
    $body = @{ 
        "identifier" = $UserName 
        "password" = $Password
    }

    Write-Information "Url: $url"

    if ($AuthFactorToken -ne $null)
    {
        Write-Information "Adding authFactorToken to body"
        $body["authFactorToken"] = $AuthFactorToken
    } 


    # Send request
    try
    {
        Write-Information "Calling Invoke-WebRequest"
        $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body ($body | ConvertTo-Json)
        $responseContent = ConvertFrom-Json $response.Content

        Write-Information "responseContent: $responseContent"

        $ret = @{
            "UserName" = $UserName
            "PDS" = $PDS
            "AuthFactorTokenExists" = ($AuthFactorToken -ne $null)
            "AccessJwt" = $responseContent.accessJwt
            "RefreshJwt" = $responseContent.refreshJwt
            "DID" = $responseContent.did
        }

        return $ret
    }
    catch
    {
        # Failed. Please check specified user/pass/pds. Also - you may need to retrieve email token.
        throw "Failed. Please check specified user/pass/pds. Also - you may need to retrieve email token. $_"
    }
}



# --------------------------------------------------------------------------------------------------------------------
#
#   assertSession
#
# --------------------------------------------------------------------------------------------------------------------
function assertSession
{
    param
    (
        [Parameter(Mandatory=$true)] $Session
    )

    Write-Information "assertSession"
    if ($Session -eq $null) { throw "Session is null"} else { Write-Information "    Session is not null" }
    if ($Session.PDS -eq $null) { throw "PDS is null"} else { Write-Information "    PDS is not null" }
    if ($Session.UserName -eq $null) { throw "UserName is null"} else { Write-Information "    UserName is not null" }
    if ($Session.AccessJwt -eq $null) { throw "AccessJwt is null"} else { Write-Information "    AccessJwt is not null" }

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
        [Parameter(Mandatory=$true)] $Session
    )


    # Verify that the user session is valid
    assertSession -Session $Session


    # Set up variables
    $pds = $Session.PDS
    $url = "https://$pds/xrpc/app.bsky.notification.getUnreadCount"
    $headers = @{
        "Authorization" = "Bearer $($Session.AccessJwt)"
    }

    Write-Information "Url: $url"
    Write-Information "UserName: $($Session.UserName)"

    # Send request
    $response = Invoke-WebRequest -Method GET -Uri $url -Headers $headers
    $responseContent = ConvertFrom-Json $response.Content

    Write-Information "responseContent: $responseContent"

    # Create return
    $ret = @{
        "Count" = $responseContent.count
    }

    return $ret
}



# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-DeleteSession
#
#   Clears global state.
#   (Calling deleteSession can delete the refreshJwt, but not the accessJwt - the latter just needs to expire.)
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-DeleteSession
{
    param
    (
        [Parameter(Mandatory=$true)] $Session
    )

    # Check stuff
    assertSession -Session $Session

    # Set up variables
    $pds = $Session.PDS
    $refreshJwt = $Session.Response.refreshJwt
    $url = "https://$pds/xrpc/com.atproto.server.deleteSession"
    $headers = @{"Authorization" = "Bearer $($Session.RefreshJwt)"}

    Write-Information "Url: $url"

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

    # Set up variables
    $url = "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=$Actor"

    Write-Information "Url: $url"

    # Send request
    try
    {
        $response = Invoke-WebRequest -Method GET -Uri $url
        return (ConvertFrom-Json $response.Content)
    }
    catch
    {
        # Failed.
        throw "getProfile failed. $_"
    }
}


# --------------------------------------------------------------------------------------------------------------------
#
#   Bluesky-CreateTextPost
#
#   https://docs.bsky.app/docs/get-started#create-a-post (see "CURL" section)
#
# --------------------------------------------------------------------------------------------------------------------
function Bluesky-CreateTextPost
{
    param
    (
        [Parameter(Mandatory=$true)] $Session,
        [Parameter(Mandatory=$true)] $Text
    )

    # Verify that the user session is valid
    assertSession -Session $Session

    # Set up variables 
    $url = "https://$($Session.PDS)/xrpc/com.atproto.repo.createRecord"
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $($Session.AccessJwt)"
    }
    $body = @{
        repo = $Session.DID
        collection = "app.bsky.feed.post"
        record = @{
            text = $Text
            createdAt = [System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        }
    }

    # Send request
    try {
        $response = Invoke-WebRequest -Method POST -Uri $url -Headers $headers -Body ($body | ConvertTo-Json)
        return (ConvertFrom-Json $response.Content)
    }
    catch {
        throw "Failed to create post: $_"
    }
}
