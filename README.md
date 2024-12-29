# bluesky-powershell

I've heard Bluesky programming described as "just a bunch of JSON calls".
I wanted to prove this out and show simple examples of interacting with the Bluesky APIs using PowerShell.

At the moment only a few scenarios are supported. They are below.

You can view docs for the Bluesky API on their web site: https://docs.bsky.app/docs/get-started

&nbsp;

# Dot-source the script to load the functions

You start by [dot-sourcing](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7.4#script-scope-and-dot-sourcing) 
the script into your current scope.


```powershell
. .\Bluesky.ps1
```

&nbsp;


# CreateSession WITHOUT two-factor authentication

If you want to use APIs that require authentication, next step is to log in.
If you don't have email two-factor authentication turned on, you can use the below script.

```powershell

$username = "your_username"
$password = "your_password"
$session = Bluesky-CreateSession -UserName $username -Password $password

```

If the call succeeds, $session will contain the authentication token needed to make 
subsequent authenticated API calls.

&nbsp;


# CreateSession WITH two-factor authentication

If you have email two-factor authentication turned on, it requires two calls to "createSession".
The first call results in Bluesky sending you an email with an auth token. The second call
completes the login process.

```powershell

$username = "your_username"
$password = "your_password"

# First call to generate auth token email - retrieve that and set $authToken
$session = Bluesky-CreateSession -UserName $username -Password $password

# Second call to use use auth token and log in
$session = Bluesky-CreateSession -UserName $username -Password $password -AuthFactorToken $authToken

```

&nbsp;

# Get user's unread notification count

Using the user session obtained above ⬆️


```powershell
Bluesky-GetUnreadCount -Session $session
```

&nbsp;

# Get user's profile info

This doesn't require auth.

```powershell
Bluesky-GetProfile -Actor "threddyrex.org"
```

&nbsp;

# Create a text post

Using the user session obtained above ⬆️


```powershell
$text = "text you want to post"
Bluesky-CreateTextPost -Session $session -Text $text
```

