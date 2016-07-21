// tinyblog is a trivial blog engine.
package main

import (
	"flag"
	"fmt"
	"log"
	"math/rand"
	"net"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"encoding/json"
	"html/template"
	"net/http"
)

var addr, postdir string

const SOURCE = "https://github.com/remyoudompheng/go-misc/tree/master/tinyblog/tinyblog.go"

func main() {
	rand.Seed(time.Now().UnixNano())
	flag.StringVar(&addr, "http", ":8070", "HTTP server address")
	flag.StringVar(&postdir, "postdir", "", "where to put the posts")
	flag.Parse()

	if postdir == "" {
		flag.Usage()
		return
	}

	log.Printf("starting at %s", addr)

	http.HandleFunc("/", handler)
	http.HandleFunc("/post", handlePost)
	http.Handle("/source", http.RedirectHandler(SOURCE, http.StatusMovedPermanently))
	err := http.ListenAndServe(addr, nil)
	log.Fatal(err)
}

const TITLE = "Tiny blog"

var homeTpl = template.Must(template.
	New("home").
	Funcs(template.FuncMap{"fmtTime": humanTime}).
	Parse(`
<!DOCTYPE html>
<html>
  <head>
    <title>{{ .Title }}</title>
    <link type="text/css" rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.21/themes/ui-lightness/jquery-ui.css">
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.21/jquery-ui.min.js"></script>
    <style type="text/css">
    fieldset label { display: block; }
    fieldset input { display: block; }
    fieldset textarea { display: block; width: 95%; }

    div.post       { margin: 1ex; }
    div.post h2    { margin: 0; }
    div.post p        { display: block; margin: 1ex; }
    div.post .content { font-size: 1em; }
    div.post .meta    { font-size: .7em; }

    div#content { width: 80%; float: left; border-right: solid thin; }
    div#sidebar { width: 17%; float: right; padding: 1em; }
    </style>
    <script type="text/javascript">
    $(document).ready(function() {
        $("#newpost").dialog({
            autoOpen: false,
            modal: true,
            height: "auto",
            width: 600,
            title: "New post",
            buttons: {
                "Send": function() {
                    $.post("/post", {
                        "title": $("#newpost input#title").val(),
                        "text": $("#newpost textarea#text").val(),
                    });
                    $(this).dialog("close");
                },
                "Cancel": function() {
                    $(this).dialog("close");
                },
            },
        });

        $("#newbutton").button();
        $("#newbutton").click(function() {
            $("#newpost").dialog("open");
        });
    });
    </script>
  </head>
  <body>
    <h1>{{ .Title }}</h1>

    <div id="content">
    {{ range $post := .Posts }}
      <div class="post ui-widget ui-widget-content ui-corner-all">
        <h2 class="ui-widget-header">{{ $post.Title }}</h2>
        <p class="content">{{ $post.Text }}</p>
        <p class="meta">Posted <span class="when">{{ fmtTime $post.When }}</span>
          by {{ $post.Author }}</p>
      </div>
    {{ end }}
    </div>

    <div id="sidebar">
      <button id="newbutton">New post</button>

      <div id="newpost">
      <form>
      <fieldset>
      <label for="title">Title</label>
      <input type="text" id="title" class="text ui-widget-content ui-corner-all" value="Titre">
      <label for="text">Content</label>
      <textarea type="text" id="text"
       class="text ui-widget-content ui-corner-all"
       rows="5">Your post.</textarea>
      </fieldset>
      </form>
      </div>

      <div><p><a href="/source">Source code</a></p></div>
    </div>
  </body>
</html>
`))

func humanTime(t time.Time) string {
	elapsed := time.Since(t)
	switch {
	case elapsed < time.Minute:
		return fmt.Sprintf("%d seconds ago", elapsed/time.Second)
	case elapsed < time.Hour:
		return fmt.Sprintf("%d minutes ago", elapsed/time.Minute)
	case elapsed < 24*time.Hour:
		return fmt.Sprintf("%d hours ago", elapsed/time.Hour)
	}
	return t.Format("Mon 2 Jan 2006 at 15:04:05 MST")
}

func logRequest(req *http.Request) {
	log.Printf("%s %s from %s", req.Method, req.URL, req.RemoteAddr)
}

func logError(w http.ResponseWriter, req *http.Request, code int, err error) {
	http.Error(w, err.Error(), code)
	log.Printf("%s %s from %s: %s", req.Method, req.URL, req.RemoteAddr, err)
}

type Post struct {
	Title  string
	Text   string
	Author string
	When   time.Time
}

func handler(w http.ResponseWriter, req *http.Request) {
	logRequest(req)
	type pagedata struct {
		Title string
		Posts []Post
	}
	var err error
	data := pagedata{
		Title: TITLE,
	}
	data.Posts, err = loadPosts()
	sort.Sort(byDescDate(data.Posts))
	if err != nil {
		logError(w, req, http.StatusInternalServerError, err)
		return
	}
	err = homeTpl.Execute(w, data)
	if err != nil {
		logError(w, req, http.StatusInternalServerError, err)
	}
}

type byDescDate []Post

func (s byDescDate) Len() int           { return len(s) }
func (s byDescDate) Less(i, j int) bool { return s[i].When.After(s[j].When) }
func (s byDescDate) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

func loadPosts() (posts []Post, err error) {
	files, err := filepath.Glob(filepath.Join(postdir, "*.json"))
	if err != nil {
		return nil, fmt.Errorf("could not open repository: %s", err)
	}
	for _, f := range files {
		in, err := os.Open(f)
		if err != nil {
			// FIXME
			continue
		}
		var post Post
		err = json.NewDecoder(in).Decode(&post)
		if err != nil {
			// FIXME
			continue
		}
		posts = append(posts, post)
	}
	return posts, nil
}

func handlePost(w http.ResponseWriter, req *http.Request) {
	logRequest(req)
	author, _, _ := net.SplitHostPort(req.RemoteAddr)
	addrs, err := net.LookupAddr(author)
	if err != nil && len(addrs) > 0 {
		author = addrs[0]
	}

	title := req.FormValue("title")
	text := req.FormValue("text")
	title = strings.TrimSpace(title)
	text = strings.TrimSpace(text)
	if title == "" || text == "" {
		err = fmt.Errorf("empty title or text")
		logError(w, req, http.StatusBadRequest, err)
		return
	}
	post := Post{
		Title:  title,
		Text:   text,
		Author: author,
		When:   time.Now(),
	}
	err = savePost(post)
	if err != nil {
		logError(w, req, http.StatusInternalServerError, err)
		return
	}
	w.Write([]byte("OK"))
}

func savePost(post Post) error {
	now := post.When.Format("20060102-150405")
	uuid := fmt.Sprintf("%012x", rand.Int63n(1<<48))
	name := fmt.Sprintf("post-%s-%s.json", now, uuid)
	w, err := os.Create(filepath.Join(postdir, name))
	if err != nil {
		return err
	}
	err = json.NewEncoder(w).Encode(post)
	return err
}
