package juice

import (
	"code.google.com/p/go.net/html"
	"io/ioutil"
	"strings"
)

func setAttributeValue(attrName string, val string, n *html.Node) {
	if n == nil {
		return
	}

	for i := range n.Attr {
		if attr := &n.Attr[i]; attr.Key == attrName {
			attr.Val = val
			return
		}
	}

	n.Attr = append(n.Attr, html.Attribute{Key: attrName, Val: val})
}

func stripLetter(content []byte) (byte, []byte) {
	var letter byte
	if len(content) != 0 {
		letter = content[0]
		content = content[1:]
	} else {
		content = []byte{}
	}
	return letter, content
}

func readFile(root string) string {
	content, err := ioutil.ReadFile(root)
	if err != nil {
		panic(err)
	}
	return string(content)
}

func clean(text []byte) string {
	return strings.Trim(strings.Replace(string(text), "\n", "", -1), " ")
}
