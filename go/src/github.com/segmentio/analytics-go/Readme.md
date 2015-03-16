# analytics-go

  Segment analytics client for Go. For additional documentation
  visit [https://segment.com/docs/libraries/go](https://segment.com/docs/libraries/go/) or view the [godocs](http://godoc.org/github.com/segmentio/analytics-go).

## Usage

```go
var DefaultContext = map[string]interface{}{
  "library": map[string]interface{}{
    "name":    "analytics-go",
    "version": Version,
  },
}
```
DefaultContext of message batches.

```go
var Endpoint = "https://api.segment.io"
```
Endpoint for the Segment API.

#### type Alias

```go
type Alias struct {
  PreviousId string `json:"previousId"`
  UserId     string `json:"userId,omitempty"`
  Message
}
```

Alias message.

#### type Batch

```go
type Batch struct {
  Messages []interface{} `json:"batch"`
  Message
}
```

Batch message.

#### type Client

```go
type Client struct {
  Endpoint string
  Interval time.Duration
  Verbose  bool
  Size     int
}
```

Client which batches messages and flushes at the given Interval or when the Size
limit is exceeded. Set Verbose to true to enable logging output.

#### func  New

```go
func New(key string) *Client
```
New client with write key.

#### func (*Client) Alias

```go
func (c *Client) Alias(msg *Alias) error
```
Alias buffers an "alias" message.

#### func (*Client) Close

```go
func (c *Client) Close() error
```
Close and flush metrics.

#### func (*Client) Group

```go
func (c *Client) Group(msg *Group) error
```
Group buffers an "group" message.

#### func (*Client) Identify

```go
func (c *Client) Identify(msg *Identify) error
```
Identify buffers an "identify" message.

#### func (*Client) Page

```go
func (c *Client) Page(msg *Page) error
```
Page buffers an "page" message.

#### func (*Client) Track

```go
func (c *Client) Track(msg *Track) error
```
Track buffers an "track" message.

#### type Group

```go
type Group struct {
  Traits      map[string]interface{} `json:"traits,omitempty"`
  AnonymousId string                 `json:"anonymousId,omitempty"`
  UserId      string                 `json:"userId,omitempty"`
  GroupId     string                 `json:"groupId"`
  Message
}
```

Group message.

#### type Identify

```go
type Identify struct {
  Traits      map[string]interface{} `json:"traits,omitempty"`
  AnonymousId string                 `json:"anonymousId,omitempty"`
  UserId      string                 `json:"userId,omitempty"`
  Message
}
```

Identify message.

#### type Message

```go
type Message struct {
  Type      string                 `json:"type,omitempty"`
  MessageId string                 `json:"messageId,omitempty"`
  Timestamp string                 `json:"timestamp,omitempty"`
  SentAt    string                 `json:"sentAt,omitempty"`
  Context   map[string]interface{} `json:"context,omitempty"`
}
```

Message fields common to all.

#### type Page

```go
type Page struct {
  Traits      map[string]interface{} `json:"properties,omitempty"`
  AnonymousId string                 `json:"anonymousId,omitempty"`
  UserId      string                 `json:"userId,omitempty"`
  Category    string                 `json:"category,omitempty"`
  Name        string                 `json:"name,omitempty"`
  Message
}
```

Page message.

#### type Track

```go
type Track struct {
  Properties  map[string]interface{} `json:"properties,omitempty"`
  AnonymousId string                 `json:"anonymousId,omitempty"`
  UserId      string                 `json:"userId,omitempty"`
  Event       string                 `json:"event"`
  Message
}
```

Track message.

## License

 MIT
