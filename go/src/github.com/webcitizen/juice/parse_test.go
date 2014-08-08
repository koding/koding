package juice

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestParse(t *testing.T) {
	blocks := Parse(Css)

	body := blocks[0]
	container := blocks[1]
	margin := body.Properties[0]
	fontSize := container.Properties[0]

	assert.Equal(t, body.Selector, "body")
	assert.Equal(t, container.Selector, ".container")

	assert.Equal(t, margin.Name, "margin")
	assert.Equal(t, margin.Value, " 0")

	assert.Equal(t, fontSize.Name, "font-size")
	assert.Equal(t, fontSize.Value, " 21px")
}
