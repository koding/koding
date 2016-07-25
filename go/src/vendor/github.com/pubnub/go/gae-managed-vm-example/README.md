#PubNub 3.6 example Google App Engine Managed VM using Go

###Demo Console App (Tested for Managed VMs on Google Cloud SDK 0.9.68)
We've included a demo console app which documents all the functionality of the client, for example:

* Publish
* Detailed History
* Here_Now
* Time
* GrantSubscribe
* RevokeSubscribe
* AuditSubscribe
* GrantPresence
* RevokePresence
* AuditPresence
* SetAuthKey
* GetAuthKey
* Set User State by adding or modifying the Key-Pair
* Delete an existing Key-Pair
* Set User State with JSON string
* Get User State
* WhereNow
* GlobalHereNow
* Subscribe/Presence/Unsubscribe using PubNub Javascript SDK

###Run the example
* Built using Eclipse IDE (Luna).
* Install golang plugin for Eclipse.
* Install Google Cloud SDK for Go. Follow the steps from here (https://cloud.google.com/appengine/docs/managed-vms/getting-started)
* Run the following command from within a termina' `export GAE_LOCAL_VM_RUNTIME=1`
* Run the PubNub GAE example using GO on the dev app server using the command `gcloud --verbosity debug preview app run app.yaml`
from inside the `<Path-to-PubNub-GAE-Folder>`
* Run http://localhost:8080.

###Using pubnub in your project and Quick Implementation Examples
* Please see [gae](../gae)


