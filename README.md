posh-servicenow
=========

PowerShell wrapper for ServiceNow requests

###### Requirements:

- ServiceNow Table API access

###### Usage:

```
Import-Module posh-servicenow
```

```
$credential = Get-Credential
Get-ServiceNowIncident -credential $credential -uri 'https://someinstance.servicenow.com' -incidentNumber 'abc123'
```




