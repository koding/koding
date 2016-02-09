package main

import (
	"fmt"

	"github.com/kr/pretty"
	"github.com/nlopes/slack"
)

func main() {
	api := slack.New("xoxp-20619428033-20616319317-20621604279-a1dd5bcc49")
	user, err := api.GetUserInfo("U0LJ49D9B")
	if err != nil {
		fmt.Println("HATA VAR")
		fmt.Printf("%s\n", err)
		return
	}
	fmt.Printf("ID: %s, Fullname: %s, Email: %s\n", user.ID, user.Profile.RealName, user.Profile.Email)

	pretty.Println("USER:", user)
	///////////////

	ch, err := api.GetChannels(false)
	if err != nil {
		fmt.Println("HATA VAR-Get Channels")
		fmt.Printf("%s\n", err)
		return
	}

	pretty.Println("CHANNELS:", ch)

	channel, err := api.GetChannelInfo("C0LJ81W74")
	if err != nil {
		fmt.Println("HATA VAR-Get Channel INFO")
		fmt.Printf("%s\n", err)
		return
	}

	pretty.Println("CHANNELS:", channel)
}

//
// func main() {
// 	api := slack.New("xoxp-20619428033-20616319317-20621604279-a1dd5bcc49")
// 	res, err := api.AuthTest()
// 	if err != nil {
// 		fmt.Println("ERR HERE")
// 		return
// 	}
// 	fmt.Println("response is :", res)
// 	pretty.Println("RESPONSE:", res)
//
// }

// xoxp-20619428033-20616319317-20621604279-a1dd5bcc49
