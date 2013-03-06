package irc

import (
	"bufio"
	"net"
	"strings"
	"time"
)

type Conn struct {
	SendChannel    chan *Message `json:"-"`
	ReceiveChannel chan *Message `json:"-"`
	socket         net.Conn
	panicHandler   func()
}

type Message struct {
	Source struct {
		Name string `json:"name"`
		User string `json:"user"`
		Host string `json:"host"`
	} `json:"source"`
	Command string   `json:"command"`
	Params  []string `json:"params"`
}

func NewConn(host string, panicHandler func()) (*Conn, error) {
	socket, err := net.Dial("tcp", host)
	if err != nil {
		return nil, err
	}

	conn := Conn{
		SendChannel:    make(chan *Message),
		ReceiveChannel: make(chan *Message),
		socket:         socket,
		panicHandler:   panicHandler,
	}

	go conn.sendLoop()
	go conn.receiveLoop()

	return &conn, nil
}

func (conn *Conn) sendLoop() {
	if conn.panicHandler != nil {
		defer conn.panicHandler()
	}
	defer conn.socket.Close()

	writer := bufio.NewWriter(conn.socket)
	for {
		var message *Message
		var ok bool
		select {
		case message, ok = <-conn.SendChannel:
			if !ok {
				return
			}
		case <-time.After(30 * time.Second):
			message = &Message{Command: "PING", Params: []string{"0"}}
		}

		if len(message.Source.Name) != 0 {
			writer.WriteByte(':')
			writer.WriteString(message.Source.Name)
			if len(message.Source.User) != 0 {
				writer.WriteByte('!')
				writer.WriteString(message.Source.User)
			}
			if len(message.Source.User) != 0 {
				writer.WriteByte('@')
				writer.WriteString(message.Source.Host)
			}
			writer.WriteByte(' ')
		}

		writer.WriteString(message.Command)

		for i, param := range message.Params {
			writer.WriteByte(' ')
			if i == len(message.Params)-1 {
				writer.WriteByte(':')
			}
			writer.WriteString(param)
		}

		writer.WriteByte('\r')
		writer.WriteByte('\n')

		writer.Flush()
	}
}

func (conn *Conn) receiveLoop() {
	if conn.panicHandler != nil {
		defer conn.panicHandler()
	}
	defer func() {
		close(conn.ReceiveChannel)
		err := recover()
		if _, ok := err.(net.Error); !ok {
			panic(err)
		}
	}()

	reader := bufio.NewReader(conn.socket)
	var firstComponent string = ""
	for {
		message := Message{
			Params: make([]string, 0),
		}

		if len(firstComponent) == 0 {
			firstComponent = readUntil(reader, ' ')
		}

		message.Command = firstComponent
		if firstComponent[0] == ':' {
			prefix := firstComponent[1:]

			i := strings.IndexRune(prefix, '@')
			if i != -1 {
				message.Source.Host = prefix[i+1:]
				prefix = prefix[:i]
			}

			i = strings.IndexRune(prefix, '!')
			if i != -1 {
				message.Source.User = prefix[i+1:]
				prefix = prefix[:i]
			}

			message.Source.Name = prefix

			message.Command = readUntil(reader, ' ')
		}

		firstComponent = ""

		for {
			if readByte(reader) == ':' {
				message.Params = append(message.Params, readUntil(reader, '\r'))
				reader.ReadByte() // \n
				break
			}
			reader.UnreadByte()
			param := strings.Split(readUntil(reader, ' '), "\r\n")
			message.Params = append(message.Params, param[0])
			if len(param) > 1 { // workaround for missing trailing space (not RFC conform)
				firstComponent = param[1]
				break
			}
		}

		switch message.Command {
		case "PING":
			conn.Command("PONG", message.Params[0])
		case "PONG":
			// ignored
		default:
			conn.ReceiveChannel <- &message
		}
	}
}

func (conn *Conn) Command(command string, params ...string) {
	conn.SendChannel <- &Message{Command: command, Params: params}
}

func (conn *Conn) Close() error {
	close(conn.SendChannel)
	return nil
}

func readByte(reader *bufio.Reader) byte {
	b, err := reader.ReadByte()
	if err != nil {
		panic(err)
	}
	return b
}

func readUntil(reader *bufio.Reader, delim byte) string {
	str, err := reader.ReadString(delim)
	if err != nil {
		panic(err)
	}
	return str[0 : len(str)-1]
}
