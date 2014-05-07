// Utility functions for working with text
package sanitize

import (
	"testing"
)

var Format string = "\ninput:    %q\nexpected: %q\noutput:   %q"

type Test struct {
	input    string
	expected string
}

var urls = []Test{
	{"ReAd ME.md", "read-me.md"},
	{"E88E08A7-279C-4CC1-8B90-86DE0D70443C.html", "e88e08a7-279c-4cc1-8b90-86de0d70443c.html"},
	{"/user/test/I am a long url's_-?ASDF@£$%£%^testé.html", "/user/test/i-am-a-long-urls-asdfteste.html"},
	{"/../../4-icon.jpg", "/4-icon.jpg"},
	{"/Images/../4-icon.jpg", "/images/4-icon.jpg"},
	{"../4 icon.*", "/4-icon."},
	{"Spac ey/Name/test før url", "spac-ey/name/test-foer-url"},
	{"../*", "/"},
}

func TestPath(t *testing.T) {
	for _, test := range urls {
		output := Path(test.input)
		if output != test.expected {
			t.Fatalf(Format, test.input, test.expected, output)
		}
	}
}

var fileNames = []Test{
	{"ReAd ME.md", "read-me.md"},
	{"/var/etc/jobs/go/go/src/pkg/foo/bar.go", "bar.go"},
	{"I am a long url's_-?ASDF@£$%£%^é.html", "i-am-a-long-urls-asdf.html"},
	{"/../../4-icon.jpg", "4-icon.jpg"},
	{"/Images/../4-icon.jpg", "4-icon.jpg"},
	{"../4 icon.jpg", "4-icon.jpg"},
}

func TestName(t *testing.T) {
	for _, test := range fileNames {
		output := Name(test.input)
		if output != test.expected {
			t.Fatalf(Format, test.input, test.expected, output)
		}
	}
}

// Test with some malformed or malicious html
// NB because we remove all tokens after a < until the next >
// and do not attempt to parse, we should be safe from invalid html, 
// but will sometimes completely empty the string if we have invalid input
var html = []Test{
	{`&amp;#x000D;`, `&amp;amp;#x000D;`},
	{`<invalid attr="invalid"<,<p><p><p><p><p>`, ""},
	{"<b><p>Bold </b> Not bold</p>\nAlso not bold.", "Bold  Not bold\nAlso not bold."},
	{"`FOO&#x000D;ZOO", "`FOO&amp;#x000D;ZOO"},
	{`<script><!--<script </s`, ""},
	{`<a href="/" alt="Fab.com | Aqua Paper Map 22"" title="Fab.com | Aqua Paper Map 22" - fab.com">test</a>`, "test"},
	{"<p</p>?> or <p id=0</p> or <<</>><ASDF><@$!@£M<<>>>>>>>>>>>>>><>***************aaaaaaaaaaaaaaaaaaaaaaaaaa>", " or ***************aaaaaaaaaaaaaaaaaaaaaaaaaa"},
	{"<p>Some text</p>", "Some text\n"},
	{"Something</br>Some more", "Something\nSome more"},
	{"Something<br/>Some more", "Something\nSome more"},
	{`<a href="http://www.example.com"?>This is a 'test' of <b>bold</b> &amp; <i>italic</i></a> </br> invalid markup.<//data>><alert><script CDATA[:Asdfjk2354115nkjafdgs]>. <div src=">">><><img src="">`, "This is a 'test' of bold & italic \n invalid markup.. \""},
	{"<![CDATA[<sender>John Smith</sender>]]>", "John Smith]]"},
	{"<!-- <script src='blah.js' data-rel='fsd'> --> This is text", " -- This is text"},
	{"<style>body{background-image:url(http://www.google.com/intl/en/images/logo.gif);}</style>", "body{background-image:url(http://www.google.com/intl/en/images/logo.gif);}"},
	{`&lt;iframe src="" attr=""&gt;>>>>>`, `&amp;lt;iframe src="" attr=""&amp;gt;`},
	{`<IMG """><SCRIPT>alert("XSS")</SCRIPT>">`, `alert("XSS")"`},
	{`<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>`, ``},
	{`<IMG SRC=JaVaScRiPt:alert('XSS')&gt;`, ``},
	{`<IMG SRC="javascript:alert('XSS')" <test`, ``},
	{`&gt test &lt`, `&amp;gt test &amp;lt`},
}

func TestHTML(t *testing.T) {
	for _, test := range html {
		output := HTML(test.input)
		if output != test.expected {
			t.Fatalf(Format, test.input, test.expected, output)
		}
	}
}
