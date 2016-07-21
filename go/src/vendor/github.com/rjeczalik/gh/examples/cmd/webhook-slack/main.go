// Command webhook-slack starts GitHub Webhook server and forwards all
// push notifications to the specified Slack channel.
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"

	"github.com/rjeczalik/gh/webhook"
)

var (
	addr    = flag.String("http", ":8080", "Network address to listen on.")
	secret  = flag.String("secret", "", "GitHub webhook secret")
	token   = flag.String("token", "", "Slack API token")
	channel = flag.String("channel", "", "Slack channel name")
)

type slack struct{}

func (s slack) Push(e *webhook.PushEvent) {
	const format = "https://slack.com/api/chat.postMessage?token=%s&channel=%s&text=%s"
	text := url.QueryEscape(fmt.Sprintf("%s pushed to %s", e.Pusher.Email, e.Repository.Name))
	if _, err := http.Get(fmt.Sprintf(format, *token, *channel, text)); err != nil {
		log.Println(err)
	}
}

func (s slack) PullRequest(e *webhook.PullRequest) {
	const format = "https://slack.com/api/chat.postMessage?token=%s&channel=%s&text=%s"
	text := url.QueryEscape(fmt.Sprintf("%v sent pull request on: %s", e.User, e.HTMLURL))
	if _, err := http.Get(fmt.Sprintf(format, *token, *channel, text)); err != nil {
		log.Println(err)
	}
}

func main() {
	flag.Parse()
	log.Fatal(http.ListenAndServe(*addr, webhook.New(*secret, slack{})))
}
