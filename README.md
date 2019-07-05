# Trakt-PS-Module

Powershell Module based on trakt API
https://trakt.docs.apiary.io/#

I'm building this module as a request from a friends who wants to have better sync between
Ombi, Sonarr, Radarr and Trakt.

For this to work you will need to create an App in trakt
https://trakt.tv/oauth/applications/new

![alt text](https://i.imgur.com/WqLm1aP.png)

# Getting started
## One-time setup (PowerShell Gallery)
1. Install the Trakt-PS-Module module from: https://www.powershellgallery.com/packages/Trakt-PS-Module
```PowerShell
Install-Module -Name Trakt-PS-Module
```
## Each time you use the module
```PowerShell
Connect-Trakt -ClientID "9841ds81e8d1e281f8e1f81" -ClientSecret "c7e1dce1d9f29e4fdd9e1f9e1f9e1f9e1f9e1f"
```
## To Save Connection Info and Skip Connect-Trakt
1. It will Save in your %appdata% folder Root
```PowerShell
Connect-Trakt -ClientID "9841ds81e8d1e281f8e1f81" -ClientSecret "c7e1dce1d9f29e4fdd9e1f9e1f9e1f9e1f9e1f" -Save $true
```

## Exemple
```PowerShell
Connect-Trakt -ClientID "9841ds81e8d1e281f8e1f81" -ClientSecret "c7e1dce1d9f29e4fdd9e1f9e1f9e1f9e1f9e1f"
$TraktObj = Set-TraktObject -MediaType movies -IdType tmdb -MediaID "479455"
Add-TraktUserListItem -list "Watchlist 1" -BodyObj $TraktObj
```
