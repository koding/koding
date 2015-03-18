package analytics

import "net/http/httptest"
import "encoding/json"
import "net/http"
import "bytes"
import "time"
import "fmt"
import "io"

func mockId() string      { return "I'm unique" }
func mockTime() time.Time { return time.Unix(0, 0) }

func mockServer() (chan []byte, *httptest.Server) {
	done := make(chan []byte)

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		buf := bytes.NewBuffer(nil)
		io.Copy(buf, r.Body)

		var v interface{}
		err := json.Unmarshal(buf.Bytes(), &v)
		if err != nil {
			panic(err)
		}

		b, err := json.MarshalIndent(v, "", "  ")
		if err != nil {
			panic(err)
		}

		done <- b
	}))

	return done, server
}

func ExampleTrack() {
	body, server := mockServer()
	defer server.Close()

	client := New("h97jamjwbh")
	client.Endpoint = server.URL
	client.now = mockTime
	client.uid = mockId
	client.Size = 1

	client.Track(&Track{
		Event:  "Download",
		UserId: "123456",
		Properties: map[string]interface{}{
			"application": "Segment Desktop",
			"version":     "1.1.0",
			"platform":    "osx",
		},
	})

	fmt.Printf("%s\n", <-body)
	// Output:
	// {
	//   "batch": [
	//     {
	//       "event": "Download",
	//       "messageId": "I'm unique",
	//       "properties": {
	//         "application": "Segment Desktop",
	//         "platform": "osx",
	//         "version": "1.1.0"
	//       },
	//       "timestamp": "1969-12-31T16:00:00-0800",
	//       "type": "track",
	//       "userId": "123456"
	//     }
	//   ],
	//   "context": {
	//     "library": {
	//       "name": "analytics-go",
	//       "version": "2.0.0"
	//     }
	//   },
	//   "messageId": "I'm unique",
	//   "sentAt": "1969-12-31T16:00:00-0800"
	// }
}

func ExampleTrack_context() {
	body, server := mockServer()
	defer server.Close()

	client := New("h97jamjwbh")
	client.Endpoint = server.URL
	client.now = mockTime
	client.uid = mockId
	client.Size = 1

	client.Track(&Track{
		Event:  "Download",
		UserId: "123456",
		Properties: map[string]interface{}{
			"application": "Segment Desktop",
			"version":     "1.1.0",
			"platform":    "osx",
		},
		Context: map[string]interface{}{
			"whatever": "here",
		},
	})

	fmt.Printf("%s\n", <-body)
	// Output:
	// {
	//   "batch": [
	//     {
	//       "context": {
	//         "whatever": "here"
	//       },
	//       "event": "Download",
	//       "messageId": "I'm unique",
	//       "properties": {
	//         "application": "Segment Desktop",
	//         "platform": "osx",
	//         "version": "1.1.0"
	//       },
	//       "timestamp": "1969-12-31T16:00:00-0800",
	//       "type": "track",
	//       "userId": "123456"
	//     }
	//   ],
	//   "context": {
	//     "library": {
	//       "name": "analytics-go",
	//       "version": "2.0.0"
	//     }
	//   },
	//   "messageId": "I'm unique",
	//   "sentAt": "1969-12-31T16:00:00-0800"
	// }
}

func ExampleTrack_many() {
	body, server := mockServer()
	defer server.Close()

	client := New("h97jamjwbh")
	client.Endpoint = server.URL
	client.now = mockTime
	client.uid = mockId
	client.Size = 3

	for i := 0; i < 5; i++ {
		client.Track(&Track{
			Event:  "Download",
			UserId: "123456",
			Properties: map[string]interface{}{
				"application": "Segment Desktop",
				"version":     i,
			},
		})
	}

	fmt.Printf("%s\n", <-body)
	// Output:
	// {
	//   "batch": [
	//     {
	//       "event": "Download",
	//       "messageId": "I'm unique",
	//       "properties": {
	//         "application": "Segment Desktop",
	//         "version": 0
	//       },
	//       "timestamp": "1969-12-31T16:00:00-0800",
	//       "type": "track",
	//       "userId": "123456"
	//     },
	//     {
	//       "event": "Download",
	//       "messageId": "I'm unique",
	//       "properties": {
	//         "application": "Segment Desktop",
	//         "version": 1
	//       },
	//       "timestamp": "1969-12-31T16:00:00-0800",
	//       "type": "track",
	//       "userId": "123456"
	//     },
	//     {
	//       "event": "Download",
	//       "messageId": "I'm unique",
	//       "properties": {
	//         "application": "Segment Desktop",
	//         "version": 2
	//       },
	//       "timestamp": "1969-12-31T16:00:00-0800",
	//       "type": "track",
	//       "userId": "123456"
	//     }
	//   ],
	//   "context": {
	//     "library": {
	//       "name": "analytics-go",
	//       "version": "2.0.0"
	//     }
	//   },
	//   "messageId": "I'm unique",
	//   "sentAt": "1969-12-31T16:00:00-0800"
	// }
}
