#PubNub 3.11.0 example Google App Engine Managed VM using Go

###Demo Console App (Tested for Managed VMs on Google Cloud SDK 133.0.0)
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
* Install Google Cloud SDK for Go. Follow the steps from here (https://cloud.google.com/appengine/docs/managed-vms/getting-started)
* From inside the `<Path-to-PubNub-gae-managed-vm-example>` run the command `go run *.go`
Run the following command from within a termina' `export GAE_LOCAL_VM_RUNTIME=1`
* In the browser run http://localhost:8080.

###Integration in your project
To integrate in your project you need to import the package `github.com/pubnub/go/messaging`
