package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/sender"
)

var (
	Name = "MailSender"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// if err := bongo.B.PublishEvent("send", &sender.Mail{Body: "foo"}); err != nil {
	// 	fmt.Println(err.Error())
	// }

	r.SetContext(sender.New(r.Log))
	r.Register(sender.Mail{}).On("send").Handle((*sender.Controller).Send)
	r.Listen()
	r.Wait()
}
