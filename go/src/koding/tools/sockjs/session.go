package sockjs

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"sync"
	"time"
)

type Session struct {
	Service                      *Service
	ReceiveChan                  chan interface{}
	sendChan                     chan interface{}
	doConnCheck, connCheckResult chan bool
	readSemaphore                chan bool
	writeOpenFrame               bool
	lastSendTime                 time.Time
	closed                       bool
	closeMutex                   sync.Mutex
	cookie                       string
}

func newSession(service *Service) *Session {
	return &Session{
		Service:         service,
		ReceiveChan:     make(chan interface{}, 1024),
		sendChan:        make(chan interface{}, 1024),
		doConnCheck:     make(chan bool),
		connCheckResult: make(chan bool),
		readSemaphore:   make(chan bool, 1),
		writeOpenFrame:  true,
		lastSendTime:    time.Now(),
		cookie:          "JSESSIONID=dummy",
	}
}

func (s *Session) Send(data interface{}) bool {
	if s.closed {
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
	go func() {
		s.closeMutex.Lock()
		defer s.closeMutex.Unlock()
		if !s.closed {
			s.closed = true
			close(s.ReceiveChan)
		}
	}()
}

func (s *Session) ReadMessages(data []byte) bool {
	s.closeMutex.Lock()
	defer s.closeMutex.Unlock()
	if s.closed {
		return true
	}

	var obj interface{}
	err := json.Unmarshal(data, &obj)
	if err != nil {
		return false
	}

	if messages, ok := obj.([]interface{}); ok {
		for _, message := range messages {
			s.ReceiveChan <- message
		}
		return true
	}

	s.ReceiveChan <- obj
	return true
}

func (s *Session) WriteFrames(w http.ResponseWriter, streaming, chunked bool, frameStart, frameEnd []byte, escape bool) {
	select {
	case s.readSemaphore <- true:
		// can read
	default:
		s.doConnCheck <- true
		errMsg := `[1002,"Connection interrupted"]`
		if <-s.connCheckResult {
			errMsg = `[2010,"Another connection still open"]`
		}
		w.Write(createFrame('c', errMsg, frameStart, frameEnd, escape))
		return
	}
	defer func() {
		<-s.readSemaphore
	}()

	c := make(chan []byte)
	defer close(c)
	go func() {
		conn, buf, _ := w.(http.Hijacker).Hijack()
		defer conn.Close()
		defer buf.Flush()

		var frameWriter io.Writer = buf
		if chunked {
			defer buf.Write([]byte("\r\n"))
			chunkedWriter := httputil.NewChunkedWriter(buf)
			frameWriter = chunkedWriter
			defer chunkedWriter.Close()
		}

		for {
			select {
			case frame, ok := <-c:
				if !ok {
					return
				}
				frameWriter.Write(frame)
				if streaming {
					buf.Flush()
				}
			case <-s.doConnCheck:
				_, err := conn.Write([]byte("0\r\n"))
				if err != nil {
					s.connCheckResult <- false
					s.Close()
					return
				}
				s.connCheckResult <- true
			}
		}
	}()

	var frame []byte
	var closed bool
	total := 0
	for !closed && total < s.Service.StreamLimit {
		frame, closed = s.CreateNextFrame(frameStart, frameEnd, escape)
		total += len(frame)
		c <- frame
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

	data, _ := json.Marshal(messages)
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
