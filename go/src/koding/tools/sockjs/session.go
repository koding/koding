package sockjs

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"time"
)

type Session struct {
	Service                      *Service
	ReceiveChan                  chan interface{}
	Closed                       bool
	sendChan                     chan interface{}
	doConnCheck, connCheckResult chan bool
	readSemaphore                chan bool
	writeOpenFrame               bool
	lastSendTime                 time.Time
	currentSecond                int64
	receiveCounter               int
	cookie                       string
	IsWebsocket                  bool
	Tag                          string
}

func newSession(service *Service, isWebsocket bool) *Session {
	return &Session{
		Service:        service,
		ReceiveChan:    make(chan interface{}, 1000),
		sendChan:       make(chan interface{}, 1000),
		readSemaphore:  make(chan bool, 1),
		writeOpenFrame: true,
		lastSendTime:   time.Now(),
		cookie:         "JSESSIONID=dummy",
		IsWebsocket:    isWebsocket,
	}
}

func (s *Session) Send(data interface{}) bool {
	if s.Closed {
		return true
	}
	select {
	case s.sendChan <- data:
		// successful
	default:
		return false
	}
	return true
}

func (s *Session) Close() {
	s.Closed = true
	select {
	case s.ReceiveChan <- nil:
		// successful
	default:
		// never block
	}
}

func (s *Session) ReadMessages(data []byte) bool {
	if s.Closed {
		return true
	}

	var obj interface{}
	err := json.Unmarshal(data, &obj)
	if err != nil {
		return false
	}

	if messages, ok := obj.([]interface{}); ok {
		for _, message := range messages {
			s.receiveMessage(message)
		}
		return true
	}

	s.receiveMessage(obj)
	return true
}

func (s *Session) receiveMessage(message interface{}) {
	t := time.Now().Unix()
	if s.currentSecond != t {
		s.currentSecond = t
		s.receiveCounter = 0
	}
	s.receiveCounter += 1
	if s.Service.MaxReceivedPerSecond > 0 && s.receiveCounter > s.Service.MaxReceivedPerSecond {
		time.Sleep(time.Second)
	}

	s.ReceiveChan <- message
}

func (s *Session) WriteFrames(w http.ResponseWriter, streaming, chunked bool, frameStart, frameEnd []byte, escape bool) {
	select {
	case s.readSemaphore <- true:
		// can read
	default:
		w.Write(createFrame('c', `[1002,"Connection interrupted"]`, frameStart, frameEnd, escape))
		return
	}
	defer func() {
		<-s.readSemaphore
	}()

	conn, buf, _ := w.(http.Hijacker).Hijack()
	defer conn.Close()

	var frameWriter io.Writer = buf
	if chunked {
		defer buf.Write([]byte("\r\n"))
		chunkedWriter := httputil.NewChunkedWriter(buf)
		frameWriter = chunkedWriter
		defer chunkedWriter.Close()
	}

	var frame []byte
	var closed bool
	total := 0
	for !closed && total < s.Service.StreamLimit {
		frame, closed = s.CreateNextFrame(frameStart, frameEnd, escape)
		total += len(frame)

		frameWriter.Write(frame)
		if err := buf.Flush(); err != nil {
			s.Close()
			return
		}

		s.lastSendTime = time.Now()
		if !streaming {
			break
		}
	}
}

func (s *Session) CreateNextFrame(frameStart, frameEnd []byte, escape bool) ([]byte, bool) {
	if s.writeOpenFrame {
		s.writeOpenFrame = false
		return createFrame('o', "", frameStart, frameEnd, escape), false
	}

	messages := make([]interface{}, 0)
	select {
	case message, ok := <-s.sendChan:
		if !ok {
			return createFrame('c', `[3000,"Go away!"]`, frameStart, frameEnd, escape), true
		}
		messages = append(messages, message)
	case <-time.After(25 * time.Second):
		return createFrame('h', "", frameStart, frameEnd, escape), false
	}

	for moreMessages := true; moreMessages; {
		select {
		case message, ok := <-s.sendChan:
			if !ok {
				moreMessages = false
				break
			}
			messages = append(messages, message)
		default:
			moreMessages = false
		}
	}

	data, err := json.Marshal(messages)
	if err != nil {
		s.Service.ErrorHandler(err, 0)
		return s.CreateNextFrame(frameStart, frameEnd, escape)
	}

	return createFrame('a', string(data), frameStart, frameEnd, escape), false
}

func createFrame(kind byte, data string, frameStart, frameEnd []byte, escape bool) []byte {
	frame := bytes.NewBuffer(nil)
	frame.Write(frameStart)
	frame.WriteByte(kind)
	for _, r := range data {
		special := (0x200c <= r && r <= 0x200f) || (0x2028 <= r && r <= 0x202f) || (0x2060 <= r && r <= 0x206f) || (0xfff0 <= r && r <= 0xffff)
		if escape && (r == '\\' || r == '"' || special) {
			frame.WriteByte('\\')
		}
		if special {
			frame.WriteString(fmt.Sprintf(`\u%04x`, r))
			continue
		}
		frame.WriteRune(r)
	}
	frame.Write(frameEnd)
	return frame.Bytes()
}
