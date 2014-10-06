package mustache

import (
    "bytes"
    "errors"
    "fmt"
    "io"
    "io/ioutil"
    "os"
    "path"
    "reflect"
    "strings"
)

type textElement struct {
    text []byte
}

type varElement struct {
    name string
    raw  bool
}

type sectionElement struct {
    name      string
    inverted  bool
    startline int
    elems     []interface{}
}

type Template struct {
    data    string
    otag    string
    ctag    string
    p       int
    curline int
    dir     string
    elems   []interface{}
}

type parseError struct {
    line    int
    message string
}

func (p parseError) Error() string { return fmt.Sprintf("line %d: %s", p.line, p.message) }

var (
    esc_quot = []byte("&quot;")
    esc_apos = []byte("&apos;")
    esc_amp  = []byte("&amp;")
    esc_lt   = []byte("&lt;")
    esc_gt   = []byte("&gt;")
)

// taken from pkg/template
func htmlEscape(w io.Writer, s []byte) {
    var esc []byte
    last := 0
    for i, c := range s {
        switch c {
        case '"':
            esc = esc_quot
        case '\'':
            esc = esc_apos
        case '&':
            esc = esc_amp
        case '<':
            esc = esc_lt
        case '>':
            esc = esc_gt
        default:
            continue
        }
        w.Write(s[last:i])
        w.Write(esc)
        last = i + 1
    }
    w.Write(s[last:])
}

func (tmpl *Template) readString(s string) (string, error) {
    i := tmpl.p
    newlines := 0
    for true {
        //are we at the end of the string?
        if i+len(s) > len(tmpl.data) {
            return tmpl.data[tmpl.p:], io.EOF
        }

        if tmpl.data[i] == '\n' {
            newlines++
        }

        if tmpl.data[i] != s[0] {
            i++
            continue
        }

        match := true
        for j := 1; j < len(s); j++ {
            if s[j] != tmpl.data[i+j] {
                match = false
                break
            }
        }

        if match {
            e := i + len(s)
            text := tmpl.data[tmpl.p:e]
            tmpl.p = e

            tmpl.curline += newlines
            return text, nil
        } else {
            i++
        }
    }

    //should never be here
    return "", nil
}

func (tmpl *Template) parsePartial(name string) (*Template, error) {
    filenames := []string{
        path.Join(tmpl.dir, name),
        path.Join(tmpl.dir, name+".mustache"),
        path.Join(tmpl.dir, name+".stache"),
        name,
        name + ".mustache",
        name + ".stache",
    }
    var filename string
    for _, name := range filenames {
        f, err := os.Open(name)
        if err == nil {
            filename = name
            f.Close()
            break
        }
    }
    if filename == "" {
        return nil, errors.New(fmt.Sprintf("Could not find partial %q", name))
    }

    partial, err := ParseFile(filename)

    if err != nil {
        return nil, err
    }

    return partial, nil
}

func (tmpl *Template) parseSection(section *sectionElement) error {
    for {
        text, err := tmpl.readString(tmpl.otag)

        if err == io.EOF {
            return parseError{section.startline, "Section " + section.name + " has no closing tag"}
        }

        // put text into an item
        text = text[0 : len(text)-len(tmpl.otag)]
        section.elems = append(section.elems, &textElement{[]byte(text)})
        if tmpl.p < len(tmpl.data) && tmpl.data[tmpl.p] == '{' {
            text, err = tmpl.readString("}" + tmpl.ctag)
        } else {
            text, err = tmpl.readString(tmpl.ctag)
        }

        if err == io.EOF {
            //put the remaining text in a block
            return parseError{tmpl.curline, "unmatched open tag"}
        }

        //trim the close tag off the text
        tag := strings.TrimSpace(text[0 : len(text)-len(tmpl.ctag)])

        if len(tag) == 0 {
            return parseError{tmpl.curline, "empty tag"}
        }
        switch tag[0] {
        case '!':
            //ignore comment
            break
        case '#', '^':
            name := strings.TrimSpace(tag[1:])

            //ignore the newline when a section starts
            if len(tmpl.data) > tmpl.p && tmpl.data[tmpl.p] == '\n' {
                tmpl.p += 1
            } else if len(tmpl.data) > tmpl.p+1 && tmpl.data[tmpl.p] == '\r' && tmpl.data[tmpl.p+1] == '\n' {
                tmpl.p += 2
            }

            se := sectionElement{name, tag[0] == '^', tmpl.curline, []interface{}{}}
            err := tmpl.parseSection(&se)
            if err != nil {
                return err
            }
            section.elems = append(section.elems, &se)
        case '/':
            name := strings.TrimSpace(tag[1:])
            if name != section.name {
                return parseError{tmpl.curline, "interleaved closing tag: " + name}
            } else {
                return nil
            }
        case '>':
            name := strings.TrimSpace(tag[1:])
            partial, err := tmpl.parsePartial(name)
            if err != nil {
                return err
            }
            section.elems = append(section.elems, partial)
        case '=':
            if tag[len(tag)-1] != '=' {
                return parseError{tmpl.curline, "Invalid meta tag"}
            }
            tag = strings.TrimSpace(tag[1 : len(tag)-1])
            newtags := strings.SplitN(tag, " ", 2)
            if len(newtags) == 2 {
                tmpl.otag = newtags[0]
                tmpl.ctag = newtags[1]
            }
        case '{':
            if tag[len(tag)-1] == '}' {
                //use a raw tag
                section.elems = append(section.elems, &varElement{tag[1 : len(tag)-1], true})
            }
        default:
            section.elems = append(section.elems, &varElement{tag, false})
        }
    }

    return nil
}

func (tmpl *Template) parse() error {
    for {
        text, err := tmpl.readString(tmpl.otag)
        if err == io.EOF {
            //put the remaining text in a block
            tmpl.elems = append(tmpl.elems, &textElement{[]byte(text)})
            return nil
        }

        // put text into an item
        text = text[0 : len(text)-len(tmpl.otag)]
        tmpl.elems = append(tmpl.elems, &textElement{[]byte(text)})

        if tmpl.p < len(tmpl.data) && tmpl.data[tmpl.p] == '{' {
            text, err = tmpl.readString("}" + tmpl.ctag)
        } else {
            text, err = tmpl.readString(tmpl.ctag)
        }

        if err == io.EOF {
            //put the remaining text in a block
            return parseError{tmpl.curline, "unmatched open tag"}
        }

        //trim the close tag off the text
        tag := strings.TrimSpace(text[0 : len(text)-len(tmpl.ctag)])
        if len(tag) == 0 {
            return parseError{tmpl.curline, "empty tag"}
        }
        switch tag[0] {
        case '!':
            //ignore comment
            break
        case '#', '^':
            name := strings.TrimSpace(tag[1:])

            if len(tmpl.data) > tmpl.p && tmpl.data[tmpl.p] == '\n' {
                tmpl.p += 1
            } else if len(tmpl.data) > tmpl.p+1 && tmpl.data[tmpl.p] == '\r' && tmpl.data[tmpl.p+1] == '\n' {
                tmpl.p += 2
            }

            se := sectionElement{name, tag[0] == '^', tmpl.curline, []interface{}{}}
            err := tmpl.parseSection(&se)
            if err != nil {
                return err
            }
            tmpl.elems = append(tmpl.elems, &se)
        case '/':
            return parseError{tmpl.curline, "unmatched close tag"}
        case '>':
            name := strings.TrimSpace(tag[1:])
            partial, err := tmpl.parsePartial(name)
            if err != nil {
                return err
            }
            tmpl.elems = append(tmpl.elems, partial)
        case '=':
            if tag[len(tag)-1] != '=' {
                return parseError{tmpl.curline, "Invalid meta tag"}
            }
            tag = strings.TrimSpace(tag[1 : len(tag)-1])
            newtags := strings.SplitN(tag, " ", 2)
            if len(newtags) == 2 {
                tmpl.otag = newtags[0]
                tmpl.ctag = newtags[1]
            }
        case '{':
            //use a raw tag
            if tag[len(tag)-1] == '}' {
                tmpl.elems = append(tmpl.elems, &varElement{tag[1 : len(tag)-1], true})
            }
        default:
            tmpl.elems = append(tmpl.elems, &varElement{tag, false})
        }
    }

    return nil
}

// See if name is a method of the value at some level of indirection.
// The return values are the result of the call (which may be nil if
// there's trouble) and whether a method of the right name exists with
// any signature.
func callMethod(data reflect.Value, name string) (result reflect.Value, found bool) {
    found = false
    // Method set depends on pointerness, and the value may be arbitrarily
    // indirect.  Simplest approach is to walk down the pointer chain and
    // see if we can find the method at each step.
    // Most steps will see NumMethod() == 0.
    for {
        typ := data.Type()
        if nMethod := data.Type().NumMethod(); nMethod > 0 {
            for i := 0; i < nMethod; i++ {
                method := typ.Method(i)
                if method.Name == name {

                    found = true // we found the name regardless
                    // does receiver type match? (pointerness might be off)
                    if typ == method.Type.In(0) {
                        return call(data, method), found
                    }
                }
            }
        }
        if nd := data; nd.Kind() == reflect.Ptr {
            data = nd.Elem()
        } else {
            break
        }
    }
    return
}

// Invoke the method. If its signature is wrong, return nil.
func call(v reflect.Value, method reflect.Method) reflect.Value {
    funcType := method.Type
    // Method must take no arguments, meaning as a func it has one argument (the receiver)
    if funcType.NumIn() != 1 {
        return reflect.Value{}
    }
    // Method must return a single value.
    if funcType.NumOut() == 0 {
        return reflect.Value{}
    }
    // Result will be the zeroth element of the returned slice.
    return method.Func.Call([]reflect.Value{v})[0]
}

// Evaluate interfaces and pointers looking for a value that can look up the name, via a
// struct field, method, or map key, and return the result of the lookup.
func lookup(contextChain []interface{}, name string) reflect.Value {
    defer func() {
        if r := recover(); r != nil {
            fmt.Printf("Panic while looking up %q: %s\n", name, r)
        }
    }()

Outer:
    for _, ctx := range contextChain { //i := len(contextChain) - 1; i >= 0; i-- {
        v := ctx.(reflect.Value)
        for v.IsValid() {
            typ := v.Type()
            if n := v.Type().NumMethod(); n > 0 {
                for i := 0; i < n; i++ {
                    m := typ.Method(i)
                    mtyp := m.Type
                    if m.Name == name && mtyp.NumIn() == 1 {
                        return v.Method(i).Call(nil)[0]
                    }
                }
            }
            if name == "." {
              return v
            }
            switch av := v; av.Kind() {
            case reflect.Ptr:
                v = av.Elem()
            case reflect.Interface:
                v = av.Elem()
            case reflect.Struct:
                ret := av.FieldByName(name)
                if ret.IsValid() {
                    return ret
                } else {
                    continue Outer
                }
            case reflect.Map:
                ret := av.MapIndex(reflect.ValueOf(name))
                if ret.IsValid() {
                    return ret
                } else {
                    continue Outer
                }
            default:
                continue Outer
            }
        }
    }
    return reflect.Value{}
}

func isEmpty(v reflect.Value) bool {
    if !v.IsValid() || v.Interface() == nil {
        return true
    }

    valueInd := indirect(v)
    if !valueInd.IsValid() {
        return true
    }
    switch val := valueInd; val.Kind() {
    case reflect.Bool:
        return !val.Bool()
    case reflect.Slice:
        return val.Len() == 0
    }

    return false
}

func indirect(v reflect.Value) reflect.Value {
loop:
    for v.IsValid() {
        switch av := v; av.Kind() {
        case reflect.Ptr:
            v = av.Elem()
        case reflect.Interface:
            v = av.Elem()
        default:
            break loop
        }
    }
    return v
}

func renderSection(section *sectionElement, contextChain []interface{}, buf io.Writer) {
    value := lookup(contextChain, section.name)
    var context = contextChain[len(contextChain)-1].(reflect.Value)
    var contexts = []interface{}{}
    // if the value is nil, check if it's an inverted section
    isEmpty := isEmpty(value)
    if isEmpty && !section.inverted || !isEmpty && section.inverted {
        return
    } else if !section.inverted {
        valueInd := indirect(value)
        switch val := valueInd; val.Kind() {
        case reflect.Slice:
            for i := 0; i < val.Len(); i++ {
                contexts = append(contexts, val.Index(i))
            }
        case reflect.Array:
            for i := 0; i < val.Len(); i++ {
                contexts = append(contexts, val.Index(i))
            }
        case reflect.Map, reflect.Struct:
            contexts = append(contexts, value)
        default:
            contexts = append(contexts, context)
        }
    } else if section.inverted {
        contexts = append(contexts, context)
    }

    chain2 := make([]interface{}, len(contextChain)+1)
    copy(chain2[1:], contextChain)
    //by default we execute the section
    for _, ctx := range contexts {
        chain2[0] = ctx
        for _, elem := range section.elems {
            renderElement(elem, chain2, buf)
        }
    }
}

func renderElement(element interface{}, contextChain []interface{}, buf io.Writer) {
    switch elem := element.(type) {
    case *textElement:
        buf.Write(elem.text)
    case *varElement:
        defer func() {
            if r := recover(); r != nil {
                fmt.Printf("Panic while looking up %q: %s\n", elem.name, r)
            }
        }()
        val := lookup(contextChain, elem.name)

        if val.IsValid() {
            if elem.raw {
                fmt.Fprint(buf, val.Interface())
            } else {
                s := fmt.Sprint(val.Interface())
                htmlEscape(buf, []byte(s))
            }
        }
    case *sectionElement:
        renderSection(elem, contextChain, buf)
    case *Template:
        elem.renderTemplate(contextChain, buf)
    }
}

func (tmpl *Template) renderTemplate(contextChain []interface{}, buf io.Writer) {
    for _, elem := range tmpl.elems {
        renderElement(elem, contextChain, buf)
    }
}

func (tmpl *Template) Render(context ...interface{}) string {
    var buf bytes.Buffer
    var contextChain []interface{}
    for _, c := range context {
        val := reflect.ValueOf(c)
        contextChain = append(contextChain, val)
    }
    tmpl.renderTemplate(contextChain, &buf)
    return buf.String()
}

func (tmpl *Template) RenderInLayout(layout *Template, context ...interface{}) string {
    content := tmpl.Render(context...)
    allContext := make([]interface{}, len(context)+1)
    copy(allContext[1:], context)
    allContext[0] = map[string]string{"content": content}
    return layout.Render(allContext...)
}

func ParseString(data string) (*Template, error) {
    cwd := os.Getenv("CWD")
    tmpl := Template{data, "{{", "}}", 0, 1, cwd, []interface{}{}}
    err := tmpl.parse()

    if err != nil {
        return nil, err
    }

    return &tmpl, err
}

func ParseFile(filename string) (*Template, error) {
    data, err := ioutil.ReadFile(filename)
    if err != nil {
        return nil, err
    }

    dirname, _ := path.Split(filename)

    tmpl := Template{string(data), "{{", "}}", 0, 1, dirname, []interface{}{}}
    err = tmpl.parse()

    if err != nil {
        return nil, err
    }

    return &tmpl, nil
}

func Render(data string, context ...interface{}) string {
    tmpl, err := ParseString(data)
    if err != nil {
        return err.Error()
    }
    return tmpl.Render(context...)
}

func RenderInLayout(data string, layoutData string, context ...interface{}) string {
    layoutTmpl, err := ParseString(layoutData)
    if err != nil {
        return err.Error()
    }
    tmpl, err := ParseString(data)
    if err != nil {
        return err.Error()
    }
    return tmpl.RenderInLayout(layoutTmpl, context...)
}

func RenderFile(filename string, context ...interface{}) string {
    tmpl, err := ParseFile(filename)
    if err != nil {
        return err.Error()
    }
    return tmpl.Render(context...)
}

func RenderFileInLayout(filename string, layoutFile string, context ...interface{}) string {
    layoutTmpl, err := ParseFile(layoutFile)
    if err != nil {
        return err.Error()
    }

    tmpl, err := ParseFile(filename)
    if err != nil {
        return err.Error()
    }
    return tmpl.RenderInLayout(layoutTmpl, context...)
}
