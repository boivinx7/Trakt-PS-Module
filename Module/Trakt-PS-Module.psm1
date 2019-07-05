<#
	.SYNOPSIS
		Used to Convert Date Value outputed by trakt
	
	.DESCRIPTION
		A detailed description of the ConvertFrom-EpochDate function.
	
	.PARAMETER EpochDate
		 Param1 help description
	
	.EXAMPLE
				PS C:\> ConvertFrom-EpochDate -EpochDate $value1
	
	.NOTES
		Additional information about the function.
#>
function ConvertFrom-EpochDate
{
	[CmdletBinding()]
	[OutputType([DateTime])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		$EpochDate
	)
	
	process
	{
		[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($EpochDate))
	}
}

<#
	.SYNOPSIS
		Used to Created Trakt Json object to add, remove media from lists
	
	.DESCRIPTION
		Used to make it easier to create the JSON object to add or Remove Media from lists.
	
	.PARAMETER MediaType
		Media Type you want to use.
	
	.PARAMETER IdType
		ID type, so trakt, TVDB, TMDB or imdb.
	
	.PARAMETER MediaID
		ID of the Media.
	
	.EXAMPLE
				PS C:\> Set-TraktObject -MediaType movies -IdType trakt -MediaID 'Value3'
	
	.NOTES
		Additional information about the function.
#>
function Set-TraktObject
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateSet('movies', 'shows', 'seasons', 'episodes')]
		[string]$MediaType,
		[Parameter(Mandatory = $true)]
		[ValidateSet('trakt', 'tvdb', 'tmdb', 'imdb')]
		[string]$IdType,
		[Parameter(Mandatory = $true)]
		[string]$MediaID
	)
	
	#TODO: Place script here
	$hash = [ordered]@{
		$MediaType = @(
			@{ "ids" = @{ $IdType = $MediaID } }
		)
	}
	
	$json = $hash | ConvertTo-Json -Depth 99
	
	$json
}

<#
	.SYNOPSIS
		Set Trakt Info
		This is optional and you can simply use Connect-Trakt.
		But Since This one is Saving the info on a local file, you do not need to pass Encrypted info.
		If you use Connect-Trakt you will need to encode the Client ID and Secret
	
	.DESCRIPTION
		You first Need to Go set a new app on
		https://trakt.tv/oauth/applications/new
		Use "urn:ietf:wg:oauth:2.0:oob" as redirect URI
		All this Module is based on that and will not work if you use anything else
		
		Once you execute this Function, Info will be encoded to an XML file in BaseCode64 and will be used for multiple other functions
	.PARAMETER ClientID
		Client ID Given when creating an App on Trakt.
	
	.PARAMETER ClientSecret
		Client Secret Given when creating an App on Trakt.
	
	.EXAMPLE
				PS C:\> Set-TraktAuthInfo -ClientID 'Value1' -ClientSecret 'Value2'
	
	.NOTES
		Xml file is saved to %AppData%.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Set-TraktAuthInfo
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ClientID,
		[Parameter(Mandatory = $true)]
		[string]$ClientSecret
	)
	
	$BytesClientID = [System.Text.Encoding]::Unicode.GetBytes($ClientID)
	$EncodedTextClientID = [Convert]::ToBase64String($BytesClientID)
	
	$BytesClientSecret = [System.Text.Encoding]::Unicode.GetBytes($ClientSecret)
	$EncodedTextClientSecret = [Convert]::ToBase64String($BytesClientSecret)
	
	[xml]$Doc = New-Object System.Xml.XmlDocument
	
	#Create Declaration
	$dec = $Doc.CreateXmlDeclaration("1.0", "utf-8", $null)
	$doc.AppendChild($dec) | Out-Null
	#Create Trakt Info Node Node
	$Root = $doc.CreateNode("element", "TraktInfo", $null)
	
	#$TraktAppNode = $doc.CreateNode("element", "TraktApp", $null)
	
	$ClientIdNode = $doc.CreateNode("element", "ClientID", $null)
	$ClientIdNode.InnerText = $EncodedTextClientID
	
	$ClientSecretNode = $doc.CreateNode("element", "ClientSecret", $null)
	$ClientSecretNode.InnerText = $EncodedTextClientSecret
	
	$Root.AppendChild($ClientIdNode) | Out-Null
	$Root.AppendChild($ClientSecretNode) | Out-Null
	
	#$Root.AppendChild($TraktAppNode) | Out-Null
	$doc.AppendChild($Root) | Out-Null
	
	$doc.save("$env:APPDATA\TraktInfo.xml")
}

<#
	.SYNOPSIS
		Used to Authorized Trakt App
	
	.DESCRIPTION
		You Need to First Use Set-TraktAuthInfo function before you can use this function
		it will read the XML file with Saved info, decode the codes and Pop up a web form for authorization
		If you are already authorized the form will close on its own.
		Will Save info to XML file if Set,
		for next time will check creation date before calling complete fonction
		Authorization expires after 3 months, if it's expired will use refresh token to refresh.
	
	.PARAMETER Save
		Used to Save info to XML file located in APPDATA might want to use if you want to Schedule scripts.
	
	.PARAMETER ClientID
		Client ID Given when creating an App on Trakt.
	
	.PARAMETER ClientSecret
		Client Secret Given when creating an App on Trakt.
	
	.EXAMPLE 1
		PS C:\> Connect-Trakt

	.EXAMPLE 2
		PS C:\> $BytesClientID = [System.Text.Encoding]::Unicode.GetBytes("****************************CLIENT ID *************************")
		PS C:\> $EncodedTextClientID = [Convert]::ToBase64String($BytesClientID)
		PS C:\> $BytesClientSecret = [System.Text.Encoding]::Unicode.GetBytes("****************************CLIENT Secret*************************")
		PS C:\> $EncodedTextClientSecret = [Convert]::ToBase64String($BytesClientSecret)
		PS C:\> Connect-Trakt -ClientID $EncodedTextClientID -ClientSecret $EncodedTextClientSecret

	EXAMPLE 3
		PS C:\> Connect-Trakt -save $true
			
	.NOTES
		Xml file is saved to %AppData%.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Connect-Trakt
{
	[CmdletBinding()]
	[OutputType([Object])]
	param
	(
		[bool]$Save,
		[string]$ClientID,
		[string]$ClientSecret
	)
	
	
	
	Add-Type -AssemblyName 'System.Windows.Forms'
	Add-Type -AssemblyName 'System.Web'
	if ([string]::IsNullOrEmpty($ClientID) -ne $true -and [string]::IsNullOrEmpty($ClientSecret) -ne $true)
	{
		
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		if ([string]::IsNullOrEmpty($ClientID) -and [string]::IsNullOrEmpty($ClientSecret))
		{
			$ClienIDImport = $XMLInfo.TraktInfo.ClientID
			$ClienSecretImport = $XMLInfo.TraktInfo.ClientSecret
		}
		else
		{
			$ClienIDImport = $ClientID
			$ClienSecretImport = $ClientSecret
		}
		$ClientID = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		$ClientSecret = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienSecretImport))
		
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	$SiteUri = "https://trakt.tv"
	#$Script:API_URI = "https://api.trakt.tv"
	$RedirectURI = 'urn:ietf:wg:oauth:2.0:oob'
	$Script:code = $null
	
	$webBrowser = New-Object -TypeName 'System.Windows.Forms.WebBrowser'
	$webBrowser.Width = 450
	$webBrowser.Height = 600
	$webBrowser.Add_DocumentCompleted({
			if ($webBrowser.Url.AbsoluteUri -match 'oauth/authorize/(?<code>[^&]*)')
			{
				$form.Close()
				$Script:code = $Matches.code
			}
		})
	
	$form = New-Object -TypeName 'System.Windows.Forms.Form'
	$form.Width = 450
	$form.Height = 600
	$form.Add_Shown({ $form.Activate() })
	$form.Controls.Add($webBrowser)
	
	$webBrowser.Navigate(('{0}/oauth/authorize?response_type=code&client_id={1}&redirect_uri={2}' -f $SiteUri, $ClientID, $RedirectURI))
	
	$null = $form.ShowDialog()
	
	$code = (($Script:code.ToString()).Split("="))[1]
	
	$body = ConvertTo-Json -InputObject @{
		code		  = $code
		client_id	  = $ClientID
		client_secret = $ClientSecret
		grant_type    = 'authorization_code'
		redirect_uri  = $RedirectURI
	}
	
	$Invoke = Invoke-WebRequest -Uri "https://api.trakt.tv/oauth/token" -Method Post -Body $body -ContentType application/json
	
	$TraktConnect = $Invoke.content | ConvertFrom-Json
	$Global:AccessToken = $TraktConnect.access_token
	$global:ClientID = $ClientID
	$global:Username = (Get-TraktUserSettings).username
	
	if ($Save -eq $true)
	{
		
		if ((Test-Path -Path "$env:appdata\TraktInfo.xml" ) -eq $true )
		{
			Remove-Item -Path "$env:appdata\TraktInfo.xml" -Force
		}
		Set-TraktAuthInfo -ClientID $ClientID -ClientSecret $ClientSecret
		[XML]$XMLInfo = Get-Content -Path "$env:appdata\TraktInfo.xml"
		
		$RootAuth = $XMLInfo.TraktInfo
		$TraktAuthNode = $XMLInfo.CreateNode("element", "TraktAuth", $null)
		
		$AccessTokenNode = $XMLInfo.CreateNode("element", "AccessToken", $null)
		$BytesAccessToken = [System.Text.Encoding]::Unicode.GetBytes($TraktConnect.access_token)
		$EncodedTextAccessToken = [Convert]::ToBase64String($BytesAccessToken)
		$AccessTokenNode.InnerText = $EncodedTextAccessToken
		$TraktAuthNode.AppendChild($AccessTokenNode) | Out-Null
		
		$TokenTypeNode = $XMLInfo.CreateNode("element", "TokenType", $null)
		$TokenTypeNode.InnerText = $TraktConnect.token_type
		$TraktAuthNode.AppendChild($TokenTypeNode) | Out-Null
		
		$ExpiresInNode = $XMLInfo.CreateNode("element", "ExpiresIn", $null)
		$ExpiresInNode.InnerText = $TraktConnect.expires_in
		$TraktAuthNode.AppendChild($ExpiresInNode) | Out-Null
		
		$RefreshTokenTokenNode = $XMLInfo.CreateNode("element", "RefreshToken", $null)
		$BytesRefreshToken = [System.Text.Encoding]::Unicode.GetBytes($TraktConnect.refresh_token)
		$EncodedTextRefreshToken = [Convert]::ToBase64String($BytesRefreshToken)
		$RefreshTokenTokenNode.InnerText = $EncodedTextRefreshToken
		$TraktAuthNode.AppendChild($RefreshTokenTokenNode) | Out-Null
		
		$ScopeNode = $XMLInfo.CreateNode("element", "Scope", $null)
		$ScopeNode.InnerText = $TraktConnect.scope
		$TraktAuthNode.AppendChild($ScopeNode) | Out-Null
		
		$ScopeUser = $XMLInfo.CreateNode("element", "username", $null)
		$ScopeUser.InnerText = $global:Username
		$TraktAuthNode.AppendChild($ScopeUser) | Out-Null
		
		$CreatedAtNode = $XMLInfo.CreateNode("element", "CreatedAt", $null)
		$Date = ConvertFrom-EpochDate -EpochDate $TraktConnect.created_at
		$CreatedAtNode.InnerText = $Date
		$TraktAuthNode.AppendChild($CreatedAtNode) | Out-Null
		
		$RootAuth.AppendChild($TraktAuthNode) | Out-Null
		
		$XMLInfo.save("$env:APPDATA\TraktInfo.xml")
	}
	
	
	
}

<#
	.SYNOPSIS
		Get List of Movies in Anticipated Movies Public List
	
	.DESCRIPTION
		Get List of Movies in Anticipated Movies Public List
	
	.EXAMPLE
		PS C:\> Get-TraktAnticipatedMovies
	
	.NOTES
		You Need to First Use Set-TraktAuthInfo function before you can use this function.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Get-TraktAnticipatedMovies
{
	[CmdletBinding()]
	param ()
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
		
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $global:ClientID) | Out-Null
	$invoke = Invoke-WebRequest -Uri https://api.trakt.tv/movies/anticipated -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value.movie
}

<#
	.SYNOPSIS
		Get List of Movies in Box Office Public List
	
	.DESCRIPTION
		Get List of Movies in Box Office Public List
	
	.EXAMPLE
		PS C:\> Get-TraktBoxOfficeMovies
	
	.NOTES
		You Need to First Use Set-TraktAuthInfo function before you can use this function.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Get-TraktBoxOfficeMovies
{
	[CmdletBinding()]
	param ()
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$invoke = Invoke-WebRequest -Uri https://api.trakt.tv/movies/boxoffice -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value.movie
}

<#
	.SYNOPSIS
		Get List of Movies in Box Office Trending Public List
	
	.DESCRIPTION
		Get List of Movies in Box Office Trending Public List
	
	.EXAMPLE
		PS C:\> Get-TraktBoxOfficeTrending
	
	.NOTES
		You Need to First Use Set-TraktAuthInfo function before you can use this function.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Get-TraktBoxOfficeTrending
{
	[CmdletBinding()]
	param ()
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$invoke = Invoke-WebRequest -Uri https://api.trakt.tv/movies/trending -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value.movie
}

<#
	.SYNOPSIS
		Get List of Movies in Box Office Popular Public List
	
	.DESCRIPTION
		Get List of Movies in Box Office Popular Public List
	
	.EXAMPLE
		PS C:\> Get-TraktBoxOfficePopular
	
	.NOTES
		You Need to First Use Set-TraktAuthInfo function before you can use this function.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Get-TraktBoxOfficePopular
{
	[CmdletBinding()]
	param ()
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$invoke = Invoke-WebRequest -Uri https://api.trakt.tv/movies/popular -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		Search all text fields that a media object contains.
		Results are ordered by the most relevant score. Specify the type of results by sending a single value or a comma delimited string for multiple types.
		By default, all text fields are used to search for the query. You can optionally specify the fields parameter with a single value or comma delimited string for multiple fields.
		Each type has specific fields that can be specified. This can be useful if you want to support more strict searches (i.e. title only).
	
	.DESCRIPTION
		Searches with use of queries. Queries will search text fields like the title and overview.
		Search all text fields that a media object contains (i.e. title, overview, etc). Results are ordered by the most relevant score.
		Specify the type of results by sending a single value or a comma delimited string for multiple types.By default, all text fields are used to search for the query.
		You can optionally specify the fields parameter with a single value or comma delimited string for multiple fields.
		Each type has specific fields that can be specified. This can be useful if you want to support more strict searches (i.e. title only).
	
	.PARAMETER Type
		Type of Media you are looking for :
		
		Type	Field
		
		movie	title
		tagline
		overview
		people
		translations
		aliases
		
		show	title
		overview
		people
		translations
		aliases
		
		episode	title
		overview
		person	name
		biography
		
		list	name
		description
	
	.PARAMETER Query
		Search Query that you will use to search
	
	.EXAMPLE
		PS C:\> Search-TraktMediaTextQuery -Type "movie" -Query "tron"
	
	.NOTES
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Search-TraktMediaTextQuery
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateSet('movie', 'show', 'episode', 'person', 'list')]
		[string]$Type,
		[Parameter(Mandatory = $true)]
		[string]$Query
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
		
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$URI = "https://api.trakt.tv/search/" + $Type + "?query=" + $Query
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		Lookup items by their Trakt, IMDB, TMDB, or TVDB ID.
		If you use the search url without a type it might return multiple items if the id_type is not globally unique.
		Specify the type of results by sending a single value or a comma delimited string for multiple types.
	
	.DESCRIPTION
		ID lookups are helpful if you have an external ID and want to get the Trakt ID and info.
		These methods can search for movies, shows, episodes, people, and lists.
	
	.PARAMETER Type
		Type	URL
		trakt	/search/trakt/:id
		/search/trakt/:id?type=movie
		/search/trakt/:id?type=show
		/search/trakt/:id?type=episode
		/search/trakt/:id?type=person
		imdb	/search/imdb/:id
		tmdb	/search/tmdb/:id
		/search/tmdb/:id?type=movie
		/search/tmdb/:id?type=show
		/search/tmdb/:id?type=episode
		/search/tmdb/:id?type=person
		tvdb	/search/tvdb/:id
		/search/tvdb/:id?type=show
		/search/tvdb/:id?type=episode
	
	.PARAMETER ID
		To use the ID Refer to exemples in Type parameter
		ex: /search/tmdb/:id?type=movie
		the ID will equal : 320288?type=movie
		Search-TraktMediaIdLookup -Type tmdb -ID "320288?type=movie"
	
	.NOTES
		Additional information about the function.
	
	.EXAMPLE 1
		PS C:\> Search-TraktMediaIdLookup -Type imdb -ID "tt0848228"
	
	.EXAMPLE 2
		PS C:\> Search-TraktMediaIdLookup -Type tmdb -ID "320288?type=movie"
#>
function Search-TraktMediaIdLookup
{
	[CmdletBinding(DefaultParameterSetName = 'imdb')]
	param
	(
		[ValidateSet('imdb', 'trakt', 'tvdb', 'tmdb')]
		[string]$Type = 'imdb',
		[Parameter(Mandatory = $true)]
		[string]$MediaID
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true)
	{
		$ClientId = $global:ClientID
		
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$URI = "https://api.trakt.tv/search/" + $Type + "/" + $MediaID
	$headers = @{ }
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		Get Lists of particular user
	
	.DESCRIPTION
		Get Lists of particular user
	
	.PARAMETER user
		The user Name of the list you want to check
	
	.PARAMETER AuthToken
		A description of the AuthToken parameter.
	
	.EXAMPLE
		PS C:\> Get-TraktUserCustomLists -User 'Value1'
	
	.NOTES
		You Need to First Use Set-TraktAuthInfo function before you can use this function.
		Everything is Based on https://trakt.docs.apiary.io/#
#>
function Get-TraktUserCustomLists
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$user,
		[string]$AuthToken
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true -and [string]::IsNullOrEmpty($Global:AccessToken) -ne $true -and [string]::IsNullOrEmpty($global:Username) -ne $true)
	{
		$ClientId = $global:ClientID
		$AccessToken = $Global:AccessToken
		$user = $global:Username
		
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		if ($XMLInfo.SelectSingleNode("TraktInfo/TraktAuth"))
		{
			$AccessTokenImport = $XMLInfo.TraktInfo.TraktAuth.AccessToken
			$AccessToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($AccessTokenImport))
			$user = $XMLInfo.TraktInfo.TraktAuth.Username
			
		}
		elseif ([string]::IsNullOrEmpty($AuthToken) -ne $true)
		{
			$AccessToken = $AuthToken
		}
		else
		{
			Write-Error "Please use Use the Access Token Param or Use the Save Param in Connect-Trakt Function"
			break
		}
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$headers = @{ }
	$headers.Add("Authorization", "Bearer $AccessToken") | Out-Null
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientId) | Out-Null
	$URI = "https://api.trakt.tv/users/" + $user + "/lists"
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		A brief description of the Get-TraktUserSettings function.
	
	.DESCRIPTION
		Everything is Based on https://trakt.docs.apiary.io/#
	
	.EXAMPLE
		PS C:\> Get-TraktUserSettings
	
	.NOTES
		Additional information about the function.
		
#>
function Get-TraktUserSettings
{
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true -and [string]::IsNullOrEmpty($Global:AccessToken) -ne $true)
	{
		$ClientId = $global:ClientID
		$AccessToken = $Global:AccessToken
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		if ($XMLInfo.SelectSingleNode("TraktInfo/TraktAuth"))
		{
			$AccessTokenImport = $XMLInfo.TraktInfo.TraktAuth.AccessToken
			$AccessToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($AccessTokenImport))
			
		}
		elseif ([string]::IsNullOrEmpty($AuthToken) -ne $true)
		{
			$AccessToken = $AuthToken
		}
		else
		{
			Write-Error "Please use Use the Access Token Param or Use the Save Param in Connect-Trakt Function"
			break
		}
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	$headers = @{ }
	$headers.Add("Authorization", "Bearer $AccessToken") | Out-Null
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientID) | Out-Null
	$invoke = Invoke-WebRequest -Uri "https://api.trakt.tv/users/settings" -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value.user
}

<#
	.SYNOPSIS
		Get Items in Specific List
	
	.DESCRIPTION
		A detailed description of the Get-TraktUserListItems function.
	
	.PARAMETER list
		Name of the list you want to get items from
	
	.EXAMPLE
		PS C:\> Get-TraktUserListItems -list "Custom WatchList"
	
	.NOTES
		Additional information about the function.
#>
function Get-TraktUserListItems
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$list
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true -and [string]::IsNullOrEmpty($Global:AccessToken) -ne $true -and [string]::IsNullOrEmpty($global:Username) -ne $true)
	{
		$AccessTokenImport = $Global:AccessToken
		$ClientId = $global:ClientID
		$user = $global:Username
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		if ($XMLInfo.SelectSingleNode("TraktInfo/TraktAuth"))
		{
			$AccessTokenImport = $XMLInfo.TraktInfo.TraktAuth.AccessToken
			$AccessToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($AccessTokenImport))
			$user = $XMLInfo.TraktInfo.TraktAuth.Username
			
		}
		elseif ([string]::IsNullOrEmpty($AuthToken) -ne $true)
		{
			$AccessToken = $AuthToken
		}
		else
		{
			Write-Error "Please Connect-Trakt Function"
			break
		}
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	$listFixed = $list -replace ' ', '-'
	$headers = @{ }
	$headers.Add("Authorization", "Bearer $AccessToken") | Out-Null
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientID) | Out-Null
	$URI = "https://api.trakt.tv/users/" + $User + "/lists/" + $listFixed + "/items"
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		Use to Remove items to specific lists.
	
	.DESCRIPTION
		Use to Remove items to specific lists.
	
	.PARAMETER list
		Name of the list you want to get items from
	
	.PARAMETER BodyObj
		Need to By in Json Format or use Set-TraktObjet Function
{
    "movies": [
        {
            "ids": {
                "tmdb": "320288"
            }
        }
    ]
}
"@
	.PARAMETER AuthToken
		This is the authToken outputed by Function Connect-Trakt.
		Is not needed if save option is used with Connect-Trakt.
	
	.NOTES
		Additional information about the function.
	
	.EXAMPLE 1
		PS C:\> Remove-TraktUserListItem -list "New Shows Watchlist" -BodyObj @"
{
    "movies": [
        {
            "ids": {
                "tmdb": "320288"
            }
        }
    ]
}
"@
	.EXAMPLE 2
		PS C:\> $TraktObj = Set-TraktObject -MediaType movies -IdType tmdb -MediaID "479455"
		PS C:\> Remove-TraktUserListItem -list "New Shows Watchlist" -BodyObj $TraktObj
#>
function Remove-TraktUserListItem
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$list,
		[Parameter(Mandatory = $true)]
		[array]$BodyObj
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true -and [string]::IsNullOrEmpty($Global:AccessToken) -ne $true -and [string]::IsNullOrEmpty($global:Username) -ne $true)
	{
		$AccessTokenImport = $Global:AccessToken
		$ClientId = $global:ClientID
		$user = $global:Username
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientId = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		if ($XMLInfo.SelectSingleNode("TraktInfo/TraktAuth"))
		{
			$AccessTokenImport = $XMLInfo.TraktInfo.TraktAuth.AccessToken
			$AccessToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($AccessTokenImport))
			$user = $XMLInfo.TraktInfo.TraktAuth.Username
			
		}
		elseif ([string]::IsNullOrEmpty($AuthToken) -ne $true)
		{
			$AccessToken = $AuthToken
		}
		else
		{
			Write-Error "Please use Use the Access Token Param or Use the Save Param in Connect-Trakt Function"
			break
		}
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	$listFixed = $list -replace ' ', '-'
	$headers = @{ }
	$headers.Add("Authorization", "Bearer $AccessToken") | Out-Null
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientID) | Out-Null
	
	$body = $BodyObj
	
	$URI = "https://api.trakt.tv/users/" + $User + "/lists/" + $listFixed + "/items/remove"
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers -Method Post -Body $body
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}

<#
	.SYNOPSIS
		Use to Add items to specific lists.
	
	.DESCRIPTION
		Use to Add items to specific lists.
	
	.PARAMETER AuthToken
		This is the authToken outputed by Function Connect-Trakt.
		Is not needed if save option is used with Connect-Trakt.
	
	.PARAMETER User
		UserName for the user you want to lookup.
		Normally will only work with your own username.
	
	.PARAMETER list
		Name of the list you want to get items from
	
	.PARAMETER BodyObj
		Need to By in Json Format
		Need to By in Json Format or use Set-TraktObjet Function
		{
		    "movies": [
		        {
		            "ids": {
		                "tmdb": "320288"
		            }
		        }
		    ]
		}
	
	.EXAMPLE 1 
				PS C:\> Add-TraktUserListItem -list "New Shows Watchlist" -BodyObj @"
{
    "movies": [
        {
            "ids": {
                "tmdb": "320288"
            }
        }
    ]
}
"@

	.EXAMPLE 2
				PS C:\> $TraktObj = Set-TraktObject -MediaType movies -IdType tmdb -MediaID "479455"
				PS C:\> Add-TraktUserListItem -list "New Shows Watchlist" -BodyObj $TraktObj
	
	.NOTES
		Additional information about the function.
#>
function Add-TraktUserListItem
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$AccessToken,
		[Parameter(Mandatory = $false)]
		[string]$User,
		[Parameter(Mandatory = $true)]
		[string]$list,
		[Parameter(Mandatory = $true)]
		[array]$BodyObj
	)
	
	if ([string]::IsNullOrEmpty($global:ClientID) -ne $true -and [string]::IsNullOrEmpty($Global:AccessToken) -ne $true -and [string]::IsNullOrEmpty($global:Username) -ne $true)
	{
		$AccessTokenImport = $Global:AccessToken
		$ClientId = $global:ClientID
		$user = $global:Username
	}
	elseif (Test-Path -Path "$env:APPDATA\TraktInfo.xml")
	{
		[XML]$XMLInfo = Get-Content -Path "$env:APPDATA\TraktInfo.xml"
		$ClienIDImport = $XMLInfo.TraktInfo.ClientID
		$ClientID = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($ClienIDImport))
		if ($XMLInfo.SelectSingleNode("TraktInfo/TraktAuth"))
		{
			$AccessTokenImport = $XMLInfo.TraktInfo.TraktAuth.AccessToken
			$AccessToken = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($AccessTokenImport))
			$user = $XMLInfo.TraktInfo.TraktAuth.Username
			
		}
		elseif ([string]::IsNullOrEmpty($AuthToken) -ne $true)
		{
			$AccessToken = $AuthToken
		}
		else
		{
			Write-Error "Please use Use the Access Token Param or Use the Save Param in Connect-Trakt Function"
			break
		}
	}
	else
	{
		Write-Error "Please use Set-TraktAuthInfo Function First"
		break
	}
	
	$listFixed = $list -replace ' ', '-'
	$headers = @{ }
	$headers.Add("Authorization", "Bearer $AccessToken") | Out-Null
	$headers.Add("trakt-api-version", "2") | out-null
	$headers.Add("trakt-api-key", $ClientID) | Out-Null
	
	$body = $BodyObj
	$URI = "https://api.trakt.tv/users/" + $User + "/lists/" + $listFixed + "/items"
	$invoke = Invoke-WebRequest -Uri $URI -ContentType application/json -Headers $headers -Method Post -Body $body
	$Value = $invoke.content | ConvertFrom-Json
	$Value
}
