package main

import (
	"flag"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
)

const dirtpl_s = `
<!DOCTYPE html>
<html>
  <head>
    <title>Listing</title>
  </head>
  <body>
    <ul>
      {{ range $file := $ }}
	<li><a href="/{{ $file.Name }}">{{ $file.Name }}</a> ({{ $file.Size }} bytes)</li>
	{{ end }}
    </ul>
  </body>
</html>
`

var dirtpl = template.Must(template.New("index").Parse(dirtpl_s))

func main() {
	var dirname, address, filename string
	flag.StringVar(&address, "addr", "", "listen address")
	flag.StringVar(&filename, "file", "", "file name")
	flag.StringVar(&dirname, "dir", "", "file name")
	flag.Parse()

	if address == "" {
		flag.Usage()
		return
	}

	switch {
	case filename != "":
		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Printf("connection from %s\n", r.RemoteAddr)
			http.ServeFile(w, r, filename)
		})
	case dirname != "":
		srv := http.FileServer(http.Dir(dirname))
		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			fmt.Printf("%s %s from %s\n", r.Method, r.URL, r.RemoteAddr)
			if r.URL.Path == "/" {
				// index
				list, err := ioutil.ReadDir(dirname)
				if err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
				dirtpl.Execute(w, list)
			} else {
				srv.ServeHTTP(w, r)
			}
		})
	}
	http.ListenAndServe(address, nil)
}
