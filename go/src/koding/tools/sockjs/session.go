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
	ReceiveChan                  <-chan interface{}
	receiveChanInternal          chan<- interface{}
	SendChan                     chan<- interface{}
	sendChanInternal             <-chan interface{}
	doConnCheck, connCheckResult chan bool
	readSemaphore                chan bool
	writeMutex                   sync.Mutex
	writeOpenFrame               bool
	lastActivity                 time.Time
	broken                       bool
	cookie                       string
}

func (s *Session) Close() {
	close(s.receiveChanInternal)
}

func (s *Session) ReadMessages(data []byte) bool {
	var obj interface{}
	err := json.Unmarshal(data, &obj)
	if err != nil {
		return false
	}
	if messages, ok := obj.([]interface{}); ok {
		for _, message := range messages {
			s.receiveChanInternal <- message
		}
	} else {
		s.receiveChanInternal <- obj
	}
	return true
}

func (s *Session) WriteFrames(w http.ResponseWriter, streaming, chunked bool, frameStart, frameEnd []byte, escape bool) {
	select {
	case s.readSemaphore <- true:
		// can read
	default:
		s.doConnCheck <- true
		if <-s.connCheckResult {
			w.Write(createFrame('c', `[2010,"Another connection still open"]`, frameStart, frameEnd, escape))
		} else {
			w.Write(createFrame('c', `[1002,"Connection interrupted"]`, frameStart, frameEnd, escape))
		}
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

		var frameWriter io.Writer
		if chunked {
			defer buf.Write([]byte("\r\n"))
			chunkedWriter := httputil.NewChunkedWriter(buf)
			frameWriter = chunkedWriter
			defer chunkedWriter.Close()
		} else {
			frameWriter = buf
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
					s.broken = true
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
	case message, ok := <-s.sendChanInternal:
		if !ok {
			return createFrame('c', `[3000,"Go away!"]`, frameStart, frameEnd, escape), true
		}
		messages = append(messages, message)
	case <-time.After(25 * time.Second):
		return createFrame('h', "", frameStart, frameEnd, escape), false
	}

	for moreMessages := true; moreMessages; {
		select {
		case message, ok := <-s.sendChanInternal:
			if ok {
				messages = append(messages, message)
			} else {
				moreMessages = false
			}
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
		if escape && r == '\\' {
			frame.WriteString(`\\`)
		} else if escape && r == '"' {
			frame.WriteString(`\"`)
		} else if (0x200c <= r && r <= 0x200f) || (0x2028 <= r && r <= 0x202f) || (0x2060 <= r && r <= 0x206f) || (0xfff0 <= r && r <= 0xffff) {
			if escape {
				frame.WriteByte('\\')
			}
			frame.WriteString(fmt.Sprintf(`\u%04x`, r))
		} else {
			frame.WriteRune(r)
		}
	}
	frame.Write(frameEnd)
	return frame.Bytes()
}
