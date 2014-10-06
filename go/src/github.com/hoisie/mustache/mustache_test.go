package mustache

import (
    "os"
    "path"
    "strings"
    "testing"
)

type Test struct {
    tmpl     string
    context  interface{}
    expected string
}

type Data struct {
    A   bool
    B   string
}

type User struct {
    Name string
    Id   int64
}

type settings struct {
    Allow bool
}

func (u User) Func1() string {
    return u.Name
}

func (u *User) Func2() string {
    return u.Name
}

func (u *User) Func3() (map[string]string, error) {
    return map[string]string{"name": u.Name}, nil
}

func (u *User) Func4() (map[string]string, error) {
    return nil, nil
}

func (u *User) Func5() (*settings, error) {
    return &settings{true}, nil
}

func (u *User) Func6() ([]interface{}, error) {
    var v []interface{}
    v = append(v, &settings{true})
    return v, nil
}

func (u User) Truefunc1() bool {
    return true
}

func (u *User) Truefunc2() bool {
    return true
}

func makeVector(n int) []interface{} {
    var v []interface{}
    for i := 0; i < n; i++ {
        v = append(v, &User{"Mike", 1})
    }
    return v
}

type Category struct {
    Tag         string
    Description string
}

func (c Category) DisplayName() string {
    return c.Tag + " - " + c.Description
}

var tests = []Test{
    {`hello world`, nil, "hello world"},
    {`hello {{name}}`, map[string]string{"name": "world"}, "hello world"},
    {`{{var}}`, map[string]string{"var": "5 > 2"}, "5 &gt; 2"},
    {`{{{var}}}`, map[string]string{"var": "5 > 2"}, "5 > 2"},
    {`{{a}}{{b}}{{c}}{{d}}`, map[string]string{"a": "a", "b": "b", "c": "c", "d": "d"}, "abcd"},
    {`0{{a}}1{{b}}23{{c}}456{{d}}89`, map[string]string{"a": "a", "b": "b", "c": "c", "d": "d"}, "0a1b23c456d89"},
    {`hello {{! comment }}world`, map[string]string{}, "hello world"},
    {`{{ a }}{{=<% %>=}}<%b %><%={{ }}=%>{{ c }}`, map[string]string{"a": "a", "b": "b", "c": "c"}, "abc"},
    {`{{ a }}{{= <% %> =}}<%b %><%= {{ }}=%>{{c}}`, map[string]string{"a": "a", "b": "b", "c": "c"}, "abc"},

    //does not exist
    {`{{dne}}`, map[string]string{"name": "world"}, ""},
    {`{{dne}}`, User{"Mike", 1}, ""},
    {`{{dne}}`, &User{"Mike", 1}, ""},
    {`{{#has}}{{/has}}`, &User{"Mike", 1}, ""},

    //section tests
    {`{{#A}}{{B}}{{/A}}`, Data{true, "hello"}, "hello"},
    {`{{#A}}{{{B}}}{{/A}}`, Data{true, "5 > 2"}, "5 > 2"},
    {`{{#A}}{{B}}{{/A}}`, Data{true, "5 > 2"}, "5 &gt; 2"},
    {`{{#A}}{{B}}{{/A}}`, Data{false, "hello"}, ""},
    {`{{a}}{{#b}}{{b}}{{/b}}{{c}}`, map[string]string{"a": "a", "b": "b", "c": "c"}, "abc"},
    {`{{#A}}{{B}}{{/A}}`, struct {
        A []struct {
            B string
        }
    }{[]struct {
        B string
    }{{"a"}, {"b"}, {"c"}}},
        "abc",
    },
    {`{{#A}}{{b}}{{/A}}`, struct{ A []map[string]string }{[]map[string]string{{"b": "a"}, {"b": "b"}, {"b": "c"}}}, "abc"},

    {`{{#users}}{{Name}}{{/users}}`, map[string]interface{}{"users": []User{{"Mike", 1}}}, "Mike"},

    {`{{#users}}gone{{Name}}{{/users}}`, map[string]interface{}{"users": nil}, ""},
    {`{{#users}}gone{{Name}}{{/users}}`, map[string]interface{}{"users": (*User)(nil)}, ""},
    {`{{#users}}gone{{Name}}{{/users}}`, map[string]interface{}{"users": []User{}}, ""},

    {`{{#users}}{{Name}}{{/users}}`, map[string]interface{}{"users": []*User{{"Mike", 1}}}, "Mike"},
    {`{{#users}}{{Name}}{{/users}}`, map[string]interface{}{"users": []interface{}{&User{"Mike", 12}}}, "Mike"},
    {`{{#users}}{{Name}}{{/users}}`, map[string]interface{}{"users": makeVector(1)}, "Mike"},
    {`{{Name}}`, User{"Mike", 1}, "Mike"},
    {`{{Name}}`, &User{"Mike", 1}, "Mike"},
    {"{{#users}}\n{{Name}}\n{{/users}}", map[string]interface{}{"users": makeVector(2)}, "Mike\nMike\n"},
    {"{{#users}}\r\n{{Name}}\r\n{{/users}}", map[string]interface{}{"users": makeVector(2)}, "Mike\r\nMike\r\n"},

    // implicit iterator tests
    {`"{{#list}}({{.}}){{/list}}"`, map[string]interface{}{"list": []string{"a", "b", "c", "d", "e"}}, "\"(a)(b)(c)(d)(e)\""},
    {`"{{#list}}({{.}}){{/list}}"`, map[string]interface{}{"list": []int{1, 2, 3, 4, 5}}, "\"(1)(2)(3)(4)(5)\""},
    {`"{{#list}}({{.}}){{/list}}"`, map[string]interface{}{"list": []float64{1.10, 2.20, 3.30, 4.40, 5.50}}, "\"(1.1)(2.2)(3.3)(4.4)(5.5)\""},

    //inverted section tests
    {`{{a}}{{^b}}b{{/b}}{{c}}`, map[string]string{"a": "a", "c": "c"}, "abc"},
    {`{{a}}{{^b}}b{{/b}}{{c}}`, map[string]interface{}{"a": "a", "b": false, "c": "c"}, "abc"},
    {`{{^a}}b{{/a}}`, map[string]interface{}{"a": false}, "b"},
    {`{{^a}}b{{/a}}`, map[string]interface{}{"a": true}, ""},
    {`{{^a}}b{{/a}}`, map[string]interface{}{"a": "nonempty string"}, ""},
    {`{{^a}}b{{/a}}`, map[string]interface{}{"a": []string{}}, "b"},

    //function tests
    {`{{#users}}{{Func1}}{{/users}}`, map[string]interface{}{"users": []User{{"Mike", 1}}}, "Mike"},
    {`{{#users}}{{Func1}}{{/users}}`, map[string]interface{}{"users": []*User{{"Mike", 1}}}, "Mike"},
    {`{{#users}}{{Func2}}{{/users}}`, map[string]interface{}{"users": []*User{{"Mike", 1}}}, "Mike"},

    {`{{#users}}{{#Func3}}{{name}}{{/Func3}}{{/users}}`, map[string]interface{}{"users": []*User{{"Mike", 1}}}, "Mike"},
    {`{{#users}}{{#Func4}}{{name}}{{/Func4}}{{/users}}`, map[string]interface{}{"users": []*User{{"Mike", 1}}}, ""},
    {`{{#Truefunc1}}abcd{{/Truefunc1}}`, User{"Mike", 1}, "abcd"},
    {`{{#Truefunc1}}abcd{{/Truefunc1}}`, &User{"Mike", 1}, "abcd"},
    {`{{#Truefunc2}}abcd{{/Truefunc2}}`, &User{"Mike", 1}, "abcd"},
    {`{{#Func5}}{{#Allow}}abcd{{/Allow}}{{/Func5}}`, &User{"Mike", 1}, "abcd"},
    {`{{#user}}{{#Func5}}{{#Allow}}abcd{{/Allow}}{{/Func5}}{{/user}}`, map[string]interface{}{"user": &User{"Mike", 1}}, "abcd"},
    {`{{#user}}{{#Func6}}{{#Allow}}abcd{{/Allow}}{{/Func6}}{{/user}}`, map[string]interface{}{"user": &User{"Mike", 1}}, "abcd"},

    //context chaining
    {`hello {{#section}}{{name}}{{/section}}`, map[string]interface{}{"section": map[string]string{"name": "world"}}, "hello world"},
    {`hello {{#section}}{{name}}{{/section}}`, map[string]interface{}{"name": "bob", "section": map[string]string{"name": "world"}}, "hello world"},
    {`hello {{#bool}}{{#section}}{{name}}{{/section}}{{/bool}}`, map[string]interface{}{"bool": true, "section": map[string]string{"name": "world"}}, "hello world"},
    {`{{#users}}{{canvas}}{{/users}}`, map[string]interface{}{"canvas": "hello", "users": []User{{"Mike", 1}}}, "hello"},
    {`{{#categories}}{{DisplayName}}{{/categories}}`, map[string][]*Category{
        "categories": {&Category{"a", "b"}},
    }, "a - b"},

    //invalid syntax - https://github.com/hoisie/mustache/issues/10
    {`{{#a}}{{#b}}{{/a}}{{/b}}}`, map[string]interface{}{}, "line 1: interleaved closing tag: a"},
}

func TestBasic(t *testing.T) {
    for _, test := range tests {
        output := Render(test.tmpl, test.context)
        if output != test.expected {
            t.Fatalf("%q expected %q got %q", test.tmpl, test.expected, output)
        }
    }
}

func TestFile(t *testing.T) {
    filename := path.Join(path.Join(os.Getenv("PWD"), "tests"), "test1.mustache")
    expected := "hello world"
    output := RenderFile(filename, map[string]string{"name": "world"})
    if output != expected {
        t.Fatalf("testfile expected %q got %q", expected, output)
    }
}

func TestPartial(t *testing.T) {
    filename := path.Join(path.Join(os.Getenv("PWD"), "tests"), "test2.mustache")
    println(filename)
    expected := "hello world"
    output := RenderFile(filename, map[string]string{"Name": "world"})
    if output != expected {
        t.Fatalf("testpartial expected %q got %q", expected, output)
    }
}

/*
func TestSectionPartial(t *testing.T) {
    filename := path.Join(path.Join(os.Getenv("PWD"), "tests"), "test3.mustache")
    expected := "Mike\nJoe\n"
    context := map[string]interface{}{"users": []User{{"Mike", 1}, {"Joe", 2}}}
    output := RenderFile(filename, context)
    if output != expected {
        t.Fatalf("testSectionPartial expected %q got %q", expected, output)
    }
}
*/
func TestMultiContext(t *testing.T) {
    output := Render(`{{hello}} {{World}}`, map[string]string{"hello": "hello"}, struct{ World string }{"world"})
    output2 := Render(`{{hello}} {{World}}`, struct{ World string }{"world"}, map[string]string{"hello": "hello"})
    if output != "hello world" || output2 != "hello world" {
        t.Fatalf("TestMultiContext expected %q got %q", "hello world", output)
    }
}

var malformed = []Test{
    {`{{#a}}{{}}{{/a}}`, Data{true, "hello"}, "empty tag"},
    {`{{}}`, nil, "empty tag"},
    {`{{}`, nil, "unmatched open tag"},
    {`{{`, nil, "unmatched open tag"},
}

func TestMalformed(t *testing.T) {
    for _, test := range malformed {
        output := Render(test.tmpl, test.context)
        if strings.Index(output, test.expected) == -1 {
            t.Fatalf("%q expected %q in error %q", test.tmpl, test.expected, output)
        }
    }
}

type LayoutTest struct {
    layout   string
    tmpl     string
    context  interface{}
    expected string
}

var layoutTests = []LayoutTest{
    {`Header {{content}} Footer`, `Hello World`, nil, `Header Hello World Footer`},
    {`Header {{content}} Footer`, `Hello {{s}}`, map[string]string{"s": "World"}, `Header Hello World Footer`},
    {`Header {{content}} Footer`, `Hello {{content}}`, map[string]string{"content": "World"}, `Header Hello World Footer`},
    {`Header {{extra}} {{content}} Footer`, `Hello {{content}}`, map[string]string{"content": "World", "extra": "extra"}, `Header extra Hello World Footer`},
    {`Header {{content}} {{content}} Footer`, `Hello {{content}}`, map[string]string{"content": "World"}, `Header Hello World Hello World Footer`},
}

func TestLayout(t *testing.T) {
    for _, test := range layoutTests {
        output := RenderInLayout(test.tmpl, test.layout, test.context)
        if output != test.expected {
            t.Fatalf("%q expected %q got %q", test.tmpl, test.expected, output)
        }
    }
}
