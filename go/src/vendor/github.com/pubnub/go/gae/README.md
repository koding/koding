## Contact support@pubnub.com for all questions

#PubNub 3.9.5 client for Google App Engine SDK (1.9.28 - 2015-10-29) using Go

### Features
* 3.9.5
 * Fix use of escaping JSON during publish
 * Prefix uuid with 'pn-'
* 3.9.4.3
 * Changed origin to ps.pndsn.com
* 3.9.4.1
 * fixed misspells, some golint changes and gocyclo issues
* 3.9.4
 * Fire Method
 * Replicate arg in Publish
* 3.9.3
 * Fixed storeInHistory when publishing
* 3.7.0 changes
 * Add authKey argument to all PAM methods
 * Add Channel Group Methods
 * Add PublishExtended() method that extends existing Publish() with 2 bool options: storeInHistory and doNotSerialize
 * Fix multiple channels encoding in PAM methods
* 3.6.3 changes
 * GAE and Managed VM use the same code now.
 * PAM operations (grant, revoke, audit) now return 403 errors in the Error Callback
* 3.6.1 changes
 * Modified to work with the the app engine run on Managed VMs (https://github.com/golang/appengine)
* 3.6 features 
 * HereNow with state (here now's signature has changed, the response has also changed)
 * WhereNow
 * Global Here Now
 * User State (Set, Get, Delete)
 * Presence heartbeat 
 * Presence heartbeat interval
* PAM: To use the PAM features in the example please enable PAM from the Pubnub admin console (https://admin.pubnub.com) and replace the publish, subscribe and secret keys in the example.
* Multiple messages received in a single response from the server will now be split into individual messages
* Non 200 response will now be bubbled to the client
* Error Callback: All the error messages are routed to this callback channel
* Subscribe/Presence is under development for GO App engine. In the example we have demonstarted Subscribe and Presence using the PubNub JavaScript SDK

###Get Code

* Clone the PubNub Go repo using `git clone https://github.com/pubnub/go.git`

###Example
* For GAE example please see [gae-example](../gae-example)
* For Managed VM example please see [gae-managed-vm-example](../gae-managed-vm-example)

###Running Unit tests (instructions for Mac/Linux, for other dev environments the instructions are similar)

* Open Terminal.
* Make sure that `<go-workspace>/github.com/pubnub/go/gae/messaging` is in the GOPATH.
* Change the directory to 
`<Path-to-PubNub-GAE-Folder>github.com/pubnub/go/gae/tests`
* Run the command `goapp test`. 

###Use pubnub in your project
* Built using Eclipse IDE (Luna).
* Install golang plugin for Eclipse.
* Insatll Google App Engine SDK for Go.
* Clone https://github.com/pubnub/go.git
* Create a new folder for your project.
* Import `github.com/pubnub/go/gae/messaging` in your project.

```go
import (
    // Other imports...
    "github.com/pubnub/go/gae/messaging"
)
```

* For the detailed usage of the PunNub API, please refer to the rest of the ReadMe 
* The SDK has a dependency on Gorilla web toolkit, for sessions (http://www.gorillatoolkit.org). You need to download Gorilla web toolkit from the git repo using `go get github.com/gorilla/sessions` and copy it to `github.com/gorilla/sessions` in your project maintaining the folder structure

###Quick Implementation Examples

#### handleResult

This function is a utility function used in the examples below to handle the non Subscribe/Presence response. You will want to adapt it to your own needs.

```go
func handleResult(c context.Context, w http.ResponseWriter, r *http.Request, uuid string, successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	for {
		select {

		case success, ok := <-successChannel:
			if !ok {
				c.Infof("success!OK")
				break
			}
			if string(success) != "[]" {
				c.Infof("success:", string(success))
				sendResponseToChannel(w, string(success), r, uuid)
			}

			return
		case failure, ok := <-errorChannel:
			if !ok {
				c.Infof("fail1:", string("failure"))
				break
			}
			if string(failure) != "[]" {
				c.Infof("fail:", string(failure))
				sendResponseToChannel(w, string(failure), r, uuid)
			}
			return
		}
	}
}
```

#### Init

Initialize a new Pubnub instance.

```go
        pubInstance := messaging.New(<AppEngine context>, <UUID>, <http.ResponseWriter>, <*http.Request>, <YOUR PUBLISH KEY>, <YOUR SUBSCRIBE KEY>, <SECRET KEY>, <CIPHER>, <SSL ON/OFF>, )
```

#### Publish

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var callbackChannel = make(chan []byte)
        go pubInstance.Publish(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, <message to publish>, callbackChannel, errorChannel)

        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")

        // please goto the top of this file see the implementation of handleResult
```

#### PublishExtended

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var callbackChannel = make(chan []byte)
        go pubInstance.PublishExtended(<AppEngine context>, <http.ResponseWriter>, <*http.Request>,
        	<pubnub channel>, <message to publish>, <storeInHistory bool>, <doNotSerialize bool>,
        	callbackChannel, errorChannel)

        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>,
        	callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "PublishExtended")

        // please goto the top of this file see the implementation of handleResult
```

#### Detailed History

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.History(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, <no of items to fetch>, <start time>, <end time>, <Reverse>, channelCallback, errorChannel)
        //example: go _pub.History(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, 100, 0, 0, false, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History")
        // please goto the top of this file see the implementation of handleResult
```

#### Here_Now

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.HereNow(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, disableUUID, includeUserState, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "HereNow")
        // please goto the top of this file see the implementation of handleResult
```

#### Time

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GetTime(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Time")
        // please goto the top of this file see the implementation of handleResult
```

#### GrantSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantSubscribe(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, true, true, 60, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Grant Susbcribe")
        // please goto the top of this file see the implementation of handleResult
```

#### RevokeSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantSubscribe(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, false, false, 1, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Susbcribe")
        // please goto the top of this file see the implementation of handleResult
```

#### AuditSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pub.AuditSubscribe(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Subscribe")
        // please goto the top of this file see the implementation of handleResult
```

#### GrantPresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantPresence(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, true, true, 60, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Grant Presence")
        // please goto the top of this file see the implementation of handleResult
```

#### RevokePresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantPresence(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, false, false, 1, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Presence")

        // please goto the top of this file see the implementation of handleResult
```

#### AuditPresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pub.AuditPresence(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channels>, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Presence")
        // please goto the top of this file see the implementation of handleResult
```

#### GrantChannelGroup
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantChannelGroup(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel groups>, true, true, 60, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Grant Channel Group")
        // please goto the top of this file see the implementation of handleResult
```

#### RevokeChannelGroup
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GrantChannelGroup(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel groups>, false, false, 1, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Channel Group")

        // please goto the top of this file see the implementation of handleResult
```

#### AuditChannelGroup
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pub.AuditChannelGroup(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel groups>, <authKey>, channelCallback, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, channelCallback, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Channel Group")
        // please goto the top of this file see the implementation of handleResult
```

#### SetAuthKey
```go
        //Init pubnub instance

        pubInstance.SetAuthenticationKey(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, authKey)
```

#### GetAuthKey
```go
        //Init pubnub instance

        pubInstance.GetAuthenticationKey()
```

#### Set User State using Key-Pair
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pubInstance.SetUserStateKeyVal(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, <key>, <val>, successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Delete User State
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pubInstance.SetUserStateKeyVal(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, <key>, "", successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Del User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Set User State using JSON
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pubInstance.SetUserStateJSON(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, <jsonString>, successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State JSON")

        // please goto the top of this file see the implementation of handleResult
```

#### Get User State
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)

        go pubInstance.GetUserState(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <pubnub channel>, successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Get User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Where Now
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pubInstance.WhereNow(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, whereNowUUID, successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "WhereNow")
        // please goto the top of this file see the implementation of handleResult
```

#### Global Here Now
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pubInstance.GlobalHereNow(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, disableUUID, includeUserState, successChannel, errorChannel)
        handleResult(<AppEngine context>, <http.ResponseWriter>, <*http.Request>, <UUID>, successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Global Here Now")

        // please goto the top of this file see the implementation of handleResult
```


## Contact support@pubnub.com for all questions
