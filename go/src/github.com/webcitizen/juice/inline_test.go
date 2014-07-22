package juice

import (
	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
)

var Html = `
<html>
  <head>
    <title>Newsletters</title>
  </head>
  <body>
    <div class="container"></div>
  </body>
</html>
`

var Css = []byte(`
body {
  margin: 0;
}

.container {
  font-size: 21px;
}

body .container {
  width: 800px;
}
`)

func TestInline(t *testing.T) {
	rules := Parse(Css)
	output := Inline(strings.NewReader(Html), rules)
	assert.Contains(t, output, "style")
	assert.NotContains(t, output, "class")
}
