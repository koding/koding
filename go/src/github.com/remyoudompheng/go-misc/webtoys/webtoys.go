// Copyright 2012 Rémy Oudompheng. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"

	"github.com/remyoudompheng/go-misc/pastehere"
	"github.com/remyoudompheng/go-misc/webclock"
	"github.com/remyoudompheng/go-misc/weblibs"
	"github.com/remyoudompheng/go-misc/webtoys/irc"
	_ "github.com/remyoudompheng/go-misc/webtoys/vdeck"
)

func init() {
	log.SetPrefix("webtoys ")
	log.SetFlags(log.LstdFlags)

	pastehere.Register(nil) // at /pastehere/
	webclock.Register(nil)  // at /webclock/
	irc.Register(nil)       // at /irc/
	err := weblibs.RegisterAll(nil)
	if err != nil {
		panic(err)
	}
}

var toys = []string{
	"irc",
	"pastehere",
	"vdeck",
	"webclock",
}

const indexTplString = `<!DOCTYPE html>
<html>
<head>
	<title>Rémy's Webtoys</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
	<h1>Rémy's Webtoys</h1>

	<ul>
	{{ range $ }}
	<li><a href="/{{ . }}">{{ . }}</a></li>
	{{ end }}
	</ul>
</body>
</html>
`

var indexTpl = template.Must(template.New("index").Parse(indexTplString))

func index(resp http.ResponseWriter, req *http.Request) {
	log.Printf("GET %s from %s", req.URL, req.RemoteAddr)
	if req.URL.Path != "/" {
		resp.WriteHeader(http.StatusNotFound)
		fmt.Fprintf(resp, "No such page: %s", req.URL.Path)
		return
	}
	indexTpl.Execute(resp, toys)
}

func init() {
	http.HandleFunc("/", index)
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
}

func main() {
	var address string
	flag.StringVar(&address, "http", ":8080", "listen address")
	flag.Parse()
	if address == "" {
		flag.Usage()
		return
	}
	log.Printf("start listening at %s", address)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		log.Fatal(err)
	}
}
