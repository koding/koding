package main

import (
	"bufio"
	"fmt"
	"github.com/pubnub/go/messaging"
	"encoding/json"
	"os"
	"strconv"
	"strings"
	"time"
)

// pub instance of messaging package.
var pub *messaging.Pubnub

var publishMessageCount int = 5
var pageSize int = 10
var startTime int64 = 0
var channel string = "test"

func main() {
	pub = messaging.NewPubnub("demo", "demo", "demo", "", false, "")
	readLoop()
	fmt.Println("Exit")
}

// askChannel asks the user to channel name.
// If the channel(s) are not provided the channel(s) provided by the user
// at the beginning will be used.
// returns the read channel(s), or error
func askChannel() (string, error) {
	fmt.Println("Please enter the channel name.")
	reader := bufio.NewReader(os.Stdin)
	channels, _, errReadingChannel := reader.ReadLine()
	if errReadingChannel != nil {
		fmt.Println("Error channel(s): ", errReadingChannel.Error())
		return "", errReadingChannel
	}
	if strings.TrimSpace(string(channels)) == "" {
		fmt.Println("Channel empty")
		return askChannel()
	}
	return string(channels), nil
}


// publishRoutine asks the user the message to send to the pubnub channel(s) and
// calls the Publish routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the
// channel by comma and send the message on all the pubnub channels.
func publishRoutine(channels string, message string) {
	errorChannel := make(chan []byte)
	successChannel := make(chan []byte)
	fmt.Println("Publishing message: ", message)
	go pub.Publish(channels, message, successChannel, errorChannel)
	go handleResult(successChannel, errorChannel, messaging.GetNonSubscribeTimeout(), "Publish")
}

// detailedHistoryRoutine calls the History routine of the messaging package as a parallel
// process. If we have multiple pubnub channels then this method will spilt the _connectChannels
// by comma and send the message on all the pubnub channels.
func detailedHistoryRoutine(channels string, startTime int64) {
	errorChannel := make(chan []byte)
	channel := make(chan []byte)
	fmt.Println(fmt.Sprintf("Page Size :%d", pageSize))
	go pub.History(channels, pageSize, startTime, 0, false, channel, errorChannel)
	go handleDetailedHistoryResult(channel, errorChannel, messaging.GetNonSubscribeTimeout(), "Detailed History")
}

// getServerTime calls the GetTime method of the messaging, parses the response to get the
// value and return it.
func getServerTime() int64 {
	returnTimeChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	go pub.GetTime(returnTimeChannel, errorChannel)
	return parseServerTimeResponse(returnTimeChannel)
}

// parseServerTimeResponse unmarshals the time response from the pubnub api and returns the int64 value.
func parseServerTimeResponse(returnChannel chan []byte) int64 {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(15 * time.Second)
		timeout <- true
	}()
	for {
		select {
		case value, ok := <-returnChannel:
			if !ok {
				break
			}
			if string(value) != "[]" {
				response := string(value)
				if response != "" {
					var arr []int64
					err2 := json.Unmarshal(value, &arr)
					if err2 != nil {
						fmt.Println("err2 time", err2)
						break
					} else {
						return arr[0]
					}
				} else {
					fmt.Println("response", response)
					break
				}
			}
		case <-timeout:
			fmt.Println("timeout")
			break
		}
	}
	return 0
}

func parseHistory(history []interface{}, action string, success []byte){
	if(history != nil){
		val, err := strconv.Atoi(history[1].(string))
		if err != nil {						
			fmt.Println(fmt.Sprintf("%s Start time parse error : %s ", err.Error(), history[2].(string)))
		} else {						
			startTime = int64(val)
			if(startTime <= 0){
				fmt.Println("")
				fmt.Println(fmt.Sprintf("No more messages in %s. ", action))
			} else {
				if(history[0] != nil){
					fmt.Println("")
					fmt.Println("History messages: ")
					var historyMessageArray = history[0].([]interface{})
					for i, _ := range historyMessageArray {
						//fmt.Println(u)
						fmt.Println(historyMessageArray[len(historyMessageArray) - i - 1])
					}
				}
				fmt.Println("")
				fmt.Println("Enter 4 to goto the next page of Detailed History")
			}
		}					
	} else {
		fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))		
	}
	//fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))	
}

// handleDetailedHistoryResult parses the history response from the pubnub api on the returnChannel
// and checks if the response contains the message. If true then the test is successful.
func handleDetailedHistoryResult(successChannel chan []byte, errorChannel chan []byte, timeoutVal uint16, action string) {
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
				var history []interface{}
				err2 := json.Unmarshal(success, &history)
				if err2 != nil {
					fmt.Println("error in unmarshalling history", err2)
					break
				} else {
					parseHistory(history, action, success)
				}
				//fmt.Println(fmt.Sprintf("%s Response: %s ", action, success))
				fmt.Println("")
			}
			return
		case failure, ok := <-errorChannel:
			if !ok {
				break
			}
			if string(failure) != "[]" {
				fmt.Println(fmt.Sprintf("%s Error Callback: %s", action, failure))
				fmt.Println("")
			}
			return
		case <-timeout:
			fmt.Println(fmt.Sprintf("%s Handler timeout after %d secs", action, timeoutVal))
			fmt.Println("")
			return
		}
	}
}

func handleResult(successChannel, errorChannel chan []byte, timeoutVal uint16, action string) {
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
				fmt.Println(fmt.Sprintf("%s Error Callback: %s", action, failure))
				fmt.Println("")
			}
			return
		case <-timeout:
			fmt.Println(fmt.Sprintf("%s Handler timeout after %d secs", action, timeoutVal))
			fmt.Println("")
			return
		}
	}
}

// askNumber
//
func askNumber(what string, optional bool) int {
	var input string

	if optional {
		fmt.Println("Enter " + what + " (optional)")
	} else {
		fmt.Println("Enter " + what)
	}
	fmt.Scanln(&input)
	if (optional) && (strings.TrimSpace(input) == ""){
		input = "0"
	}
	
	val, err := strconv.Atoi(strings.TrimSpace(input))
	if err != nil {
		fmt.Println(what + " is invalid. Please enter numerals.")
		return askNumber(what, optional)
	}

	return int(val)
}

// readLoop starts an infinite loop to read the user's input.
// Based on the input the respective go routine is called as a parallel process.
func readLoop() {
	showOptions := true
	reader := bufio.NewReader(os.Stdin)
	for {
		if showOptions {
			fmt.Println("")
			fmt.Println("ENTER 1 TO Publish a message")
			fmt.Println("ENTER 2 TO Publish some messages")
			fmt.Println("ENTER 3 TO fetch Detailed History")
			fmt.Println("ENTER 4 TO goto the next page of Detailed History")
			fmt.Println(fmt.Sprintf("ENTER 5 TO set Publish message count (current: %d)", publishMessageCount))
			fmt.Println(fmt.Sprintf("ENTER 6 TO set Detailed History page size (current: %d)", pageSize))
			fmt.Println(fmt.Sprintf("ENTER 7 TO change PubNub Channel (current: %s)", channel))
			fmt.Println("ENTER 0 TO Exit")
			fmt.Println("")
			showOptions = false
		}

		var action string
		fmt.Scanln(&action)

		breakOut := false
		switch action {
		case "1":
			fmt.Println("Please enter the message")
			message, _, err := reader.ReadLine()
			if err != nil {
				fmt.Println(err)
			} else {
				go publishRoutine(channel, string(message))
			}		
		case "2":
			fmt.Println(fmt.Sprintf("Publish %d messages to channel: %s", publishMessageCount, channel))
			for i := 0; i < publishMessageCount; i++ {
				go publishRoutine(channel, fmt.Sprintf("test message %d", i))
				time.Sleep(1 * time.Second)
			}
			fmt.Println(fmt.Sprintf("%d messages published.", publishMessageCount))
			fmt.Println("")
		case "3":
			fmt.Println(fmt.Sprintf("Running Detailed History for channel: %s", channel))
			startTime := getServerTime()
			go detailedHistoryRoutine(channel, startTime)			
		case "4":
			if(startTime <=0){
				fmt.Println("Start time invalid, please run option 3 first.")
			} else {
				fmt.Println(fmt.Sprintf("Showing next page of Detailed History for channel: %s", channel))
				fmt.Println(fmt.Sprintf("Using start time :%d", startTime))	
				go detailedHistoryRoutine(channel, startTime)
			}
			fmt.Println("")
		case "5":	
			publishMessageCount = askNumber("Publish Message Count", false)
			fmt.Println(fmt.Sprintf("Publish Message Count set to :%d", publishMessageCount))
			fmt.Println("")
		case "6":
			pageSize = askNumber("Detailed History Page Size", false)
			fmt.Println(fmt.Sprintf("Detailed History Page Size set to :%d", pageSize))		
			fmt.Println("")	
		case "7":
			channels, errReadingChannel := askChannel()
			if errReadingChannel != nil {
				fmt.Println("errReadingChannel: ", errReadingChannel)
			} else {
				channel = channels
				fmt.Println("Channel changed to : ", channel)
			}	
			fmt.Println("")
		case "0":
			fmt.Println("Exiting")
			pub.Abort()
			time.Sleep(1 * time.Second)
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