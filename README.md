# bluesky-powershell

I've heard Bluesky programming described as "just a bunch of JSON calls".
I wanted to prove this out and show simple examples of interacting with the Bluesky APIs.

At the moment only a few scenarios are supported. They are below.


## Dot-source the script to load the functions

[script-scope-and-dot-sourcing](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7.4#script-scope-and-dot-sourcing)

```powershell
. .\Bluesky.ps1
```


## Login with no email 2fa

```powershell

$username = "your_username"
$password = "your_password"
$session = Bluesky-Login -UserName $username -Password $password

```


## Login with email 2fa

```powershell

$username = "your_username"
$password = "your_password"

# First call to generate auth token email - retrieve that and set $authToken
$session = Bluesky-Login -UserName $username -Password $password

# Second call to use use auth token and log in
$session = Bluesky-Login -UserName $username -Password $password -AuthFactorToken $authToken

```


## Get user's unread notification count

Using the user session obtained above ⬆️


```powershell
Bluesky-GetUnreadCount -UserSession $session
```
