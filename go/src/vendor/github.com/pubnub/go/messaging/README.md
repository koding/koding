## Contact support@pubnub.com for all questions

#PubNub 3.6 client for Go 1.0.3, 1.1, 1.3, 1.3.1, 1.4.2

###Important changes in this version:
The package name has been modified to "messaging" from "pubnubMessaging". 

###Change log
* 3.6.3
 * PAM operations (grant, revoke, audit) now return 403 errors in the Error Callback
* SetLogging method name changed to LoggingEnabled
* SetLogOutput added, you can customize the log output now 
* Support to change uuid
* 3.6 features 
 * HereNow with state (here now's signature has changed, the response has also changed)
 * WhereNow
 * Global Here Now
 * User State (Set, Get, Delete)
 * Presence heartbeat 
 * Presence heartbeat interval

* These are converted to uint16
 * nonSubscribeTimeout
 * retryInterval
 * connectTimeout
 * subscribeTimeout

* Optimizations


###Earlier Features

* Supports multiplexing, UUID, SSL, Encryption, Proxy, and godoc
* This version is not backward compatible. The major change is in the func calls. A new parameter "error callback" is added to the major functions of the pubnub class.
* The client now supports:
* Error Callback: All the error messages are routed to this callback channel
* Resume on reconnect
* You can now "Subscribe with timetoken"
* An example of Disconnect/Retry has been added in the example 
* Multiple messages received in a single response from the server will now be split into individual messages
* Non 200 response will now be bubbled to the client
* PAM: To use the PAM features in the example please enable PAM from the Pubnub admin console (https://admin.pubnub.com) and replace the publish, subscribe and secret keys in example/pubnubExample.go (line 124).

###Quick Start Video

We've put together a quick HOWTO video here http://vimeo.com/93523019

###Get Package

* Use the command `go get github.com/pubnub/go/messaging` to download and install the package

###Run the example
* Built using Eclipse IDE (juno) 
* Install golang plugin for Eclipse
* Using Eclipse Project Explorer browse to the directory `$GOPATH/src/github.com/pubnub/go/messaging/example`, where `$GOPATH` is the workspaces directory of go.
* Run `pubnubExample.go` as a "go application"
* Look for the application in the "Console" of the Eclipse IDE

###Running Unit tests (instructions for Mac/Linux, for other dev environments the instructions are similar)

* Open Terminal.
* Change the directory to 
`<eclipse-workspace>/src/github.com/pubnub/go/messaging/tests.`
* Run the command `go test -i` to install the packages. 
* And then run the command `go test` to run test cases.

###Use pubnub in your project

* Install golang plugin for Eclipse.
* Use the command go get github.com/pubnub/go/messaging to download and install the package.
* Open terminal/command prompt. Browse to the directory ` $GOPATH/src/github.com/pubnub/go/messaging/ `
* Run the command `go install`.
* Go to eclipse and create a new "go project". Enter the project name.
* Create a new "go file" in the "src" directory of the new project. For this example choose the "Command Source File" under the "Source File Type" with "Empty Main Function".
* Click Finish
* On this file in eclipse.
* Under import add the 2 lines

```go
import (
    // Other imports...
    "fmt"
    "github.com/pubnub/go/messaging"
)
```

* And under main add the following line

```go
fmt.Println("PubNub Api for go;", messaging.VersionInfo())
```

* Run the example as a "go application"
* This application will print the version info of the PubNub Api.
* For the detailed usage of the PunNub API, please refer to the rest of the ReadMe or the pubnubExample.go file under ` $GOPATH/src/github.com/pubnub/go/messaging/example `


In addition to Eclipse, this has also been tested with Go 1.0.3 on Linux using IntelliJ IDEA 12.

###Demo Console App
We've included a demo console app which documents all the functionality of the client, for example:

* Subscribe
* Subscribe with timetoken
* Publish
* Presence
* Detailed History
* Here_Now
* Unsubscribe
* Presence-Unsubscribe
* Time
* Disconnect/Retry
* GrantSubscribe
* RevokeSubscribe
* AuditSubscribe
* GrantPresence
* RevokePresence
* AuditPresence
* SetAuthKey
* GetAuthKey
* Exit
* Set Presence Heartbeat
* Set Presence Heartbeat Interval
* Set User State by adding or modifying the Key-Pair
* Delete an existing Key-Pair
* Set User State with JSON string
* Get User State
* WhereNow
* GlobalHereNow
* Change UUID 

###Quick Implementation Examples

#### handleSubscribeResult

This function is a utility function used in the examples below to handle the Subscribe/Presence response. You will want to adapt it to your own needs.

```go
func handleSubscribeResult(successChannel, errorChannel chan []byte, action string) {
    for {
        select {
        case success, ok := <-successChannel:
            if !ok {
				break
			}
			if string(success) != "[]" {
				fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))
				fmt.Println("")
			}
        case failure, ok := <-errorChannel:
            if !ok {
				break
			}
            if string(failure) != "[]" {
				if displayError {
					fmt.Println(fmt.Sprintf("%s Error Callback: %s", action, failure))
					fmt.Println("")
				}
			}
        }
    }
}
```

#### handleResult

This function is a utility function used in the examples below to handle the non Subscribe/Presence response. You will want to adapt it to your own needs.

```go
func handleResult(successChannel, errorChannel chan []byte, timeoutVal int64, action string) {
    timeout := make(chan bool, 1)
	go func() {
		time.Sleep(time.Duration(timeoutVal) * time.Second)
		timeout <- true
	}()
    for {
        select {
        case success, ok := <-successChannel:
            if !ok {
				break
			}
			if string(success) != "[]" {
				fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))
				fmt.Println("")
			}
            return
        case failure, ok := <-errorChannel:
            if !ok {
				break
			}
            if string(failure) != "[]" {
				if displayError {
					fmt.Println(fmt.Sprintf("%s Error Callback: %s", action, failure))
					fmt.Println("")
				}
			}
            return
        case <-timeout:
            fmt.Println(fmt.Sprintf("%s Handler timeout after %d secs", action, timeoutVal))
			fmt.Println("")            
            return
        }
    }
}
```

#### Init

Initialize a new Pubnub instance.

```go
        pubInstance := messaging.NewPubnub(<YOUR PUBLISH KEY>, <YOUR SUBSCRIBE KEY>, <SECRET KEY>, <CIPHER>, <SSL ON/OFF>, <UUID>)
```

#### Publish

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var callbackChannel = make(chan []byte)
        go pubInstance.Publish(<pubnub channel>, <message to publish>, callbackChannel, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")
        // please goto the top of this file see the implementation of handleResult
```

#### Subscribe

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var subscribeChannel = make(chan []byte)
        go pubInstance.Subscribe(<pubnub channels, multiple channels can be separated by comma>, <timetoken, should be an empty string in this case>, subscribeChannel, <this field is FALSE for subscribe requests>, errorChannel)
        go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
        // please goto the top of this file see the implementation of handleSubscribeResult
```

#### Subscribe with timetoken

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var subscribeChannel = make(chan []byte)
        go pubInstance.Subscribe(<pubnub channel, multiple channels can be separated by comma>, <timetoken to init the request with>, subscribeChannel, <this field is FALSE for subscribe requests>, errorChannel)
        go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
        // please goto the top of this file see the implementation of handleSubscribeResult
```

#### Presence

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var presenceChannel = make(chan []byte)
        go pubInstance.Subscribe(<pubnub channel, multiple channels can be separated by comma>, <timetoken, should be an empty string in this case>, presenceChannel, <this field is TRUE for subscribe requests>, errorChannel)
        go handleSubscribeResult(presenceChannel, errorChannel, "Presence")  
        // please goto the top of this file see the implementation of handleSubscribeResult
```

#### Detailed History

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.History(<pubnub channel>, <no of items to fetch>, <start time>, <end time>, false, channelCallback, errorChannel)
        //example: go _pub.History(<pubnub channel>, 100, 0, 0, false, channelCallback, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History") 
        // please goto the top of this file see the implementation of handleResult
```

#### Here_Now

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.HereNow(<pubnub channel>, showUuid, includeUserState, channelCallback, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "HereNow")
        // please goto the top of this file see the implementation of handleResult
```

####  Unsubscribe

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.Unsubscribe(<pubnub channels, multiple channels can be separated by comma>, channelCallback, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Unsubscribe")
        // please goto the top of this file see the implementation of handleResult
```

#### Presence-Unsubscribe

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.PresenceUnsubscribe(<pubnub channels, multiple channels can be separated by comma>, channelCallback, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "UnsubscribePresence")
        // please goto the top of this file see the implementation of handleResult
```

#### Time

```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var channelCallback = make(chan []byte)
        go pubInstance.GetTime(channelCallback, errorChannel)
        go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Time")
        // please goto the top of this file see the implementation of handleResult
```

#### Disconnect/Retry
```go
        //Init pubnub instance

        pubInstance.CloseExistingConnection() 
```

#### GrantSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.GrantSubscribe(<pubnub channels>, true, true, 60, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Susbcribe Grant")
        // please goto the top of this file see the implementation of handleResult
```

#### RevokeSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.GrantSubscribe(<pubnub channels>, false, false, -1, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke Subscribe")
        // please goto the top of this file see the implementation of handleResult
```

#### AuditSubscribe
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.AuditSubscribe(<pubnub channels>, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Subscribe")
        // please goto the top of this file see the implementation of handleResult
```

#### GrantPresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.GrantPresence(<pubnub channels>, true, true, 60, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Presence Grant")
        // please goto the top of this file see the implementation of handleResult
```

#### RevokePresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.GrantPresence(<pubnub channels>, false, false, -1, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Revoke presence")
        // please goto the top of this file see the implementation of handleResult
```

#### AuditPresence
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var pamChannel = make(chan []byte)
        go pub.AuditPresence(<pubnub channels>, pamChannel, errorChannel)
        go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit Presence")
        // please goto the top of this file see the implementation of handleResult
```

#### SetAuthKey
```go
        //Init pubnub instance

        pub.SetAuthenticationKey("authkey")
```

#### GetAuthKey
```go
        //Init pubnub instance

        fmt.Println(pub.GetAuthenticationKey())
```

#### Set Presence Heartbeat
```go
        //Init pubnub instance

        pub.SetPresenceHeartbeat(<presenceHeartbeat>)
```

#### Set Presence Heartbeat Interval
```go
        //Init pubnub instance

        pub.SetPresenceHeartbeatInterval(<presenceHeartbeatInterval>)
```

#### Set User State using Key-Pair
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.SetUserStateKeyVal(<pubnub channel>, <key>, <val>, successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Delete User State
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.SetUserStateKeyVal(<pubnub channel>, <key>, "", successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Del User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Set User State using JSON
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.SetUserStateJSON(<pubnub channel>, <jsonString>, successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State JSON")
        // please goto the top of this file see the implementation of handleResult
```

#### Get User State
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.GetUserState(<pubnub channel>, successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Get User State")
        // please goto the top of this file see the implementation of handleResult
```

#### Where Now
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.WhereNow(<uuid>, successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "WhereNow")

	// please goto the top of this file see the implementation of handleResult
```

#### Global Here Now
```go
        //Init pubnub instance

        var errorChannel = make(chan []byte)
        var successChannel = make(chan []byte)
        go pub.GlobalHereNow(showUuid, includeUserState, successChannel, errorChannel)
        go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Global here now")

	// please goto the top of this file see the implementation of handleResult
```

#### Change UUID
```go
        //Init pubnub instance

        pub.SetUUID(<uuid>)
```

#### Exit

```go
        //Init pubnub instance

        pubInstance.Abort()  
```


## Contact support@pubnub.com for all questions
