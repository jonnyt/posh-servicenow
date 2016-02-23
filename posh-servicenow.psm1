<#
    Ref:  http://wiki.servicenow.com/index.php?title=Table_API
#>

New-Variable -Name INCIDENT_URI -Value 'api/now/v1/table/incident' -Option Constant

Function Invoke-TableApiRequest
{
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][hashtable]$requestHash
    )

    # Add headers here, request hash will have required data for GET, PUT, PATCH etc
    $headers = @{'Content-Type' = 'application/json';'Accept' = 'application/json'}

    if($requestHash -ne $null)
    {
        $requestBody =  @{
                auth="($($credential.UserName),$($credential.Password))";
                data=ConvertTo-Json($requestHash) -Depth 10
        }
    }
    else
    {
        $requestBody =  @{auth="($($credential.UserName),$($credential.Password))"}
    }

    # Let's use the .Net JavaScript serializer, the default PowerShell implementation limits return size
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $javaScriptSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $javaScriptSerializer.MaxJsonLength = [int]::MaxValue
    $javaScriptSerializer.RecursionLimit = 99

    # Make our request to the web service
    $resp = Invoke-WebRequest -Method Post -Uri $uri -Body $requestBody -TimeoutSec 480 -DisableKeepAlive:$True -UseBasicParsing -Headers $headers

    # Deserialize the request into a PowerShell object
    $result = $javaScriptSerializer.DeserializeObject($resp.Content)

    # Do something with the result
    
    # Stick the result on the pipeline
    $result
}

Function Get-ServiceNowIncident
{
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][string]$incidentNumber
    )

    # build the requestUri
    $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true&sysparm_fields=&sysparm_query=number=$($incidentNumber.Trim())"

    # send the request
    $result = Invoke-TableApiRequest -credential $credential -uri $uri -requestHash $null


}

Export-ModuleMember *