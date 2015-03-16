package analytics

import "github.com/jehiah/go-strftime"
import "github.com/xtgo/uuid"
import "encoding/json"
import "net/http"
import "errors"
import "bytes"
import "time"
import "log"

// Version of the client.
var version = "2.0.0"

// Endpoint for the Segment API.
var Endpoint = "https://api.segment.io"

// DefaultContext of message batches.
var DefaultContext = map[string]interface{}{
	"library": map[string]interface{}{
		"name":    "analytics-go",
		"version": version,
	},
}

// Message interface.
type message interface {
	setMessageId(string)
	setTimestamp(string)
}

// Response from API.
type response struct {
	Message string `json:"message"`
	Code    string `json:"code"`
}

// Message fields common to all.
type Message struct {
	Type      string `json:"type,omitempty"`
	MessageId string `json:"messageId,omitempty"`
	Timestamp string `json:"timestamp,omitempty"`
	SentAt    string `json:"sentAt,omitempty"`
}

// Batch message.
type Batch struct {
	Context  map[string]interface{} `json:"context,omitempty"`
	Messages []interface{}          `json:"batch"`
	Message
}

// Identify message.
type Identify struct {
	Context     map[string]interface{} `json:"context,omitempty"`
	Traits      map[string]interface{} `json:"traits,omitempty"`
	AnonymousId string                 `json:"anonymousId,omitempty"`
	UserId      string                 `json:"userId,omitempty"`
	Message
}

// Group message.
type Group struct {
	Context     map[string]interface{} `json:"context,omitempty"`
	Traits      map[string]interface{} `json:"traits,omitempty"`
	AnonymousId string                 `json:"anonymousId,omitempty"`
	UserId      string                 `json:"userId,omitempty"`
	GroupId     string                 `json:"groupId"`
	Message
}

// Track message.
type Track struct {
	Context     map[string]interface{} `json:"context,omitempty"`
	Properties  map[string]interface{} `json:"properties,omitempty"`
	AnonymousId string                 `json:"anonymousId,omitempty"`
	UserId      string                 `json:"userId,omitempty"`
	Event       string                 `json:"event"`
	Message
}

// Page message.
type Page struct {
	Context     map[string]interface{} `json:"context,omitempty"`
	Traits      map[string]interface{} `json:"properties,omitempty"`
	AnonymousId string                 `json:"anonymousId,omitempty"`
	UserId      string                 `json:"userId,omitempty"`
	Category    string                 `json:"category,omitempty"`
	Name        string                 `json:"name,omitempty"`
	Message
}

// Alias message.
type Alias struct {
	PreviousId string `json:"previousId"`
	UserId     string `json:"userId"`
	Message
}

// Client which batches messages and flushes at the given Interval or
// when the Size limit is exceeded. Set Verbose to true to enable
// logging output.
type Client struct {
	Endpoint string
	Interval time.Duration
	Verbose  bool
	Size     int
	key      string
	msgs     chan interface{}
	quit     chan bool

	uid func() string
	now func() time.Time
}

// New client with write key.
func New(key string) *Client {
	c := &Client{
		msgs:     make(chan interface{}, 100),
		quit:     make(chan bool),
		Interval: 5 * time.Second,
		Endpoint: Endpoint,
		Size:     250,
		key:      key,
		now:      time.Now,
		uid:      uid,
	}

	go c.loop()

	return c
}

// Alias buffers an "alias" message.
func (c *Client) Alias(msg *Alias) error {
	if msg.UserId == "" {
		return errors.New("You must pass a 'userId'.")
	}

	if msg.PreviousId == "" {
		return errors.New("You must pass a 'previousId'.")
	}

	msg.Type = "alias"
	c.queue(msg)

	return nil
}

// Page buffers an "page" message.
func (c *Client) Page(msg *Page) error {
	if msg.UserId == "" && msg.AnonymousId == "" {
		return errors.New("You must pass either an 'anonymousId' or 'userId'.")
	}

	msg.Type = "page"
	c.queue(msg)

	return nil
}

// Group buffers an "group" message.
func (c *Client) Group(msg *Group) error {
	if msg.GroupId == "" {
		return errors.New("You must pass a 'groupId'.")
	}

	if msg.UserId == "" && msg.AnonymousId == "" {
		return errors.New("You must pass either an 'anonymousId' or 'userId'.")
	}

	msg.Type = "group"
	c.queue(msg)

	return nil
}

// Identify buffers an "identify" message.
func (c *Client) Identify(msg *Identify) error {
	if msg.UserId == "" && msg.AnonymousId == "" {
		return errors.New("You must pass either an 'anonymousId' or 'userId'.")
	}

	msg.Type = "identify"
	c.queue(msg)

	return nil
}

// Track buffers an "track" message.
func (c *Client) Track(msg *Track) error {
	if msg.Event == "" {
		return errors.New("You must pass 'event'.")
	}

	if msg.UserId == "" && msg.AnonymousId == "" {
		return errors.New("You must pass either an 'anonymousId' or 'userId'.")
	}

	msg.Type = "track"
	c.queue(msg)

	return nil
}

// Queue message.
func (c *Client) queue(msg message) {
	msg.setMessageId(c.uid())
	msg.setTimestamp(timestamp(c.now()))
	c.msgs <- msg
}

// Close and flush metrics.
func (c *Client) Close() error {
	c.quit <- true
	close(c.msgs)
	<-c.quit
	return nil
}

// Send batch request.
func (c *Client) send(msgs []interface{}) {
	batch := new(Batch)
	batch.Messages = msgs
	batch.MessageId = c.uid()
	batch.SentAt = timestamp(c.now())
	batch.Context = DefaultContext

	b, err := json.Marshal(batch)
	if err != nil {
		c.log("error marshalling msgs: %s", err)
		return
	}

	url := c.Endpoint + "/v1/batch"
	req, err := http.NewRequest("POST", url, bytes.NewReader(b))
	if err != nil {
		c.log("error creating request: %s", err)
		return
	}

	req.Header.Add("User-Agent", "analytics-go (version: "+version+")")
	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Content-Length", string(len(b)))
	req.SetBasicAuth(c.key, "")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		c.log("error sending request: %s", err)
		return
	}
	defer res.Body.Close()

	c.report(res)
}

// Report on response body.
func (c *Client) report(res *http.Response) {
	if res.StatusCode < 400 {
		c.verbose("response %s", res.Status)
		return
	}

	msg := new(response)
	err := json.NewDecoder(res.Body).Decode(msg)
	if err != nil {
		c.log("error reading response: %s", err)
		return
	}

	c.log("response %s: %s – %s", res.Status, msg.Code, msg.Message)
}

// Batch loop.
func (c *Client) loop() {
	var msgs []interface{}
	tick := time.NewTicker(c.Interval)

	for {
		select {
		case msg := <-c.msgs:
			c.verbose("buffer (%d/%d) %v", len(msgs), c.Size, msg)
			msgs = append(msgs, msg)
			if len(msgs) == c.Size {
				c.verbose("exceeded %d messages – flushing", c.Size)
				c.send(msgs)
				msgs = nil
			}
		case <-tick.C:
			if len(msgs) > 0 {
				c.verbose("interval reached - flushing %d", len(msgs))
				c.send(msgs)
				msgs = nil
			} else {
				c.verbose("interval reached – nothing to send")
			}
		case <-c.quit:
			c.verbose("exit requested – flushing %d", len(msgs))
			c.send(msgs)
			c.verbose("exit")
			c.quit <- true
			return
		}
	}
}

// Verbose log.
func (c *Client) verbose(msg string, args ...interface{}) {
	if c.Verbose {
		log.Printf("segment: "+msg, args...)
	}
}

// Unconditional log.
func (c *Client) log(msg string, args ...interface{}) {
	log.Printf("segment: "+msg, args...)
}

// Set message timestamp.
func (m *Message) setTimestamp(s string) {
	m.Timestamp = s
}

// Set message id.
func (m *Message) setMessageId(s string) {
	m.MessageId = s
}

// Return formatted timestamp.
func timestamp(t time.Time) string {
	return strftime.Format("%Y-%m-%dT%H:%M:%S%z", t)
}

// Return uuid string.
func uid() string {
	return uuid.NewRandom().String()
}
