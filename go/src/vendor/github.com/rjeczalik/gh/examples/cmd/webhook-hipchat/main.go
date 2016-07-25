// Command webhook-hipchat starts GitHub Webhook server and forwards all
// push notifications to the specified HipChat room.
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/rjeczalik/gh/webhook"
)

var (
	addr   = flag.String("http", ":8080", "Network address to listen on.")
	secret = flag.String("secret", "", "GitHub webhook secret.")
	token  = flag.String("token", "", "HipChat personal API token.")
	room   = flag.String("room", "", "HipChat room ID.")
)

type hipchat struct{}

func (h hipchat) Push(e *webhook.PushEvent) {
	url := fmt.Sprintf("https://api.hipchat.com/v2/room/%s/notification", *room)
	body := fmt.Sprintf(`{"message":"%s pushed to %s"}`, e.Pusher.Email, e.Repository.Name)
	req, err := http.NewRequest("POST", url, strings.NewReader(body))
	if err != nil {
		log.Println(err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+*token)
	if _, err := http.DefaultClient.Do(req); err != nil {
		log.Println(err)
	}
}

func main() {
	flag.Parse()
	log.Fatal(http.ListenAndServe(*addr, webhook.New(*secret, hipchat{})))
}
