<#
    Ref:  http://wiki.servicenow.com/index.php?title=Table_API
#>

Add-Type -TypeDefinition @"
   public enum HTTP_METHOD
   {
      GET,
      PUT,
      POST,
      PATCH,
      DELETE
   }
"@

New-Variable -Name INCIDENT_URI -Value 'api/now/v1/table/incident' -Option Constant

Function Invoke-TableApiRequest
{
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][HTTP_METHOD]$httpMethod,
        [Parameter(Mandatory=$False)][hashtable]$requestHash
    )

    
    $headers = @{'Content-Type' = 'application/json';'Accept' = 'application/json'}

    # Let's use the .Net JavaScript serializer, the default PowerShell implementation limits return size
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $javaScriptSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $javaScriptSerializer.MaxJsonLength = [int]::MaxValue
    $javaScriptSerializer.RecursionLimit = 99

    # Make our request to the web service
    if($requestHash -ne $null)
    {
        $requestBody =  @{data=ConvertTo-Json($requestHash) -Depth 10}
        $resp = Invoke-WebRequest -Method $httpMethod -Uri $uri -Body $requestBody -TimeoutSec 480 -DisableKeepAlive:$True -UseBasicParsing -Headers $headers -Credential $credential
    }
    else
    {
        $resp = Invoke-WebRequest -Method $httpMethod -Uri $uri -TimeoutSec 480 -DisableKeepAlive:$True -UseBasicParsing -Headers $headers -Credential $credential
    }

    # Deserialize the request into a PowerShell object
    $result = $javaScriptSerializer.DeserializeObject($resp.Content)

    # Looks like we have at least one object to return, let's create a PSObject because it's easier to enum
    foreach ($thisResult in $result.result)
    {
        $thisObject = New-Object -Type PSObject -Property $thisResult
        
        # put the object on the pipline
        $thisObject
    }
}

Function Get-ServiceNowIncident
{
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$False)][string]$incidentNumber
    )

    # build the requestUri
    if(![String]::IsNullOrEmpty($incidentNumber))
    {
        $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true&sysparm_fields=&sysparm_query=number=$($incidentNumber.Trim())"
    }
    else
    {
        $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true&sysparm_fields="
    }

    $fullUri = "$uri$requestUri"

    # send the request
    Invoke-TableApiRequest -credential $credential -uri $fullUri -httpMethod GET
}

Export-ModuleMember *