Function Authenticate-ToYammer
{
    # https://github.com/bittercoder/DevDefined.OAuth

    $clientID = ""
    $clientSecret = ""
    $redirect = "http://www.yammer.com"  #http://yourappurl/auth/yammer/callback

    $ConsumerKey = $clientID
    $ConsumerSecret = $clientSecret

    #Add-Type -Path $JammerPath\DevDefined.OAuth.dll #change path to the location where you have downloaded the oAuth dll.
    #Add-Type -Path $JammerPath\DevDefined.OAuth2.dll #downloaded 2015/01/16 from http://www.leporelo.eu/blog.aspx?id=how-to-use-oauth-to-connect-to-twitter-in-powershell#download-131 - updated for PIN
    Add-Type -Path DevDefined.OAuth3.dll #compiled 2015/01/16 from https://github.com/bittercoder/DevDefined.OAuth
    $cons = New-Object devdefined.oauth.consumer.oauthconsumercontext

    $cons.ConsumerKey = $ConsumerKey
    $cons.ConsumerSecret = $ConsumerSecret
    $cons.SignatureMethod = [devdefined.oauth.framework.signaturemethod]::HmacSha1

    $Global:session = new-object DevDefined.OAuth.Consumer.OAuthSession $cons,
    "https://www.yammer.com/oauth/request_token",
    "https://www.yammer.com/oauth/authorize",
    "https://www.yammer.com/oauth/access_token"

    #Create Request Token.
    $requestToken = $session.GetRequestToken()

    #Authorization URL. The authorization URL is where your application redirects to, to allow the user to grant or deny you access to the their data.
    $userAuthorizationURLForToken = $session.GetUserAuthorizationUrlForToken($requestToken, 'wedonthaveone')

    #Open Browser for PIN
    Start-Process $userAuthorizationURLForToken

    $pin = read-host -prompt 'Enter 4 digit PIN you see in in Yammer URL after clicking Authorize'

    #Once the user is back at your app, you use the request token and pin to generate the access token
    $Global:accessToken = $session.ExchangeRequestTokenForAccessToken($requestToken, $pin) 

    Write-Verbose "Yammer Authentication finished"
}

$VerbosePreference = "Continue"
$groupsExportfile = "D:\YammerGroupExport.csv"
$usersExportfile = "D:\YammerUserExport.csv"

Function Export-YammerGroups
{
     #show all the groups
      $page=1
      do
      {
          $YammerParameter = "page=$page"
          $req = $session.Request($accessToken)
          $req.Context.RequestMethod = 'GET'
          $req.Context.RawUri = [Uri]"https://www.yammer.com/api/v1/groups.json?$YammerParameter"
          $groups = $req | convertfrom-json -ErrorAction SilentlyContinue
          #$groups | select full_name, description, id
          $groups | select @{L="Groupname";E={$_.Name}}, Id, Description, Privacy, created_at, state, web_url, @{L="Number_of_Members"; E={($_ | select -ExpandProperty Stats).Members}},@{L="Last_Message_at"; E={($_ | select -ExpandProperty Stats).last_message_at}},@{L="number_of_updates"; E={($_ | select -ExpandProperty Stats).updates}} | Export-Csv -Append -LiteralPath $groupsExportFile
          Start-Sleep 1 #slow it down to prevent processing errors i was seeing
          $page++
          Write-Verbose "Retrieving Page $page"
      }
      while($groups -ne $null)
}

Function Export-YammerUsers
{
      $page=1
      do
      {
          $YammerParameter = "page=$page" 
          $req = $session.Request($accessToken)
          $req.Context.RequestMethod = 'GET'
          $req.Context.RawUri = [Uri]"https://www.yammer.com/api/v1/users.json?$YammerParameter"
          $users = $req | convertfrom-json -ErrorAction SilentlyContinue
          $users |  %{ $_ | Export-Csv -Append -LiteralPath $usersExportfile}
          Start-Sleep 1 #slow it down to prevent processing errors i was seeing
          $page++
          Write-Verbose "Retrieving Page $page"
      }
      while($users -ne $null)
}


