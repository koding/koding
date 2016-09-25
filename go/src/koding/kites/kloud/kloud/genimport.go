// +build ignore

package main

import (
	"flag"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
)

var output = flag.String("o", "-", "")

var t = template.Must(template.New("").Parse(`package kloud

import (
{{range $_, $import := .}}	_ "{{$import}}"
{{end}})
`))

func main() {
	flag.Parse()

	var imports []string

	d, err := os.Open(filepath.FromSlash("../provider"))
	if err != nil {
		log.Fatal(err)
	}
	defer d.Close()

	fis, err := d.Readdir(-1)
	if err != nil {
		log.Fatal(err)
	}

	for _, fi := range fis {
		if !fi.IsDir() {
			continue
		}

		name := filepath.Base(fi.Name())

		if strings.HasPrefix(name, "_") {
			continue
		}

		if _, err := os.Stat(filepath.Join(fi.Name(), ".ignore")); err == nil {
			continue
		}

		imports = append(imports, "koding/kites/kloud/provider/"+name)
	}

	sort.Strings(imports)

	w := os.Stdout

	if *output != "-" && *output != "" {
		f, err := os.Create(*output)
		if err != nil {
			log.Fatal(err)
		}

		w = f
	}

	if err := t.Execute(w, imports); err != nil {
		log.Fatal(err)
	}

	if err := w.Close(); err != nil {
		log.Fatal(err)
	}
}
