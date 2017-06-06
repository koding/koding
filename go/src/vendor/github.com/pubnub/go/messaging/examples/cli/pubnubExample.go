// Package main provides the example implemetation to connect to pubnub api.
// Runs on the console.
package main

import (
	"bufio"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"github.com/pubnub/go/messaging"
	"log"
	"math/big"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
	"unicode/utf16"
	"unicode/utf8"
)

// connectChannels: the connected pubnub channels, multiple channels are stored separated by comma.
var connectChannels = ""

// ssl: true if the ssl is enabled else false.
var ssl bool

// cipher: stores the cipher key set by the user.
var cipher = ""

// uuid stores the custom uuid set by the user.
var uuid = ""

//
var publishKey = "demo"

//
var subscribeKey = "demo"

//
var secretKey = ""

// a boolean to capture user preference of displaying errors.
var displayError = true

// pub instance of messaging package.
var pub *messaging.Pubnub

// main method to initiate the application in the console.
// Calls the init method to read user input. And starts the read loop to parse user input.
func main() {
	b := Init()
	if b {
		ReadLoop()
	}
	fmt.Println("Exit")
}

// Init asks the user the basic settings to initialize to the pubnub struct.
// Settings include the pubnub channel(s) to connect to.
// Ssl settings
// Cipher key
// Secret Key
// Custom Uuid
// Proxy details
//
// The method returns false if the channel name is not provided.
//
// returns: a bool, true if the user completed the initail settings.
func Init() (b bool) {
	fmt.Println("")
	fmt.Println(messaging.VersionInfo())
	fmt.Println("")
	fmt.Println("Please enter the channel name(s). Enter multiple channels separated by comma without spaces.")
	reader := bufio.NewReader(os.Stdin)

	line, _, err := reader.ReadLine()
	if err != nil {
		fmt.Println(err)
	} else {
		connectChannels = string(line)

		if len(strings.TrimSpace(connectChannels)) == 0 {
			connectChannels = "test"
		}
		fmt.Println("Channel: ", connectChannels)
		fmt.Println("Enable SSL? Enter n for No, y for Yes")
		var enableSsl string
		fmt.Scanln(&enableSsl)

		if enableSsl == "n" || enableSsl == "N" {
			ssl = false
			fmt.Println("SSL disabled")
		} else {
			ssl = true
			fmt.Println("SSL enabled")
		}

		fmt.Println("Please enter a subscribe key, leave blank for default key.")
		fmt.Scanln(&subscribeKey)

		if strings.TrimSpace(subscribeKey) == "" {
			subscribeKey = "demo"
		}
		fmt.Println("Subscribe Key: ", subscribeKey)
		fmt.Println("")

		fmt.Println("Please enter a publish key, leave blank for default key.")
		fmt.Scanln(&publishKey)
		if strings.TrimSpace(publishKey) == "" {
			publishKey = "demo"
		}
		fmt.Println("Publish Key: ", publishKey)
		fmt.Println("")

		fmt.Println("Please enter a secret key, leave blank for default key.")
		fmt.Scanln(&secretKey)
		if strings.TrimSpace(secretKey) == "" {
			//secretKey = "demo"
		}
		fmt.Println("Secret Key: ", secretKey)
		fmt.Println("")

		fmt.Println("Please enter a CIPHER key, leave blank if you don't want to use this.")
		fmt.Scanln(&cipher)
		fmt.Println("Cipher: ", cipher)

		fmt.Println("Please enter a Custom UUID, leave blank for default.")
		fmt.Scanln(&uuid)
		fmt.Println("UUID: ", uuid)

		fmt.Println("Display error messages? Enter y for Yes, n for No. Default is Yes")
		var enableErrorMessages = "y"
		fmt.Scanln(&enableErrorMessages)

		if enableErrorMessages == "y" || enableErrorMessages == "Y" {
			displayError = true
			fmt.Println("Error messages will be displayed")
		} else {
			displayError = false
			fmt.Println("Error messages will not be displayed")
		}

		fmt.Println("Enable resume on reconnect? Enter y for Yes, n for No. Default is Yes")
		var enableResumeOnReconnect = "y"
		fmt.Scanln(&enableResumeOnReconnect)

		if enableResumeOnReconnect == "y" || enableResumeOnReconnect == "Y" {
			messaging.SetResumeOnReconnect(true)
			fmt.Println("Resume on reconnect enabled")
		} else {
			messaging.SetResumeOnReconnect(false)
			fmt.Println("Resume on reconnect disabled")
		}

		fmt.Println("Set subscribe timeout? Enter numerals.")
		var subscribeTimeout = ""
		fmt.Scanln(&subscribeTimeout)
		val, err := strconv.Atoi(subscribeTimeout)
		if err != nil {
			fmt.Println("Entered value is invalid. Using default value.")
		} else {
			messaging.SetSubscribeTimeout(uint16(val))
		}

		fmt.Println("Enable logging? Enter y for Yes, n for No. Default is Yes")
		var enableLogging = "y"
		fmt.Scanln(&enableLogging)

		var infoLogger *log.Logger

		if enableLogging == "y" || enableLogging == "Y" {
			logfileName := "pubnubMessaging.log"
			f, err := os.OpenFile(logfileName, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
			if err != nil {

				fmt.Println("error opening file: ", err.Error())
				fmt.Println("Logging disabled")
			} else {
				fmt.Println("Logging enabled writing to ", logfileName)
				infoLogger = log.New(f, "", log.Ldate|log.Ltime|log.Lshortfile)
			}
		} else {
			fmt.Println("Logging disabled")
		}

		//messaging.SetOrigin("balancer-tj71.devbuild.aws-pdx-1.ps.pn")
		messaging.SetOrigin("ps.pndsn.com")

		var pubInstance = messaging.NewPubnub(publishKey, subscribeKey, secretKey, cipher, ssl, uuid, infoLogger)

		pub = pubInstance

		SetupProxy()

		presenceHeartbeat := askNumber16("Presence Heartbeat", true)
		pub.SetPresenceHeartbeat(presenceHeartbeat)
		fmt.Println(fmt.Sprintf("Presence Heartbeat set to :%d", pub.GetPresenceHeartbeat()))

		presenceHeartbeatInterval := askNumber16("Presence Heartbeat Interval", true)
		pub.SetPresenceHeartbeat(presenceHeartbeatInterval)
		fmt.Println(fmt.Sprintf("Presence Heartbeat set to :%d", pub.GetPresenceHeartbeat()))

		fmt.Println("Pubnub instance initialized")

		return true
		//}
		//fmt.Println("Channel cannot be empty.")
	}
	return false
}

// SetupProxy asks the user the Proxy details and calls the SetProxy of the messaging
// package with the details.
func SetupProxy() {
	fmt.Println("Using Proxy? Enter y to setup.")
	var enableProxy string
	fmt.Scanln(&enableProxy)

	if enableProxy == "y" || enableProxy == "Y" {
		proxyServer := askServer()
		proxyPort := askPort()
		proxyUser := askUser()
		proxyPassword := askPassword()

		messaging.SetProxy(proxyServer, proxyPort, proxyUser, proxyPassword)

		fmt.Println("Proxy sever set")
	} else {
		fmt.Println("Proxy not used")
	}
}

// AskServer asks the user to enter the proxy server name or IP.
// It validates the input and returns the value if validated.
func askServer() string {
	var proxyServer string

	fmt.Println("Enter proxy servername or IP.")
	fmt.Scanln(&proxyServer)

	if strings.TrimSpace(proxyServer) == "" {
		fmt.Println("Proxy servername or IP is empty.")
		askServer()
	}
	return proxyServer
}

// AskPort asks the user to enter the proxy port number.
// It validates the input and returns the value if validated.
func askPort() int {
	var proxyPort string

	fmt.Println("Enter proxy port.")
	fmt.Scanln(&proxyPort)

	port, err := strconv.Atoi(proxyPort)
	if (err != nil) || ((port <= 0) || (port > 65536)) {
		fmt.Println("Proxy port is invalid.")
		askPort()
	}
	return port
}

// AskUser asks the user to enter the proxy username.
// returns the value, can be empty.
func askUser() string {
	var proxyUser string

	fmt.Println("Enter proxy username (optional)")
	fmt.Scanln(&proxyUser)

	return proxyUser
}

// AskPassword asks the user to enter the proxy password.
// returns the value, can be empty.
func askPassword() string {
	var proxyPassword string

	fmt.Println("Enter proxy password (optional)")
	fmt.Scanln(&proxyPassword)

	return proxyPassword
}

// AskOneChannel asks the user to channel name.
// If the channel(s) are not provided the channel(s) provided by the user
// at the beginning will be used.
// returns the read channel(s), or error
func askOneChannel() (string, error) {
	fmt.Println("Please enter a channel name.")
	reader := bufio.NewReader(os.Stdin)
	channels, _, errReadingChannel := reader.ReadLine()
	if errReadingChannel != nil {
		fmt.Println("Error channel: ", errReadingChannel.Error())
		return "", errReadingChannel
	}
	if strings.TrimSpace(string(channels)) == "" {
		fmt.Print("Channel empty. ")
		return askOneChannel()
	}
	return string(channels), nil
}

// AskChannel asks the user to channel name.
// If the channel(s) are not provided the channel(s) provided by the user
// at the beginning will be used.
// returns the read channel(s), or error
func askChannel() (string, error) {
	fmt.Println("Please enter the channel name. Leave empty to use the channel(s) provided at the beginning.")
	reader := bufio.NewReader(os.Stdin)
	channels, _, errReadingChannel := reader.ReadLine()
	if errReadingChannel != nil {
		fmt.Println("Error channel(s): ", errReadingChannel.Error())
		return "", errReadingChannel
	}
	if strings.TrimSpace(string(channels)) == "" {
		fmt.Println("Using channel(s): ", connectChannels)
		return connectChannels, nil
	}
	return string(channels), nil
}

// AskChannel asks the user to channel name.
// If the channel(s) are not provided the channel(s) provided by the user
// at the beginning will be used.
// returns the read channel(s), or error
func askChannelOptional() (string, error) {
	fmt.Println("Do you want to use the channels entered in the beginning, enter 'y' for yes. Default is no")
	var enableRead = "n"
	fmt.Scanln(&enableRead)

	if enableRead == "y" || enableRead == "Y" {
		fmt.Println("Using channel(s): ", connectChannels)
		return connectChannels, nil
	}

	fmt.Println("Please enter the channel name. You can leave it blank.")
	reader := bufio.NewReader(os.Stdin)
	channels, _, errReadingChannel := reader.ReadLine()
	if errReadingChannel != nil {
		fmt.Println("Error channel: ", errReadingChannel.Error())
		return "", errReadingChannel
	}
	return string(channels), nil
}

// AskChannelGroup asks the user for a channel group name.
// If the channel group(s) are not provided an error will be returned
// returns the read channel(s), or error
func askChannelGroup() (string, error) {
	fmt.Println("Please enter the channel group name.")
	reader := bufio.NewReader(os.Stdin)
	channelGroups, _, errReadingChannel := reader.ReadLine()

	if errReadingChannel != nil {
		fmt.Println("Error channel group: ", errReadingChannel.Error())
		return "", errReadingChannel
	} else if string(channelGroups) == "" {
		return "", fmt.Errorf("Channel Group cannot be an empty string")
	} else {
		return string(channelGroups), nil
	}
}

// askChannelGroupOptional asks the user for a channel group name.
// If the channel group(s) are not provided an empty string will be returned
// returns the read channel(s), or error
func askChannelGroupOptional() (string, error) {
	fmt.Println("Please enter the channel group name. You can leave it blank.")
	reader := bufio.NewReader(os.Stdin)
	channelGroups, _, errReadingChannel := reader.ReadLine()

	if errReadingChannel != nil {
		fmt.Println("Error channel group: ", errReadingChannel.Error())
		return "", errReadingChannel
	}
	return string(channelGroups), nil
}

func askQuestionBool(what string, defaultYes bool) bool {
	enable := "n"
	if defaultYes {
		enable = "y"
	}

	fmt.Println(fmt.Sprintf("%s? Enter y for Yes, n for No. Default is %s", what, enable))
	fmt.Scanln(&enable)

	if enable == "y" || enable == "Y" {
		return true
	}
	return false
}

// askNumber
//
func askNumber(what string) int64 {
	var input string

	fmt.Println("Enter " + what)
	fmt.Scanln(&input)

	//val, err := strconv.(input, 10, 32)
	bi := big.NewInt(0)
	if _, ok := bi.SetString(input, 10); !ok {
		//if (err != nil) {
		fmt.Println(what + " is invalid. Please enter numerals.")
		return askNumber(what)
	}
	fmt.Println(bi.Int64())
	return bi.Int64()
}

// askNumber
//
func askNumber16(what string, optional bool) uint16 {
	var input string

	if optional {
		fmt.Println("Enter " + what + " (optional)")
	} else {
		fmt.Println("Enter " + what)
	}
	fmt.Scanln(&input)
	if (optional) && (strings.TrimSpace(input) == "") {
		input = "0"
	}

	/*reader := bufio.NewReader(os.Stdin)
	input, _, errReadingChannel := reader.ReadLine()
	if errReadingChannel != nil {
		fmt.Println("Error: ", errReadingChannel.Error())
		return 0
	}
	input1 := string(input)
	if (optional) && (strings.TrimSpace(input1) == ""){
		input1 = "0"
	}

	//return string(channels), nil

	/*bi := big.NewInt(0)
	if _, ok := bi.SetString(input, 10); !ok {
		//if (err != nil) {
		fmt.Println(what + " is invalid. Please enter numerals.")
		return askNumber16(what, optional)
	}*/

	val, err := strconv.Atoi(strings.TrimSpace(input))
	//fmt.Println("Input " + input)
	if err != nil {
		fmt.Println(what + " is invalid. Please enter numerals.")
		return askNumber16(what, optional)
	}

	return uint16(val)
}

// askString
//
func askString(what string, optional bool) string {
	var input string

	if optional {
		fmt.Println("Enter " + what + " (optional)")
	} else {
		fmt.Println("Enter " + what)
	}
	fmt.Scanln(&input)
	if (!optional) && (strings.TrimSpace(input) == "") {
		fmt.Println(what + " is empty.")
		return askString(what, optional)
	}
	return input
}

// askOtherPamInputs asks the user for read and write access
// and the ttl values
// returns read, write and ttl
func askOtherPamInputs() (bool, bool, int) {
	var read, write bool
	var ttl int

	fmt.Println("Read access, enter 'y' for yes, default is no")
	var enableRead = "n"
	fmt.Scanln(&enableRead)

	if enableRead == "y" || enableRead == "Y" {
		read = true
	} else {
		read = false
	}

	fmt.Println("Write access, enter 'y' for yes, default is no")
	var enableWrite = "n"
	fmt.Scanln(&enableWrite)

	if enableWrite == "y" || enableWrite == "Y" {
		write = true
	} else {
		write = false
	}

	var input string

	fmt.Println("Enter TTL in minutes. Default = 1440 minutes (24 hours)")
	fmt.Scanln(&input)

	if ival, err := strconv.Atoi(input); err == nil {
		ttl = ival
	} else {
		ttl = 1440
	}

	return read, write, ttl

}

// askOtherPamCGInputs asks the user for read and manage access
// and the ttl values on channel group
// returns read, manage and ttl
func askOtherPamCGInputs() (bool, bool, string, int) {
	var read, manage bool
	var ttl int

	var authKey = askString("authentication key", true)

	fmt.Println("Read access, enter 'y' for yes, default is no")
	var enableRead = "n"
	fmt.Scanln(&enableRead)

	if enableRead == "y" || enableRead == "Y" {
		read = true
	} else {
		read = false
	}

	fmt.Println("Manage access, enter 'y' for yes, default is no")
	var enableManage = "n"
	fmt.Scanln(&enableManage)

	if enableManage == "y" || enableManage == "Y" {
		manage = true
	} else {
		manage = false
	}

	var input string

	fmt.Println("Enter TTL in minutes. Default = 1440 minutes (24 hours)")
	fmt.Scanln(&input)

	if ival, err := strconv.Atoi(input); err == nil {
		ttl = ival
	} else {
		ttl = 1440
	}

	return read, manage, authKey, ttl
}

// UTF16BytesToString converts UTF-16 encoded bytes, in big or little endian byte order,
// to a UTF-8 encoded string.
func utf16BytesToString(b []byte, o binary.ByteOrder) string {
	utf := make([]uint16, (len(b)+(2-1))/2)
	for i := 0; i+(2-1) < len(b); i += 2 {
		utf[i/2] = o.Uint16(b[i:])
	}
	if len(b)/2 < len(utf) {
		utf[len(utf)-1] = utf8.RuneError
	}
	return string(utf16.Decode(utf))
}

// ReadLoop starts an infinite loop to read the user's input.
// Based on the input the respective go routine is called as a parallel process.
func ReadLoop() {
	showOptions := true
	reader := bufio.NewReader(os.Stdin)

	for {
		if showOptions {
			fmt.Println("")
			fmt.Println("ENTER 1 FOR Subscribe")
			fmt.Println("ENTER 2 FOR Subscribe with timetoken")
			fmt.Println("ENTER 3 FOR Publish")
			fmt.Println("ENTER 4 FOR Presence")
			fmt.Println("ENTER 5 FOR Detailed History")
			fmt.Println("ENTER 6 FOR Here_Now")
			fmt.Println("ENTER 7 FOR Unsubscribe")
			fmt.Println("ENTER 8 FOR Presence-Unsubscribe")
			fmt.Println("ENTER 9 FOR Time")
			fmt.Println("ENTER 10 TO Disconnect & Retry")
			fmt.Println("ENTER 11 TO GRANT Subscribe")
			fmt.Println("ENTER 12 TO REVOKE Subscribe")
			fmt.Println("ENTER 13 TO AUDIT Subscribe")
			fmt.Println("ENTER 14 TO GRANT Presence")
			fmt.Println("ENTER 15 TO REVOKE Presence")
			fmt.Println("ENTER 16 TO Audit Presence")
			fmt.Println("ENTER 17 TO GRANT Channel Group")
			fmt.Println("ENTER 18 TO REVOKE Channel Group")
			fmt.Println("ENTER 19 TO Audit Channel Group")
			fmt.Println("ENTER 20 TO SET Auth key")
			fmt.Println("ENTER 21 TO SHOW Auth key")
			fmt.Println(fmt.Sprintf("ENTER 22 TO SET Presence Heartbeat, current val: %d", pub.GetPresenceHeartbeat()))
			fmt.Println(fmt.Sprintf("ENTER 23 TO SET Presence Heartbeat Interval, current val:%d", pub.GetPresenceHeartbeatInterval()))
			fmt.Println("ENTER 24 TO SET User State by adding or modifying the Key-Pair")
			fmt.Println("ENTER 25 TO DELETE an existing Key-Pair")
			fmt.Println("ENTER 26 TO SET User State with JSON string")
			fmt.Println("ENTER 27 TO GET User State")
			fmt.Println("ENTER 28 FOR WhereNow")
			fmt.Println("ENTER 29 FOR GlobalHereNow")
			fmt.Println("ENTER 30 TO CHANGE UUID (" + pub.GetUUID() + ")")
			fmt.Println("ENTER 31 TO Add Channel to Channel Group ")
			fmt.Println("ENTER 32 TO Remove Channel from Channel Group ")
			fmt.Println("ENTER 33 TO List Channel Group ")
			fmt.Println("ENTER 34 TO Remove Channel Group ")
			fmt.Println("ENTER 35 TO Set Filter Expression")
			fmt.Println("ENTER 36 TO Get Filter Expression")
			fmt.Println("ENTER 37 FOR Publish with Meta")
			fmt.Println("ENTER 38 FOR Publish with StoreInHistory")
			fmt.Println("ENTER 39 FOR Publish with replicate")
			fmt.Println("ENTER 40 FOR Fire")
			fmt.Println("ENTER 41 FOR Subscribe V2")
			fmt.Println("ENTER 42 FOR Subscribe Channel Group V2")
			fmt.Println("ENTER 43 FOR Subscribe Channel Group")
			fmt.Println("ENTER 44 FOR Publish with TTL")
			fmt.Println("ENTER 99 FOR Exit")
			fmt.Println("")
			showOptions = false
		}

		var action string
		fmt.Scanln(&action)

		breakOut := false
		switch action {
		case "1":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Subscribe")
				go subscribeRoutine(channels, "")
			}
		case "2":
			fmt.Println("Running Subscribe with timetoken")
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				timetoken := askNumber("Timetoken")
				go subscribeRoutine(channels, strconv.FormatInt(timetoken, 10))
			}
		case "111":
			//for test
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Subscribe2")
				go subscribeRoutine2(channels, "")
			}
		case "333":
			//for test
			fmt.Printf("goroutines start: %d\n", runtime.NumGoroutine())
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {

				go func() {
					for i := 0; i < 100; i++ {
						publishRoutine(channels, fmt.Sprintf("%d", i))
					}
				}()
			}
			fmt.Printf("goroutines end: %d\n", runtime.NumGoroutine())
		case "3333":
			//for test
			fmt.Printf("goroutines start: %d\n", runtime.NumGoroutine())
			channels, errReadingChannel := askChannel()

			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				nu := askNumber("number of messages to publish")
				go func() {
					for i := 0; i < int(nu); i++ {
						publishRoutine(channels, fmt.Sprintf("%d", i))
					}
				}()
			}
			fmt.Printf("goroutines end: %d\n", runtime.NumGoroutine())
		case "3":
			fmt.Printf("goroutines start: %d\n", runtime.NumGoroutine())
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()

				if err != nil {
					fmt.Println(err)
				} else {
					go publishRoutine(channels, string(message))
				}
				//go publishRoutine(channels, message)
			}
		case "4":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Presence")
				go presenceRoutine(channels)
			}
		case "444":
			//for test
			fmt.Println("Running Presence2")
			go presenceRoutine2()
		case "5":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running detailed history")
				go detailedHistoryRoutine(channels)
			}
		case "55":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running detailed history")
				go getAllMessages(0, channels)
			}
		case "6":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				showUuid := askQuestionBool("Show UUID list", true)
				includeUserState := askQuestionBool("Include user state", false)

				fmt.Println("Running here now")
				go hereNowRoutine(channels, showUuid, includeUserState)
			}
		case "7":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Unsubscribe")
				go unsubscribeRoutine(channels)
			}
		case "8":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Unsubscribe Presence")
				go unsubscribePresenceRoutine(channels)
			}
		case "9":
			fmt.Println("Running Time")
			go timeRoutine()
		case "10":
			fmt.Println("Disconnect/Retry")
			pub.CloseExistingConnection()
		case "11":
			fmt.Println("Running Grant Subscribe")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				read, write, ttl := askOtherPamInputs()
				go pamSubscribeRoutine(channels, read, write, ttl)
			}
		case "12":
			fmt.Println("Running Revoke Subscribe")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				go pamSubscribeRoutine(channels, false, false, -1)
			}
		case "13":
			fmt.Println("Running Subscribe Audit")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				go pamAuditRoutine(channels, false)
			}
		case "14":
			fmt.Println("Running Grant Presence")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				read, write, ttl := askOtherPamInputs()
				go pamPresenceRoutine(channels, read, write, ttl)
			}
		case "15":
			fmt.Println("Running Revoke Presence")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				go pamPresenceRoutine(channels, false, false, -1)
			}
		case "16":
			fmt.Println("Running Presence Audit")
			channels, errReadingChannel := askChannelOptional()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				go pamAuditRoutine(channels, true)
			}
		case "17":
			fmt.Println("Running Grant Channel Ggroup")
			groups, errReadingChannelGroup := askChannelGroupOptional()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
			} else {
				read, write, auth, ttl := askOtherPamCGInputs()
				go pamGrantChannelGroupRoutine(groups, auth, read, write, ttl)
			}
		case "18":
			fmt.Println("Running Revoke Channel Ggroup")
			groups, errReadingChannelGroup := askChannelGroupOptional()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
			} else {
				auth := askString("authentication key", true)
				go pamGrantChannelGroupRoutine(groups, auth, false, false, -1)
			}
		case "19":
			fmt.Println("Running Audit Channel Group")
			groups, errReadingChannelGroup := askChannelGroupOptional()
			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
			} else {
				auth := askString("authentication key", true)
				go pamAuditChannelGroupRoutine(groups, auth)
			}
		case "20":
			fmt.Println("Enter Auth Key. Use comma to enter multiple Auth Keys.")
			fmt.Println("If you don't want to use Auth Key, Press ENTER Key")
			reader := bufio.NewReader(os.Stdin)
			authKey, _, errReadingChannel := reader.ReadLine()
			if errReadingChannel != nil {
				fmt.Println("Error channel: ", errReadingChannel.Error())
			} else {
				fmt.Println("Setting Authentication Key")
				pub.SetAuthenticationKey(string(authKey))
				fmt.Println("Authentication Key Set")
			}
		case "21":
			fmt.Print("Authentication Key:")
			fmt.Println(pub.GetAuthenticationKey())
		case "22":
			presenceHeartbeat := askNumber16("Presence Heartbeat", false)
			pub.SetPresenceHeartbeat(presenceHeartbeat)
			fmt.Println(fmt.Sprintf("Presence Heartbeat set to :%d", pub.GetPresenceHeartbeat()))
		case "23":
			presenceHeartbeatInterval := askNumber16("Presence Heartbeat Interval", false)
			pub.SetPresenceHeartbeatInterval(presenceHeartbeatInterval)
			fmt.Println(fmt.Sprintf("Presence Heartbeat Interval set to :%d", pub.GetPresenceHeartbeatInterval()))
		case "24":
			channel, errReadingChannel := askOneChannel()

			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				key := askString("key", false)
				val := askString("val", false)
				fmt.Println("Setting User State")
				go setUserState(channel, key, val)
			}
		case "25":
			channel, errReadingChannel := askOneChannel()

			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				key := askString("User state key to delete", false)
				fmt.Println("Deleting User State")
				go delUserState(channel, key)
			}
		case "26":
			channel, errReadingChannel := askOneChannel()

			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				jsonString := askString("User state JSON", false)
				fmt.Println("Setting User State using JSON")
				go setUserStateJSON(channel, jsonString)
			}
		case "27":
			channel, errReadingChannel := askOneChannel()
			uuid := askString("UUID", true)

			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Get User State")
				go getUserState(channel, uuid)
			}
		case "28":
			uuid := askString("uuid", true)
			fmt.Println("Running Where now")
			go whereNowRoutine(uuid)
		case "29":
			showUuid := askQuestionBool("Show UUID list", true)
			includeUserState := askQuestionBool("Include user state", false)
			fmt.Println("Running Global here now")

			go globalHereNowRoutine(showUuid, includeUserState)
		case "30":
			uuid := askString("uuid", true)
			pub.SetUUID(uuid)
			fmt.Println("UUID set to " + pub.GetUUID())
		case "31":
			fmt.Println("Running Add Chanel to Channel Group")
			group, errReadingChannelGroup := askChannelGroup()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
				break
			}

			channels := askString("channel names separated by comma", false)
			go addChannelToChannelGroupRoutine(group, channels)
		case "32":
			fmt.Println("Running Remove Chanel from Channel Group")
			group, errReadingChannelGroup := askChannelGroup()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
				break
			}

			channels := askString("channel names separated by comma", false)
			go removeChannelFromChannelGroupRoutine(group, channels)
		case "33":
			fmt.Println("Listing a Channel Group")
			group, errReadingChannelGroup := askChannelGroup()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
			} else {
				go listChannelGroupRoutine(group)
			}
		case "34":
			fmt.Println("Remove a Channel Group")
			group, errReadingChannelGroup := askChannelGroup()

			if errReadingChannelGroup != nil {
				fmt.Println("errReadingChannelGroup: ", errReadingChannelGroup)
			} else {
				go removeChannelGroupRoutine(group)
			}
		case "35":
			fmt.Println("Set Filter Expression")
			filterExp := askString("Filter Expression", false)
			go pub.SetFilterExpression(filterExp)
		case "335":
			fmt.Println("Set preset Filter Expression")
			go pub.SetFilterExpression("(aoi_x >= 0 && aoi_x <= 2) && (aoi_y >= 0 && aoi_y <= 2)")
		case "36":
			fmt.Println("Get Filter Expression: ", pub.FilterExpression())
		case "37":
			channels, errReadingChannel := askChannel()
			nextStep := false
			msg := ""
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()
				if err != nil {
					fmt.Println(err)
				} else {
					nextStep = true
					msg = string(message)
				}
			}
			if nextStep {
				metaKey := askString("Meta Key", false)
				metaVal := askString("Meta Value", false)
				if strings.TrimSpace(metaKey) != "" && strings.TrimSpace(metaVal) != "" {
					meta := make(map[string]string)
					meta[metaKey] = metaVal
					go publishWithMetaRoutine(channels, msg, meta)
				}
			}
		case "337":
			channels, _ := askChannel()
			meta := make(map[string]int)
			meta["aoi_x"] = 1
			meta["aoi_y"] = 1
			go publishWithMetaRoutine(channels, "test", meta)
		case "338":
			channelGroups, errReadingChannelGrp := askChannelGroup()
			if errReadingChannelGrp != nil {
				fmt.Println("errReadingChannelGrp: ", errReadingChannelGrp)
			} else {
				fmt.Println("Running Subscribe for Channel Group")
				go subscribeChannelGroupRoutine(channelGroups, "")
			}
		case "38":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()

				if err != nil {
					fmt.Println(err)
				} else {
					fmt.Println("Store in history? Enter 'y' for yes or 'n' for no")
					var storeInHistory = "n"
					fmt.Scanln(&storeInHistory)
					storeInHistoryBool := false
					if storeInHistory == "Y" || storeInHistory == "y" {
						storeInHistoryBool = true
					}
					go publishRoutineStoreInHistory(channels, string(message), storeInHistoryBool)
				}
				//go publishRoutine(channels, message)
			}
		case "39":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()

				if err != nil {
					fmt.Println(err)
				} else {
					fmt.Println("Replicate? Enter 'y' for yes or 'n' for no")
					var replicate = "n"
					fmt.Scanln(&replicate)
					replicateBool := false
					if replicate == "Y" || replicate == "y" {
						replicateBool = true
					}
					go publishRoutineReplicate(channels, string(message), replicateBool)
				}
				//go publishRoutine(channels, message)
			}
		case "40":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()

				if err != nil {
					fmt.Println(err)
				} else {
					go fireRoutine(channels, string(message))
				}
				//go publishRoutine(channels, message)
			}
		case "41":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Subscribe")
				go subscribeRoutineV2(channels, "", "")
			}
		case "42":
			channels, errReadingChannel := askChannelGroup()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Subscribe")
				go subscribeRoutineV2("", channels, "")
			}
		case "43":
			channels, errReadingChannel := askChannelGroup()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Running Subscribe CG")
				go subscribeRoutineCG(channels, "")
			}
		case "44":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				fmt.Println("Please enter the message")
				message, _, err := reader.ReadLine()

				if err != nil {
					fmt.Println(err)
				} else {
					fmt.Println("Replicate? Enter 'y' for yes or 'n' for no")
					var replicate = "n"
					fmt.Scanln(&replicate)
					replicateBool := false
					if replicate == "Y" || replicate == "y" {
						replicateBool = true
					}
					fmt.Println("Enter TTL in minutes. Default = 10)")
					input := ""
					fmt.Scanln(&input)

					ttl := -1

					if ival, err := strconv.Atoi(input); err == nil {
						ttl = ival
					} else {
						ttl = 10
					}
					go publishRoutineReplicateWithTTL(channels, string(message), replicateBool, ttl)
				}
				//go publishRoutine(channels, message)
			}
		case "99":
			fmt.Println("Exiting")
			pub.Abort()
			time.Sleep(3 * time.Second)
			breakOut = true
		default:
			fmt.Println("Invalid choice!")
			showOptions = true
		}
		if breakOut {
			break
		} else {
			time.Sleep(1000 * time.Millisecond)
		}
	}
}

func getUserState(channel, uuid string) {
	var errorChannel = make(chan []byte)
	var successChannel = make(chan []byte)
	go pub.GetUserState(channel, uuid, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Get User State")
}

func setUserStateJSON(channel, jsonString string) {
	var errorChannel = make(chan []byte)
	var successChannel = make(chan []byte)
	go pub.SetUserStateJSON(channel, jsonString, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State JSON")
}

func setUserState(channel, key, val string) {
	var errorChannel = make(chan []byte)
	var successChannel = make(chan []byte)
	go pub.SetUserStateKeyVal(channel, key, val, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Set User State")
}

func delUserState(channel, key string) {
	var errorChannel = make(chan []byte)
	var successChannel = make(chan []byte)
	go pub.SetUserStateKeyVal(channel, key, "", successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Del User State")
}

// pamSubscribeRoutine calls the GrantSubscribe routine of the messaging package
// as a parallel process. This is used to grant or revoke the R, W permissions
// to revoke set read and write false and ttl as -1
func pamSubscribeRoutine(channels string, read bool, write bool, ttl int) {
	var errorChannel = make(chan []byte)
	var pamChannel = make(chan []byte)
	go pub.GrantSubscribe(channels, read, write, ttl, "", pamChannel, errorChannel)
	go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Subscribe Grant")
}

// pamPresenceRoutine calls the GrantPresence routine of the messaging package
// as a parallel process. This is used to grant or revoke the R, W permissions
// to revoke set read and write false and ttl as -1
func pamPresenceRoutine(channels string, read bool, write bool, ttl int) {
	var errorChannel = make(chan []byte)
	var pamChannel = make(chan []byte)
	go pub.GrantPresence(channels, read, write, ttl, "", pamChannel, errorChannel)
	go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Presence Grant")
}

// pamAuditRoutine calls the AuditPresence or AuditSubscribe routine of the messaging package
// as a parallel process.
func pamAuditRoutine(channels string, isPresence bool) {
	var errorChannel = make(chan []byte)
	var pamChannel = make(chan []byte)
	if isPresence {
		go pub.AuditPresence(channels, "", pamChannel, errorChannel)
	} else {
		go pub.AuditSubscribe(channels, "", pamChannel, errorChannel)
	}
	go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Audit")
}

func pamGrantChannelGroupRoutine(groups, auth string,
	read, manage bool, ttl int) {
	var errorChannel = make(chan []byte)
	var pamChannel = make(chan []byte)

	go pub.GrantChannelGroup(groups, read, manage, ttl, auth,
		pamChannel, errorChannel)
	go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(),
		"Channel Group Grant")
}

func pamAuditChannelGroupRoutine(groups, auth string) {
	var errorChannel = make(chan []byte)
	var pamChannel = make(chan []byte)

	go pub.AuditChannelGroup(groups, auth, pamChannel, errorChannel)
	go handleResult(pamChannel, errorChannel, messaging.GetNonSubscribeTimeout(),
		"Channel Group Audit")
}

// SubscribeChannelGroupRoutine calls the Subscribe routine of the messaging package
// as a parallel process.
func subscribeChannelGroupRoutine(channelGroups string, timetoken string) {
	var errorChannel = make(chan []byte)
	var subscribeChannel = make(chan []byte)
	go pub.ChannelGroupSubscribeWithTimetoken(channelGroups, timetoken, subscribeChannel, errorChannel)
	go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
}

// SubscribeRoutine calls the Subscribe routine of the messaging package
// as a parallel process.
func subscribeRoutine(channels string, timetoken string) {
	var errorChannel = make(chan []byte)
	var subscribeChannel = make(chan []byte)
	go pub.Subscribe(channels, timetoken, subscribeChannel, false, errorChannel)
	go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
}

// SubscribeRoutine calls the Subscribe routine of the messaging package
// as a parallel process.
func subscribeRoutineCG(cg string, timetoken string) {
	var errorChannel = make(chan []byte)
	var subscribeChannel = make(chan []byte)
	go pub.ChannelGroupSubscribe(cg, subscribeChannel, errorChannel)
	go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe")
}

func PrintInterfaceSlice(intf []interface{}, what string) {
	if len(intf) > 0 {
		for _, msg := range intf {
			fmt.Println(what, ":", msg)
		}
	}

}

// SubscribeRoutine calls the Subscribe routine of the messaging package
// as a parallel process.
func subscribeRoutineV2(channels string, channelGroups string, timetoken string) {
	var statusChannel = make(chan *messaging.PNStatus)
	var messageChannel = make(chan *messaging.PNMessageResult)
	var presenceChannel = make(chan *messaging.PNPresenceEventResult)
	go pub.SubscribeV2(channels, channelGroups, "", true, statusChannel, messageChannel, presenceChannel)
	for {
		select {
		case response := <-presenceChannel:
			fmt.Println("****** Presence response ******")
			fmt.Println("Channel:", response.Channel)
			fmt.Println("ChannelGroup:", response.ChannelGroup)
			fmt.Println("Event:", response.Event)
			fmt.Println("OriginatingTimetoken:", response.OriginatingTimetoken.Timetoken)
			fmt.Println("IssuingClientId:", string(response.IssuingClientId))
			fmt.Println("UserMetadata:", response.UserMetadata)
			fmt.Println("UUID:", response.UUID)
			fmt.Println("Timestamp:", response.Timestamp)
			fmt.Println("State:", response.State)
			fmt.Println("Occupancy:", response.Occupancy)

			PrintInterfaceSlice(response.Join, "Joined")
			PrintInterfaceSlice(response.Leave, "Left")
			PrintInterfaceSlice(response.Timeout, "TimedOut")

			fmt.Println("****** ******")
		case response := <-messageChannel:
			fmt.Println("****** Subscribe response ******")
			fmt.Println("Channel:", response.Channel)
			fmt.Println("ChannelGroup:", response.ChannelGroup)
			fmt.Println("Payload:", response.Payload)
			fmt.Println("OriginatingTimetoken:", response.OriginatingTimetoken.Timetoken)
			fmt.Println("PublishTimetokenMetadata:", response.PublishTimetokenMetadata.Timetoken)
			fmt.Println("IssuingClientId:", string(response.IssuingClientId))
			fmt.Println("UserMetadata:", response.UserMetadata)
			fmt.Println("****** ******")
		case err := <-statusChannel:
			if err.IsError {
				fmt.Println("Error:", err.ErrorData.Information)
				fmt.Println("Category:", err.Category)
				fmt.Println("AffectedChannels:", strings.Join(err.AffectedChannels, ","))
				fmt.Println("AffectedChannelGroups:", strings.Join(err.AffectedChannelGroups, ","))
			} else if err.Category == messaging.PNConnectedCategory {
				fmt.Println(fmt.Sprintf("Category: %d", err.Category))
				fmt.Println("AffectedChannels:", strings.Join(err.AffectedChannels, ","))
				fmt.Println("AffectedChannelGroups:", strings.Join(err.AffectedChannelGroups, ","))
			} else {
				fmt.Println("Category:", err.Category)
			}
		}
	}
}

// SubscribeRoutine calls the Subscribe routine of the messaging package
// as a parallel process.
func subscribeRoutine2(channels string, timetoken string) {
	var errorChannel = make(chan []byte)
	var subscribeChannel = make(chan []byte)
	go pub.Subscribe(channels, timetoken, subscribeChannel, false, errorChannel)
	go handleSubscribeResult(subscribeChannel, errorChannel, "Subscribe2")
}

// PublishRoutine asks the user the message to send to the pubnub channel(s) and
// calls the Publish routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the
// channel by comma and send the message on all the pubnub channels.
func publishWithMetaRoutine(channels, message string, meta interface{}) {
	var errorChannel = make(chan []byte)
	ch := strings.TrimSpace(channels)
	fmt.Println("Publish to channel: ", ch)
	callbackChannel := make(chan []byte)
	go pub.PublishExtendedWithMeta(ch, message, meta, true, false, callbackChannel, errorChannel)

	go handleResult(callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish with Meta")
}

func publishRoutineStoreInHistory(channels, message string, storeInHistory bool) {
	var errorChannel = make(chan []byte)
	ch := strings.TrimSpace(channels)
	fmt.Println("Publish to channel: ", ch)
	callbackChannel := make(chan []byte)
	go pub.PublishExtended(ch, message, storeInHistory, false, callbackChannel, errorChannel)

	go handleResult(callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish with store in history")
}

func publishRoutineReplicateWithTTL(channels, message string, replicate bool, ttl int) {
	var errorChannel = make(chan []byte)
	ch := strings.TrimSpace(channels)
	fmt.Println("Publish to channel: ", ch)
	callbackChannel := make(chan []byte)
	go pub.PublishExtendedWithMetaReplicateAndTTL(ch, message, nil, true, false, replicate, ttl, callbackChannel, errorChannel)

	go handleResult(callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "PublishExtendedWithMeta and TTL")
}

func publishRoutineReplicate(channels, message string, replicate bool) {
	var errorChannel = make(chan []byte)
	ch := strings.TrimSpace(channels)
	fmt.Println("Publish to channel: ", ch)
	callbackChannel := make(chan []byte)
	go pub.PublishExtendedWithMetaAndReplicate(ch, message, nil, true, false, replicate, callbackChannel, errorChannel)

	go handleResult(callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish with replicate")
}

func fireRoutine(channels string, message string) {
	var errorChannel = make(chan []byte)
	ch := strings.TrimSpace(channels)
	fmt.Println("Publish to channel: ", ch)
	callbackChannel := make(chan []byte)
	go pub.Fire(ch, message, false, callbackChannel, errorChannel)

	go handleResult(callbackChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Fire")
}

// PublishRoutine asks the user the message to send to the pubnub channel(s) and
// calls the Publish routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the
// channel by comma and send the message on all the pubnub channels.
func publishRoutine(channels string, message string) {
	var errorChannel = make(chan []byte)
	channelArray := strings.Split(channels, ",")

	for i := 0; i < len(channelArray); i++ {
		ch := strings.TrimSpace(channelArray[i])
		fmt.Println("Publish to channel: ", ch)
		channel := make(chan []byte)
		/*event := "DialStatus: ANSWER\r\nEvent: Dial\r\nPrivilege: call,all\r\nSubEvent: End\r\nChannel: SIP/1180-00001fa3\r\nUniqueID: 1475581272.19470"
			message2 := struct {
			Event          string `json:"event"`
			OrganizationId string `json:"organizationId"`
			Type           string `json:"type"`
		}{
			event,
			"someOrg",
			"phone",
		}
			go pub.Publish(ch, message2, channel, errorChannel)*/
		go pub.Publish(ch, message, channel, errorChannel)
		go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")
	}
}

func handleUnsubscribeResult(successChannel, errorChannel chan []byte, timeoutVal uint16, action string, noOfResponsesOnChannel int) {
	timeout := make(chan bool, 1)
	var timeoutValInt int
	multipleResponsesExpected := false
	if noOfResponsesOnChannel > 1 {
		timeoutValInt = int(timeoutVal) * noOfResponsesOnChannel
		multipleResponsesExpected = true
	}

	go func() {
		time.Sleep(time.Duration(timeoutValInt) * time.Second)
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
			if !multipleResponsesExpected {
				return
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
			if !multipleResponsesExpected {
				return
			}
		case <-timeout:
			fmt.Println(fmt.Sprintf("%s Handler timeout after %d secs", action, timeoutValInt))
			fmt.Println("")
			return
		}
	}
}

func handleResult(successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
	/*timeout := make(chan bool, 1)
	go func() {
		time.Sleep(time.Duration(timeoutVal) * time.Second)
		timeout <- true
	}()*/
	timeout := time.After(time.Duration(timeoutVal) * time.Second)
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
			//return
		}
	}
}

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

// PresenceRoutine calls the Subscribe routine of the messaging package,
// by setting the last argument as true, as a parallel process.
func presenceRoutine(channels string) {
	var errorChannel = make(chan []byte)
	var presenceChannel = make(chan []byte)
	go pub.Subscribe(channels, "", presenceChannel, true, errorChannel)
	go handleSubscribeResult(presenceChannel, errorChannel, "Presence")
}

// for test
func presenceRoutine2() {
	var errorChannel = make(chan []byte)
	var presenceChannel = make(chan []byte)
	go pub.Subscribe(connectChannels, "", presenceChannel, true, errorChannel)
	go handleSubscribeResult(presenceChannel, errorChannel, "Presence2")
}

// DetailedHistoryRoutine calls the History routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the _connectChannels
// by comma and send the message on all the pubnub channels.
func detailedHistoryRoutine(channels string) {
	var errorChannel = make(chan []byte)
	channelArray := strings.Split(channels, ",")
	for i := 0; i < len(channelArray); i++ {
		ch := strings.TrimSpace(channelArray[i])
		fmt.Println("DetailedHistory for channel: ", ch)

		channel := make(chan []byte)

		//go _pub.History(ch, 100, 13662867154115803, 13662867243518473, false, channel)
		go pub.History(ch, 100, 0, 0, false, false, channel, errorChannel)
		go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History")
	}
}

func getAllMessages(timetoken int64, channel string) {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	count := 100

	for {
		go pub.History(channel, count, timetoken, 0, false, false, successChannel, errorChannel)

		select {
		case response := <-successChannel:
			var parsed []interface{}

			err := json.Unmarshal(response, &parsed)
			if err != nil {
				fmt.Println(err.Error())
			}

			msgs := parsed[0].([]interface{})
			startString := parsed[1].(string)
			start, err := strconv.Atoi(startString)
			//endString := parsed[2].(string)
			//end, err := strconv.Atoi(endString)
			length := len(msgs)

			if length > 0 {
				fmt.Println(msgs)
				//fmt.Println(length)
				//fmt.Println("start:", start)
				//fmt.Println("end:", end)
			}

			if length == 100 {
				timetoken = int64(start)
			} else {
				return
			}
		case err := <-errorChannel:
			fmt.Println(string(err))
			return
		case <-messaging.Timeout():
			fmt.Println("History() timeout")
			return
		}
	}
}

func globalHereNowRoutine(showUuid bool, includeUserState bool) {
	fmt.Println("Global here now ", uuid)
	var errorChannel = make(chan []byte)
	successChannel := make(chan []byte)
	go pub.GlobalHereNow(showUuid, includeUserState, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Global Here Now")
}

// WhereNowRoutine
func whereNowRoutine(uuid string) {
	fmt.Println("WhereNow ", uuid)
	var errorChannel = make(chan []byte)
	successChannel := make(chan []byte)
	go pub.WhereNow(uuid, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "WhereNow")
}

// HereNowRoutine calls the HereNow routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the _connectChannels
// by comma and send the message on all the pubnub channels.
func hereNowRoutine(channels string, showUuid bool, includeUserState bool) {
	var errorChannel = make(chan []byte)
	channelArray := strings.Split(channels, ",")
	for i := 0; i < len(channelArray); i++ {
		channel := make(chan []byte)
		ch := strings.TrimSpace(channelArray[i])
		fmt.Println("HereNow for channel: ", ch)

		go pub.HereNow(ch, "", showUuid, includeUserState, channel, errorChannel)
		go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "HereNow")
	}
}

// UnsubscribeRoutine calls the Unsubscribe routine of the messaging package as a parallel
// process. All the channels in the _connectChannels string will be unsubscribed.
func unsubscribeRoutine(channels string) {
	var errorChannel = make(chan []byte)
	channel := make(chan []byte)
	channelArray := strings.Split(channels, ",")
	go pub.Unsubscribe(channels, channel, errorChannel)
	go handleUnsubscribeResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Unsubscribe", len(channelArray)*2)
}

// UnsubscribePresenceRoutine calls the PresenceUnsubscribe routine of the messaging package as a parallel
// process. All the channels in the _connectChannels string will be unsubscribed.
func unsubscribePresenceRoutine(channels string) {
	var errorChannel = make(chan []byte)
	channel := make(chan []byte)
	channelArray := strings.Split(channels, ",")
	go pub.PresenceUnsubscribe(channels, channel, errorChannel)
	go handleUnsubscribeResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "UnsubscribePresence", len(channelArray)*2)
}

// TimeRoutine calls the GetTime routine of the messaging package as a parallel
// process.
func timeRoutine() {
	var errorChannel = make(chan []byte)
	channel := make(chan []byte)
	go pub.GetTime(channel, errorChannel)
	go handleResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Time")
}

func addChannelToChannelGroupRoutine(group, channels string) {
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pub.ChannelGroupAddChannel(group, channels, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel,
		messaging.GetNonSubscribeTimeout(), "Channel Group Add Channel")
}

func removeChannelFromChannelGroupRoutine(group, channels string) {
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pub.ChannelGroupRemoveChannel(group, channels, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel,
		messaging.GetNonSubscribeTimeout(), "Channel Group Remove Channel")
}

func listChannelGroupRoutine(group string) {
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pub.ChannelGroupListChannels(group, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel,
		messaging.GetNonSubscribeTimeout(), "Channel Group List")
}

func removeChannelGroupRoutine(group string) {
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)

	go pub.ChannelGroupRemoveGroup(group, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel,
		messaging.GetNonSubscribeTimeout(), "Channel Group Remove")
}
