package cascadia

import (
	"code.google.com/p/go.net/html"
	"strings"
	"testing"
)

func MustParseHTML(doc string) *html.Node {
	dom, err := html.Parse(strings.NewReader(doc))
	if err != nil {
		panic(err)
	}
	return dom
}

var selector = MustCompile(`div.matched`)
var doc = `<!DOCTYPE html>
<html>
<body>
<div class="matched">
  <div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
    <div class="matched"></div>
  </div>
</div>
</body>
</html>
`
var dom = MustParseHTML(doc)

func BenchmarkMatchAll(b *testing.B) {
	var matches []*html.Node
	for i := 0; i < b.N; i++ {
		matches = selector.MatchAll(dom)
	}
	_ = matches
}
