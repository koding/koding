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
	ReceiveChan, SendChan        chan interface{}
	DoConnCheck, ConnCheckResult chan bool
	ReadSemaphore                chan bool
	WriteMutex                   sync.Mutex
	WriteOpenFrame               bool
	LastActivity                 time.Time
	Broken                       bool
	Cookie                       string
}

func (session *Session) readMessages(data []byte) bool {
	var obj interface{}
	err := json.Unmarshal(data, &obj)
	if err != nil {
		return false
	}
	if messages, ok := obj.([]interface{}); ok {
		for _, message := range messages {
			session.ReceiveChan <- message
		}
	} else {
		session.ReceiveChan <- obj
	}
	return true
}

func (session *Session) writeFrames(w http.ResponseWriter, streaming, chunked bool, frameStart, frameEnd []byte, escape bool) {
	select {
	case session.ReadSemaphore <- true:
		// can read
	default:
		session.DoConnCheck <- true
		if <-session.ConnCheckResult {
			w.Write(createFrame('c', `[2010,"Another connection still open"]`, frameStart, frameEnd, escape))
		} else {
			w.Write(createFrame('c', `[1002,"Connection interrupted"]`, frameStart, frameEnd, escape))
		}
		return
	}
	defer func() {
		<-session.ReadSemaphore
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
			case <-session.DoConnCheck:
				_, err := conn.Write([]byte("0\r\n"))
				if err != nil {
					session.ConnCheckResult <- false
					session.Broken = true
					return
				}
				session.ConnCheckResult <- true
			}
		}
	}()

	var frame []byte
	var closed bool
	total := 0
	for !closed && total < session.Service.StreamLimit {
		frame, closed = session.createNextFrame(frameStart, frameEnd, escape)
		total += len(frame)
		c <- frame
		if !streaming {
			break
		}
	}
}

func (session *Session) createNextFrame(frameStart, frameEnd []byte, escape bool) ([]byte, bool) {
	if session.WriteOpenFrame {
		session.WriteOpenFrame = false
		return createFrame('o', "", frameStart, frameEnd, escape), false
	}

	messages := make([]interface{}, 0)
	select {
	case message, ok := <-session.SendChan:
		if !ok {
			return createFrame('c', `[3000,"Go away!"]`, frameStart, frameEnd, escape), true
		}
		messages = append(messages, message)
	case <-time.After(25 * time.Second):
		return createFrame('h', "", frameStart, frameEnd, escape), false
	}

	for moreMessages := true; moreMessages; {
		select {
		case message, ok := <-session.SendChan:
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
