package chromr

import (
	"code.google.com/p/go.net/websocket"
	"encoding/json"
	"fmt"
	"net/http"
)

type ChromeTab struct {
	Title        string
	Url          string
	Description  string
	FaviconUrl   string
	ThumbnailUrl string
	Type         string

	Id                   string
	DevtoolsFrontendUrl  string
	WebSocketDebuggerUrl string

	requestChan      chan *request
	NotificationChan chan *Notification
}

type P map[string]interface{}

type request struct {
	Id                 int    `json:"id"`
	Method             string `json:"method"`
	Params             P      `json:"params"`
	singleResponseChan chan *response
}

type response struct {
	Id     int             `json:"id"`
	Error  interface{}     `json:"error"`
	Result json.RawMessage `json:"result"`
}

type Notification struct {
	Method string          `json:"method"`
	Params json.RawMessage `json:"params"`
}

func GetTabs(host string) ([]*ChromeTab, error) {
	resp, err := http.Get("http://" + host + "/json")
	if err != nil {
		return nil, err
	}

	dec := json.NewDecoder(resp.Body)
	var tabs []*ChromeTab
	if err := dec.Decode(&tabs); err != nil {
		return nil, err
	}
	resp.Body.Close()

	return tabs, nil
}

func (tab *ChromeTab) Connect() {
	tab.requestChan = make(chan *request)
	tab.NotificationChan = make(chan *Notification, 1000)

	go func() {
		ws, err := websocket.Dial(tab.WebSocketDebuggerUrl, "", "http://localhost/")
		if err != nil {
			panic(err)
		}

		responseChan := make(chan *response)
		go func() {
			for {
				var message struct {
					response
					Notification
				}
				if err := websocket.JSON.Receive(ws, &message); err != nil {
					panic(err)
				}
				if message.Method != "" {
					tab.NotificationChan <- &message.Notification
					continue
				}
				responseChan <- &message.response
			}
		}()

		id := 0
		pendingRequests := make(map[int]*request)
		for {
			select {
			case req := <-tab.requestChan:
				req.Id = id
				pendingRequests[id] = req
				id += 1
				if err := websocket.JSON.Send(ws, req); err != nil {
					panic(err)
				}
			case resp := <-responseChan:
				pendingRequests[resp.Id].singleResponseChan <- resp
				delete(pendingRequests, resp.Id)
			}
		}
	}()
}

func (tab *ChromeTab) Command(method string, params P, resultPtr interface{}) error {
	singleResponseChan := make(chan *response)
	req := request{
		Method:             method,
		Params:             params,
		singleResponseChan: singleResponseChan,
	}
	tab.requestChan <- &req
	resp := <-singleResponseChan
	if resp.Error != nil {
		return fmt.Errorf("%v", resp.Error)
	}
	if resultPtr == nil {
		return nil
	}
	return json.Unmarshal(resp.Result, resultPtr)
}
