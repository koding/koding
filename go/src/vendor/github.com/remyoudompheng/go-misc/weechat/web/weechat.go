// weechat/web implements a web interface for weechat.
package web

import (
	"bytes"
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"

	ws "code.google.com/p/go.net/websocket"
	"github.com/remyoudompheng/go-misc/weechat"
)

func Register(mux *http.ServeMux) {
	if mux == nil {
		mux = http.DefaultServeMux
	}
	mux.HandleFunc("/weechat", handleHome)
	mux.HandleFunc("/weechat/buflines", handleLines)
	mux.Handle("/weechat/ws", ws.Handler(handleWebsocket))
}

var (
	weechatAddr string
	weechatConn *weechat.Conn
	initOnce    sync.Once
)

func init() {
	flag.StringVar(&weechatAddr, "weechat.relay", "", "address of Weechat relay")
}

func initWeechat() {
	conn, err := weechat.Dial(weechatAddr)
	if err != nil {
		log.Fatal(err)
	}
	weechatConn = conn
}

const homeTplStr = `
<!DOCTYPE html>
<html>
  <head>
    <title>Weechat</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/libs/bootstrap/css/bootstrap.min.css" rel="stylesheet">
    <script src="/libs/jquery.min.js"></script>
    <script src="/libs/bootstrap/js/bootstrap.min.js"></script>
    <script type="text/javascript">
    $(document).ready(function() {
      $("ul#buffers li").click(function() {
            $.get("/weechat/buflines",
            {"buffer": $(this).attr("addr")},
            function(data) {
                  $("#lines").html(data);
            });
      });
    });
    </script>
    <style type="text/css">
    body { padding-top: 60px; }
    div#lines div.irc-date { text-size: 70%; }
    </style>
  </head>
  <body style="padding-top: 60px;">
    <div class="container">
    <div class="navbar navbar-inverse navbar-fixed-top">
      <a class="navbar-brand" href="/">Rémy's Webtoys</a>
      <div class="nav-collapse collapse">
        <ul class="nav navbar-nav">
          <li><a href="/">Home</a></li>
          <li class="active"><a href="#">Weechat</a></li>
        </ul>
      </div>
    </div>
    </div>

    <div class="container">
    <div class="row">
      <div class="col-lg-3"><!-- left, vertical -->
      <div class="sidebar-nav well">
        <ul class="nav nav-list" id="buffers">
          {{ range $buf := $ }}
          <li addr="{{ $buf.Self | printf "%x" }}"><a href="javascript:void(0);">{{ $buf.Name }}</a></li>
          {{ end }}
        </ul>
      </div>
      </div>

      <div class="col-lg-9">
        <div class="row">
        <div class="col-12 well well-large"><!-- title -->
          <h1>Weechat</h1>
        </div>
        </div>

        <div class="row">
        <div class="col-12" id="lines">
        <!-- buffer lines -->
        </div>
        </div>
      </div>
    </div>
    </div>
  </body>
</html>
`

var homeTpl = template.Must(template.New("home").Parse(homeTplStr))

func handleHome(w http.ResponseWriter, req *http.Request) {
	initOnce.Do(initWeechat)
	bufs, err := weechatConn.ListBuffers()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	homeTpl.Execute(w, bufs)
}

const linesTplStr = `
{{ range $line := $ }}
{{ if $line.Displayed }}
<div class="row">
  <div class="col-lg-10">
  {{ if isAction $line }}<span class="label label-success">{{ htmlMessage $line }}</span>
  {{ else }}{{ if isSystem $line }}<span class="label label-info">{{ $line.Prefix }} {{ $line.Message }}</span>
  {{ else }}<span class="label">{{ $line.Prefix }}</span> {{ htmlMessage $line }}
  {{ end }}{{ end }}
  </div>
  <div class="col-lg-2 irc-date">{{ humanTime $line.Date }}</div>
</div>
{{ end }}{{ end }}
`

var linesTpl = template.Must(template.New("lines").
	Funcs(template.FuncMap{
	"isAction": isAction, "isSystem": isSystem,
	"humanTime": humanTime, "htmlMessage": htmlMessage}).
	Parse(linesTplStr))

func isAction(line weechat.LineData) bool { return line.Prefix == " *" }

func isSystem(line weechat.LineData) bool {
	return line.Prefix == "" ||
		len(line.Prefix) <= 3 && strings.Contains(line.Prefix, "--")
}

func humanTime(t time.Time) string {
	if t.IsZero() || t.Unix() == 0 {
		return ""
	}
	now := time.Now()
	switch laps := now.Sub(t); {
	case laps <= 0:
		return t.Format("2006-01-02 15:04:05")
	case laps <= time.Minute:
		return fmt.Sprintf("%d secs ago, %s", int(laps.Seconds()), t.Format("15:04:05"))
	case laps <= time.Hour:
		return fmt.Sprintf("%d min. ago, %s", int(laps.Seconds()/60), t.Format("15:04:05"))
	}
	return t.Format("Mon 2, 15:04")
}

func htmlMessage(line weechat.LineData) template.HTML {
	if !strings.Contains(line.Message, "://") {
		// fast path.
		return template.HTML(template.HTMLEscapeString(line.Message))
	}
	buf := new(bytes.Buffer)
	for msg := line.Message; len(msg) > 0; {
		idx := strings.Index(msg, "://")
		switch {
		case idx >= 4 && msg[idx-4:idx] == "http":
			buf.WriteString(msg[:idx-4])
			msg = msg[idx-4:]
		case idx >= 5 && msg[idx-5:idx] == "https":
			buf.WriteString(msg[:idx-5])
			msg = msg[idx-5:]
		default:
			buf.WriteString(msg)
			msg = ""
			continue
		}
		space := strings.IndexFunc(msg, unicode.IsSpace)
		if space < 0 {
			space = len(msg)
		}
		u := msg[:space]
		msg = msg[space:]
		if _, err := url.Parse(u); err == nil {
			fmt.Fprintf(buf, `<a href="%s">%s</a>`, u, u)
		} else {
			buf.WriteString(u)
		}
	}
	return template.HTML(buf.String())
}

func handleLines(w http.ResponseWriter, req *http.Request) {
	initOnce.Do(initWeechat)
	req.ParseForm()
	bufHex := req.Form.Get("buffer")
	bufId, err := strconv.ParseUint(bufHex, 16, 64)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Get latest lines in reverse order.
	lines, err := weechatConn.BufferData(bufId, -256, "date,prefix,message,displayed")
	revlines := make([]weechat.LineData, 0, 256)
	for i := range lines {
		l := lines[len(lines)-1-i]
		l.Clean()
		revlines = append(revlines, l)
	}
	err = linesTpl.Execute(w, revlines)
	if err != nil {
		log.Printf("template error: %s", err)
	}
}

func handleWebsocket(conn *ws.Conn) {
}
