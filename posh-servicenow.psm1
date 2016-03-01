<#
    Ref:  http://wiki.servicenow.com/index.php?title=Table_API
#>

New-Variable -Name INCIDENT_URI -Value 'api/now/v1/table/incident' -Option Constant
New-Variable -Name USER_URI -Value 'api/now/v1/table/sys_user' -Option Constant

# Private function to handle all API communication, not exported
Function invokeTableApiRequest
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][ValidateSet('Put','Post','Get','Patch')][string]$httpMethod,
        [Parameter(Mandatory=$False)][hashtable]$requestHash
    )

    PROCESS
    {
        Write-Verbose "Invoking Table API request with method $httpMethod"
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
}

Function Get-ServiceNowIncident
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$False)][string]$incidentNumber
    )

    PROCESS
    {
        # build the requestUri
        if(![String]::IsNullOrEmpty($incidentNumber))
        {
            $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true&sysparm_query=number=$($incidentNumber.Trim())"
        }
        else
        {
            $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true"
        }

        $fullUri = "$uri$requestUri"
        Write-Verbose "Full URI is $fullUri"

        # send the request
        invokeTableApiRequest -credential $credential -uri $fullUri -httpMethod Get
    }
}

Function Get-ServiceNowUser
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][string]$email
    )

    PROCESS
    {
        # build the requestUri
        if(![String]::IsNullOrEmpty($email))
        {
            $requestUri = "$USER_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true&sysparm_query=email=$($email.Trim())"
        }
        else
        {
            $requestUri = "$USER_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true"
        }
        $fullUri = "$uri$requestUri"
        Write-Verbose "Full URI is $fullUri"

        # send the request
        invokeTableApiRequest -credential $credential -uri $fullUri -httpMethod Get
    }
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
        [Parameter(Mandatory=$True)][string]$contactType,
        [Parameter(Mandatory=$False)][string]$userId
    )

    PROCESS
    {
        # Build the URI
        $requestUri = "$INCIDENT_URI`?&sysparm_exclude_reference_link=true&sysparm_display_value=true"
        $fullUri = "$uri$requestUri"
        Write-Verbose "Full URI is $fullUri"

        # Crease HashTable for request body (content of the incident)

        $requestHash = @{
            'assignment_group' = $assignmentGroup;
            'cmdb_ci' = $cmdbCI;
            'category' = $category;
            'short_description' = $shortDescription;
            'comments' = $comments;
            'contact_type' = $contactType;
            }
        if($PSBoundParameters.ContainsKey('userId'))
        {
            $requestHash.Add('caller_id',$userId)
        }

        # Dump the hash
        Write-Verbose "Request body is $(ConvertTo-Json $requestHash)"

        # Send the request
        invokeTableApiRequest -credential $credential -uri $fullUri -httpMethod Post -requestHash $requestHash
    }
}

Function Update-ServiceNowIncident
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri,
        [Parameter(Mandatory=$True)][string]$incidentID,
        [Parameter(Mandatory=$False)][string]$assignmentGroup,
        [Parameter(Mandatory=$False)][string]$cmdbCI,
        [Parameter(Mandatory=$False)][string]$category,
        [Parameter(Mandatory=$False)][string]$comments,
        [Parameter(Mandatory=$False)][string]$contactType,
        [Parameter(Mandatory=$False)][string]$userId
    )

    PROCESS
    {
        # Build the URI
        $requestUri = "$INCIDENT_URI/$incidentID`?&sysparm_exclude_reference_link=true&sysparm_display_value=true"
        $fullUri = "$uri$requestUri"
        Write-Verbose "Full URI is $fullUri"

        # Crease HashTable for request body (content of the incident)

        $requestHash = @{}
        if($PSBoundParameters.ContainsKey('userId'))
        {
            $requestHash.Add('caller_id',$userId)
            Write-Verbose "Adding caller_id $userID to hash"
        }

        if($PSBoundParameters.ContainsKey('assignmentGroup'))
        {
            $requestHash.Add('assignment_group',$assignmentGroup)
            Write-Verbose "Adding assignment_group $assignmentGroup to hash"
        }
        
        if($PSBoundParameters.ContainsKey('cmdbCI'))
        {
            $requestHash.Add('cmdb_ci',$cmdbCI)
            Write-Verbose "Adding cmdb_ci $cmdbCI to hash"
        }
        
        if($PSBoundParameters.ContainsKey('category'))
        {
            $requestHash.Add('category',$category)
            Write-Verbose "Adding category $category to hash"
        }
        
        if($PSBoundParameters.ContainsKey('comments'))
        {
            $requestHash.Add('comments',$comments)
            Write-Verbose "Adding comments $comments to hash"
        }
        
        if($PSBoundParameters.ContainsKey('contactType'))
        {
            $requestHash.Add('contact_type',$contactType)
            Write-Verbose "Adding contact_type $contactType to hash"
        }

        # Dump the hash
        Write-Verbose "Request body is $(ConvertTo-Json $requestHash)"

        # Send the request
        invokeTableApiRequest -credential $credential -uri $fullUri -httpMethod Patch -requestHash $requestHash
    }
}

Function Get-ServiceNowCI
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri
    )

    PROCESS
    {
        throw "Not implemented"
    }
}

Function Get-ServiceNowAssignmentGroup
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)][PSCredential]$credential,
        [Parameter(Mandatory=$True)][string]$uri
    )

    PROCESS
    {
        throw "Not implemented"
    }

}

Export-ModuleMember *-*