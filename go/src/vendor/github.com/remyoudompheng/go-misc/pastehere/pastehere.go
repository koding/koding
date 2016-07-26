// Package pastehere implements a pastebin-like application.
package pastehere

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"
)

var logger = log.New(os.Stderr, "pastehere ", log.Lshortfile|log.Ldate|log.Ltime)

const homePage = `
<html>
<head>
  <title>Paste Here!</title>
</head>
<body>
  <h1>Paste here!</h1>
  <form action="paste" method="POST" enctype="multipart/form-data">
     <p>Select a file: <input type="file" id="file" name="file" size="30" />
     <input type="submit" value="Upload" id="upload_button"/></p>
  </form>
  <form action="paste" method="POST">
    <textarea id="textarea" name="content" cols="80" rows="20"></textarea>
    <input type="submit" value="Paste" name="process"/>
  </form>
</body>
`

func logRequest(req *http.Request) {
	host, _, _ := net.SplitHostPort(req.RemoteAddr)
	names, _ := net.LookupAddr(host)
	if len(names) > 0 {
		logger.Printf("%s %s from %s (%s)", req.Method, req.URL, req.RemoteAddr, names[0])
	} else {
		logger.Printf("%s %s from %s", req.Method, req.URL, req.RemoteAddr)
	}
}

func sendError(resp http.ResponseWriter, er error) {
	resp.WriteHeader(http.StatusBadRequest)
	fmt.Fprintf(resp, "error: %s", er)
}

var (
	words1   []string
	words2   []string
	words3   []string
	initFlag sync.Once
)

func initWords() {
	f, er := os.Open("/usr/share/dict/words")
	if er != nil {
		panic(er)
	}
	for buf := bufio.NewReader(f); ; {
		line_b, _, er := buf.ReadLine()
		line := string(line_b)
		if er == io.EOF {
			break
		}
		line = strings.TrimSpace(line)
		if ok, _ := regexp.MatchString("[A-Za-z]+", line); !ok {
			continue
		}
		switch {
		case strings.HasSuffix(line, "ity"):
			words1 = append(words1, line)
		case strings.HasSuffix(line, "ness"):
			words2 = append(words2, line)
		case strings.HasSuffix(line, "ism"):
			words3 = append(words3, line)
		}
	}
	sort.Strings(words1)
	sort.Strings(words2)
	sort.Strings(words3)
	logger.Printf("init with %d×%d×%d words", len(words1), len(words2), len(words3))

	rand.Seed(time.Now().UnixNano())
}

type Key [3]uint16

func (k Key) String() string {
	initFlag.Do(initWords)
	a, b, c := k[0], k[1], k[2]
	return words1[a] + "/" + words2[b] + "/" + words3[c]
}

// ChooseKey chooses a random storage key.
func ChooseKey() Key {
	initFlag.Do(initWords)
	a, b, c := rand.Intn(len(words1)), rand.Intn(len(words2)), rand.Intn(len(words3))
	return Key{uint16(a), uint16(b), uint16(c)}
}

// KeyFromStrings parses a triple of strings to a numerical key.
func KeyFromStrings(s [3]string) Key {
	initFlag.Do(initWords)
	a := sort.SearchStrings(words1, s[0])
	b := sort.SearchStrings(words2, s[1])
	c := sort.SearchStrings(words3, s[2])
	return Key{uint16(a), uint16(b), uint16(c)}
}

type Item []byte

var allPastes = map[Key]Item{}

// Home displays pastehere's homepage.
func Home(resp http.ResponseWriter, req *http.Request) {
	go logRequest(req)
	buf := bytes.NewBufferString(homePage)
	io.Copy(resp, buf)
}

// Paste receives a new paste from a client.
func Paste(resp http.ResponseWriter, req *http.Request) {
	go logRequest(req)
	req.ParseForm()
	var contents []byte
	key := ChooseKey()
	if data := req.Form.Get("content"); len(data) > 0 {
		contents = []byte(data)
		logger.Printf("new paste: inline %s %v (%d bytes)",
			key, [3]uint16(key), len(contents))
	} else {
		file, hdr, er := req.FormFile("file")
		if er == nil {
			truncfile := io.LimitReader(file, 512<<10)
			contents, er = ioutil.ReadAll(truncfile)
		}
		if er != nil {
			sendError(resp, er)
			return
		}
		name := hdr.Filename
		mime := hdr.Header.Get("Content-Type")
		logger.Printf("new paste: %s %s %s %v (%d bytes)",
			name, mime, key, [3]uint16(key), len(contents))
	}
	allPastes[key] = Item(contents)
	fmt.Fprintf(resp, "http://%s/pastehere/view/%s", req.Host, key)
}

// View views a selected paste.
func View(resp http.ResponseWriter, req *http.Request) {
	go logRequest(req)
	p := req.URL.Path
	p, _ = filepath.Rel("/pastehere/view", p)
	t := strings.Split(p, "/")
	var dirs [3]string
	if len(t) != 3 {
		er := fmt.Errorf("invalid paste")
		sendError(resp, er)
		return
	}
	copy(dirs[:], t)
	key := KeyFromStrings(dirs)
	logger.Printf("get paste %v %v", dirs, [3]uint16(key))
	paste, ok := allPastes[key]
	if !ok {
		resp.WriteHeader(http.StatusNotFound)
		fmt.Fprint(resp, "no such paste")
		return
	}
	buf := bytes.NewBuffer(paste)
	io.Copy(resp, buf)
}

// Register registers HTTP handlers for pastehere.
func Register(mux *http.ServeMux) {
	if mux == nil {
		mux = http.DefaultServeMux
	}
	mux.HandleFunc("/pastehere/", Home)
	mux.HandleFunc("/pastehere/paste", Paste)
	mux.HandleFunc("/pastehere/view/", View)
}
