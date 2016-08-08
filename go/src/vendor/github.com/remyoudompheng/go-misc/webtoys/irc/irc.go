package irc

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"net/textproto"
	"os"
	"strings"
	"time"

	"code.google.com/p/go.net/websocket"
)

var logger = log.New(os.Stderr, "irc ", log.LstdFlags|log.Lshortfile)

func Register(mux *http.ServeMux) {
	if mux == nil {
		mux = http.DefaultServeMux
	}
	mux.HandleFunc("/irc", home)
	mux.Handle("/irc/ws", websocket.Handler(connect))
	log.Printf("registered irc at /irc and /irc/ws")
}

const (
	nick    = "remy_web"
	server  = "chat.freenode.net:6667"
	channel = "#arch-fr-off"
)

type Client struct {
	*textproto.Conn
	lines chan Event
}

func NewClient(server, nick string) (c *Client, err error) {
	conn, err := textproto.Dial("tcp", server)
	if err != nil {
		return
	}
	// RFC 2812, 3.1.2
	conn.Cmd("NICK %s", nick)
	// RFC 2812, 3.1.3
	conn.Cmd("USER %s %d %s :%s", "webtoy", 0, "*", "Anonymous Guest")
	c = &Client{
		Conn:  conn,
		lines: make(chan Event, 8),
	}
	go c.ReadLines()
	return c, nil
}

func (cli *Client) Send(cmd string, args ...interface{}) {
	cli.Cmd("%s %s", cmd, fmt.Sprint(args))
}

func (cli *Client) ReadLines() error {
	defer close(cli.lines)
	for {
		line, err := cli.ReadLine()
		if err != nil {
			return err
		}
		prefix, command, args := parseIrcLine(line)
		cli.HandleEvent(command, prefix, args)
	}
}

type Event struct {
	Line    string `json:"line,omitempty"`
	Message string `json:"system,omitempty"`
}

func parseIrcLine(line string) (prefix, command string, args []string) {
	if line == "" {
		logger.Printf("cannot parse %q", line)
		return
	}
	var hasPrefix bool
	if line[0] == ':' {
		hasPrefix = true
	}
	var items []string
	colon := strings.Index(line[1:], ":")
	if colon >= 0 {
		// long arg
		items = strings.Fields(line[:colon+1])
		items = append(items, line[colon+2:])
	} else {
		items = strings.Fields(line)
	}
	if len(items) < 2 {
		logger.Printf("cannot parse %q", line)
		return
	}
	if hasPrefix {
		return items[0][1:], items[1], items[2:]
	}
	return "", items[0], items[1:]
}

var (
	messageTplS = `<span class="date">{{ .Time }}</span>
	<span class="to">{{ .To }}</span>
	<span class="from" style="{{ colorNick .From }}">{{ .From }}</span>
	<span class="message">{{ .Message }}</span>`
	messageTpl = template.Must(template.New("line").
			Funcs(template.FuncMap{"colorNick": colorNick}).
			Parse(messageTplS))
)

func colorNick(s string) template.CSS {
	hue := uint(0)
	for _, c := range s {
		hue *= 17
		hue += uint(c)
	}
	style := fmt.Sprintf("color: hsl(%d, 40%%, 50%%)", hue%360)
	return template.CSS(style)
}

func (cli *Client) HandleEvent(command, prefix string, args []string) {
	switch command {
	case "PRIVMSG":
		if i := strings.Index(prefix, "!"); i >= 0 {
			prefix = prefix[:i]
		}
		buf := new(bytes.Buffer)
		type Msg struct{ From, To, Time, Message string }
		var msg Msg
		if len(args) != 2 {
			msg = Msg{From: prefix, To: "", Time: time.Now().Format("15:04:05"),
				Message: fmt.Sprintf("%v", args)}
		} else {
			msg = Msg{From: prefix, To: args[0], Time: time.Now().Format("15:04:05"),
				Message: args[1]}
		}
		err := messageTpl.Execute(buf, msg)
		if err == nil {
			cli.lines <- Event{Line: buf.String()}
		} else {
			cli.lines <- Event{Message: err.Error()}
		}
	case "PING":
		if len(args) > 0 {
			cli.Cmd("PONG %s", args[0])
		}
		cli.lines <- Event{Message: fmt.Sprintf("/%s %v", command, args)}
	default:
		cli.lines <- Event{Message: fmt.Sprintf("/%s %v", command, args)}
	}
}

type Form struct {
	Nick, Chan, Serv string
}

func loggedmessage(conn *websocket.Conn, format string, args ...interface{}) {
	logger.Printf("/irc/ws: "+format, args...)
	websocket.Message.Send(conn, fmt.Sprintf(format, args...))
}

func connect(conn *websocket.Conn) {
	logger.Printf("websocket from %s", conn.RemoteAddr())
	defer conn.Close()
	var form []byte
	var f Form
	if err := websocket.Message.Receive(conn, &form); err != nil {
		return
	}
	if err := json.Unmarshal(form, &f); err != nil {
		loggedmessage(conn, "invalid request: %s (%s)", form, err)
		return
	}
	loggedmessage(conn, "opening connection to %s for %s", f.Serv, f.Nick)
	client, err := NewClient(f.Serv, f.Nick)
	if err != nil {
		websocket.Message.Send(conn, "connection error: "+err.Error())
		return
	}
	defer func() {
		logger.Printf("closing connection to %s for %s", f.Serv, f.Nick)
		websocket.Message.Send(conn, "connection closed.")
		client.Cmd("QUIT :%s", "client left.")
		client.Close()
	}()
	logger.Printf("joining channel %s", f.Chan)
	client.Cmd("JOIN %s", f.Chan)
	for line := range client.lines {
		// send {"system": message} or {"line": message}
		websocket.JSON.Send(conn, line)
	}
}

const ircTemplate = `<!DOCTYPE html>
<html>
<head>
	<title>IRC Chat</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
	<script type="text/javascript">
  	$(function() {
		var conn;
		var WS = window["WebSocket"] ? WebSocket : MozWebSocket;

		function connect() {
			$("#lines").empty();
			var params = {};
			params.Nick = $("#nick").val();
			params.Chan = $("#channel").val();
			params.Serv = $("#server").val();
			conn = new WS("ws://{{ $ }}/irc/ws");
			conn.onopen = function () {
				conn.send(JSON.stringify(params));
			};
			conn.onmessage = display;
			return false;
		};

		function display(msg) {
			var event = JSON.parse(msg.data);
			if (event.line) {
				$("#lines").append($("<li/>").html(event.line));
			}
			if (event.system) {
				// Only keep 50 last messages.
				$("#system").append($("<li/>").html(event.system));
				$("#system li").slice(0,-50).remove();
			}
		};

		$("#form").submit(connect);

		$.unload(function() {
			if (conn) {
				conn.close();
			}
		});
	});
	</script>
	<style type="text/css">
		div#top, div#main {
			position: fixed;
			left: 0;
			width: 100%;
		}
		div#top {
			top: 0;
			height: 20em;
		}
		div#main {
			top: 20em;
			bottom: 0;
		}
		ul {
			border: solid 1px;
			list-style: none;
			overflow: auto;
		}
		form#form {
			height: 8em;
		}
		ul#system, ul#lines {
			position: absolute;
			left: 2%;
			right: 2%;
			bottom: 1ex;
		}
		ul#system {
			top: 8em;
		}
		ul#lines {
			top: 0%;
		}
		ul li {
			font-family: monospace, Courier;
		}
		span.from, span.to {
			display: inline-block;
			width: 16ex;
			overflow: hidden;
		}
	</style>
</head>
<body>
	<div id="top">
		<form id="form">
			<h1>IRC Chat</h1>
			Nick:
			<input type="text" id="nick" size="32" value="guest">
			Channel:
			<input type="text" id="channel" size="32" value="#arch-fr-off"><br/>
			Server:
			<input type="text" id="server" size="32" value="chat.freenode.net:6667">
			<input type="submit" value="Connect">
		</form>

		<ul id="system">
		</ul>
	</div>
	<div id="main">
		<ul id="lines">
		</ul>
	</div>
</body>
</html>
`

var ircTpl = template.Must(template.New("irc").Parse(ircTemplate))

func home(resp http.ResponseWriter, req *http.Request) {
	logger.Printf("GET %s from %s", req.URL, req.RemoteAddr)
	err := ircTpl.Execute(resp, req.Host)
	if err != nil {
		logger.Printf("error: %s", err)
	}
}
