<#
    Ref:  http://wiki.servicenow.com/index.php?title=Table_API
#>

New-Variable -Name INCIDENT_URI -Value 'api/now/v1/table/incident' -Option Constant

Function Invoke-TableApiRequest
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][ValidateSet('Put','Post','Get','Patch')][string]$httpMethod,
        [Parameter(Mandatory=$False)][hashtable]$requestHash
    )

    
    $headers = @{'Content-Type' = 'application/json';'Accept' = 'application/json'}

    # Use the .Net JavaScript serializer, the default PowerShell implementation limits return size
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $javaScriptSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $javaScriptSerializer.MaxJsonLength = [int]::MaxValue
    $javaScriptSerializer.RecursionLimit = 99

    # Make a request to the web service
    if($requestHash -ne $null)
    {
        $requestBody =  ConvertTo-Json($requestHash) -Depth 10
        $resp = Invoke-WebRequest -Method $httpMethod -Uri $uri -Body $requestBody -TimeoutSec 480 -DisableKeepAlive:$True -UseBasicParsing -Headers $headers -Credential $credential
    }
    else
    {
        $resp = Invoke-WebRequest -Method $httpMethod -Uri $uri -TimeoutSec 480 -DisableKeepAlive:$True -UseBasicParsing -Headers $headers -Credential $credential
    }

    # Deserialize the content, it will either a Dictionary or array of Dictionary
    $result = $javaScriptSerializer.DeserializeObject($resp.Content)

    # Return PSObjects from the result for convenience
    foreach ($thisResult in $result.result)
    {
        $thisObject = New-Object -Type PSObject -Property $thisResult
        
        # put the object on the pipline
        $thisObject
    }
}

Function Get-ServiceNowIncident
{
    [CmdletBinding()]
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
    Invoke-TableApiRequest -credential $credential -uri $fullUri -httpMethod Get
}

Function New-ServiceNowIncident
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][string]$assignmentGroup,
        [Parameter(Mandatory=$True)][string]$shortDescription,
        [Parameter(Mandatory=$True)][string]$cmdbCI,
        [Parameter(Mandatory=$True)][string]$category,
        [Parameter(Mandatory=$True)][string]$comments,
        [Parameter(Mandatory=$True)][string]$contactType
    )

    # Build the URI
    $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true"
    $fullUri = "$uri$requestUri"

    # Crease HashTable for request body (content of the incident)
    $requestHash = @{
        'assignment_group' = $assignmentGroup;
        'cmdb_ci' = $cmdbCI;
        'category' = $category;
        'short_description' = $shortDescription;
        'comments' = $comments;
        'contact_type' = $contactType;
        }

    # Send the request
    Invoke-TableApiRequest -credential $credential -uri $fullUri -httpMethod Post -requestHash $requestHash
}

Function Update-ServiceNowIncident
{
    [CmdletBinding()]
    Param()
}

Function Get-ServiceNowCI
{
    [CmdletBinding()]
    Param()
}

Function Get-ServiceNowUser
{
    [CmdletBinding()]
    Param()
}

Function Get-ServiceNowAssignmentGroup
{
    [CmdletBinding()]
    Param()
}

Export-ModuleMember *