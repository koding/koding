## Overview

mustache.go is an implementation of the mustache template language in Go. It is better suited for website templates than Go's native pkg/template. mustache.go is fast -- it parses templates efficiently and stores them in a tree-like structure which allows for fast execution. 

## Documentation

For more information about mustache, check out the [mustache project page](http://github.com/defunkt/mustache) or the [mustache manual](http://mustache.github.com/mustache.5.html).

Also check out some [example mustache files](http://github.com/defunkt/mustache/tree/master/examples/)

## Installation
To install mustache.go, simply run `go get github.com/hoisie/mustache`. To use it in a program, use `import "github.com/hoisie/mustache"`

## Usage
There are four main methods in this package:

    func Render(data string, context ...interface{}) string
    
    func RenderFile(filename string, context ...interface{}) string
    
    func ParseString(data string) (*template, os.Error)
    
    func ParseFile(filename string) (*template, os.Error) 

There are also two additional methods for using layouts (explained below).

The Render method takes a string and a data source, which is generally a map or struct, and returns the output string. If the template file contains an error, the return value is a description of the error. There's a similar method, RenderFile, which takes a filename as an argument and uses that for the template contents. 

    data := mustache.Render("hello {{c}}", map[string]string{"c":"world"})
    println(data)


If you're planning to render the same template multiple times, you do it efficiently by compiling the template first:

    tmpl,_ := mustache.ParseString("hello {{c}}")
    var buf bytes.Buffer;
    for i := 0; i < 10; i++ {
        tmpl.Render (map[string]string { "c":"world"}, &buf)  
    }

For more example usage, please see `mustache_test.go`

## Escaping

mustache.go follows the official mustache HTML escaping rules. That is, if you enclose a variable with two curly brackets, `{{var}}`, the contents are HTML-escaped. For instance, strings like `5 > 2` are converted to `5 &gt; 2`. To use raw characters, use three curly brackets `{{{var}}}`.

## Layouts

It is a common pattern to include a template file as a "wrapper" for other templates. The wrapper may include a header and a footer, for instance. Mustache.go supports this pattern with the following two methods:

    func RenderInLayout(data string, layout string, context ...interface{}) string
    
    func RenderFileInLayout(filename string, layoutFile string, context ...interface{}) string
    
The layout file must have a variable called `{{content}}`. For example, given the following files:

layout.html.mustache:

    <html>
    <head><title>Hi</title></head>
    <body>
    {{{content}}}
    </body>
    </html>

template.html.mustache:

    <h1> Hello World! </h1>

A call to `RenderFileInLayout("template.html.mustache", "layout.html.mustache", nil)` will produce:

    <html>
    <head><title>Hi</title></head>
    <body>
    <h1> Hello World! </h1>
    </body>
    </html>

## A note about method receivers

Mustache.go supports calling methods on objects, but you have to be aware of Go's limitations. For example, lets's say you have the following type:

    type Person struct {
        FirstName string
        LastName string    
    }

    func (p *Person) Name1() string {
        return p.FirstName + " " + p.LastName
    }

    func (p Person) Name2() string {
        return p.FirstName + " " + p.LastName
    }

While they appear to be identical methods, `Name1` has a pointer receiver, and `Name2` has a value receiver. Objects of type `Person`(non-pointer) can only access `Name2`, while objects of type `*Person`(person) can access both. This is by design in the Go language.

So if you write the following:

    mustache.Render("{{Name1}}", Person{"John", "Smith"})

It'll be blank. You either have to use `&Person{"John", "Smith"}`, or call `Name2`

## Supported features

* Variables
* Comments
* Change delimiter
* Sections (boolean, enumerable, and inverted)
* Partials


