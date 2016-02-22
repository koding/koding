// Package webhook implements middleware for GitHub Webhooks. User provides
// webhook service object that handles events delivered by GitHub. Webhook
// handler verifies payload signature delivered along with the event, unmarshals
// it to corresponding event struct and dispatches control to user service.
//
// The types of events are configured up front during webhook creation. Only
// "application/json" content type is supported for incoming events.
//
// Event types
//
//           Name       |            Type
//   -------------------+-----------------------------
//    commit_comment    | *webhook.CommitCommentEvent
//   -------------------+-----------------------------
//    create            | *webhook.CreateEvent
//   -------------------+-----------------------------
//    delete            | *webhook.DeleteEvent
//   -------------------+-----------------------------
//    deployment        | *webhook.DeploymentEvent
//   -------------------+-----------------------------
//    deployment_status | *webhook.DeploymentStatusEvent
//   -------------------+-----------------------------
//    download          | *webhook.DownloadEvent
//   -------------------+-----------------------------
//    follow            | *webhook.FollowEvent
//   -------------------+-----------------------------
//    fork_apply        | *webhook.ForkApplyEvent
//   -------------------+-----------------------------
//    fork              | *webhook.ForkEvent
//   -------------------+-----------------------------
//    gist              | *webhook.GistEvent
//   -------------------+-----------------------------
//    gollum            | *webhook.GollumEvent
//   -------------------+-----------------------------
//    issue_comment     | *webhook.IssueCommentEvent
//   -------------------+-----------------------------
//    issues            | *webhook.IssuesEvent
//   -------------------+-----------------------------
//    member            | *webhook.MemberEvent
//   -------------------+-----------------------------
//    membership        | *webhook.MembershipEvent
//   -------------------+-----------------------------
//    page_build        | *webhook.PageBuildEvent
//   -------------------+-----------------------------
//    ping              | *webhook.PingEvent
//   -------------------+-----------------------------
//    public            | *webhook.PublicEvent
//   -------------------+-----------------------------
//    pull_request      | *webhook.PullRequestEvent
//   -------------------+-----------------------------
//    push              | *webhook.PushEvent
//   -------------------+-----------------------------
//    release           | *webhook.ReleaseEvent
//   -------------------+-----------------------------
//    repository        | *webhook.RepositoryEvent
//   -------------------+-----------------------------
//    status            | *webhook.StatusEvent
//   -------------------+-----------------------------
//    team_add          | *webhook.TeamAddEvent
//   -------------------+-----------------------------
//    watch             | *webhook.WatchEvent
//   -------------------+---------+----------------------------------------
//    pull_request_review_comment | *webhook.PullRequestReviewCommentEvent
//   -----------------------------+----------------------------------------
//
// Handler service
//
// Webhook dispatches incoming events to user-provided handler service. Each
// method that takes *Event struct as a single argument is mapped for handling
// corresponding event type according to the above table. In order to handle
// all the events with single method, webhook handler looks up for the method
// with the following definition:
//
//   func (T) MethodName(eventName string, eventPayload interface{})
//
// If a handler service has defined both: methods for handling particular events
// and method hadling all events, the former has the priority - if there exists
// no method for handling particular event type, the blanket handler will be used.
//
// Example
//
// The following handler service logs each incoming event.
//
//   package main
//
//   import (
//   	"log"
//   	"net/http"
//
//   	"github.com/rjeczalik/gh/webhook"
//   )
//
//   type LoggerService struct{}
//
//   func (LoggerService) Ping(event *webhook.PingEvent) {
//   	log.Printf("supported events: %v", event.Hook.Events)
//   }
//
//   func (LoggerService) Push(event *webhook.PushEvent) {
//   	log.Printf("%s has pushed to %s", event.Pusher.Email, event.Repository.Name)
//   }
//
//   func (LoggerService) All(name string, event interface{}) {
//   	log.Println("event", event)
//   }
//
//   func main() {
//      log.Fatal(http.ListenAndServe(":8080", webhook.New("secret", LoggerService{}))
//   }
//
// The "ping" and "push" event are handle accordingly by the Ping and Push methods,
// all the rest are handled with the All one.
package webhook

import (
	"bytes"
	"reflect"
	"strconv"
	"time"
)

//go:generate go run generate_payloads.go
//go:generate go test -run TestGenerateMockHelper -- -generate
//go:generate gofmt -w -s payloads.go mock_test.go

var null = []byte("null")

// Time embeds time.Time. The wrapper allows for unmarshalling time from JSON
// null value or unix timestamp.
type Time struct {
	time.Time
}

// MarshalJSON implements the json.Marshaler interface. The time is a quoted
// string in RFC 3339 format or "null" if it's a zero value.
func (t Time) MarshalJSON() ([]byte, error) {
	if t.Time.IsZero() {
		return null, nil
	}
	return t.Time.MarshalJSON()
}

// UnmarshalJSON implements the json.Unmarshaler interface. The time is expected
// to be a quoted string in RFC 3339 format, a unix timestamp or a "null" string.
func (t *Time) UnmarshalJSON(p []byte) (err error) {
	if bytes.Compare(p, null) == 0 {
		t.Time = time.Time{}
		return nil
	}
	if err = t.Time.UnmarshalJSON(p); err == nil {
		return nil
	}
	n, e := strconv.ParseInt(string(bytes.Trim(p, `"`)), 10, 64)
	if e != nil {
		return err
	}
	t.Time = time.Unix(n, 0)
	return nil
}

type payloadsMap map[string]reflect.Type

func (p payloadsMap) Type(name string) (reflect.Type, bool) {
	typ, ok := p[name]
	return typ, ok
}

func (p payloadsMap) Name(typ reflect.Type) (string, bool) {
	for pname, ptyp := range p {
		if ptyp == typ {
			return pname, true
		}
	}
	return "", false
}
