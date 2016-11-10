package object

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"reflect"
	"strings"
	"text/tabwriter"

	"github.com/fatih/structs"
)

type Printer struct {
	Tag    string
	JSON   bool
	Format string
	W      io.Writer
}

func (p *Printer) Print(v interface{}) error {
	if p.JSON {
		return p.printJSON(v)
	}
	return p.printTab(v)
}

func (p *Printer) printJSON(v interface{}) error {
	enc := json.NewEncoder(p.W)
	enc.SetIndent("", "\t")

	return enc.Encode(v)
}

var (
	fprintf  = reflect.ValueOf(fmt.Fprintf)
	stringer = reflect.TypeOf((*fmt.Stringer)(nil)).Elem()
)

func (p *Printer) printTab(v interface{}) error {
	tw := tabwriter.NewWriter(p.W, 2, 0, 2, ' ', 0)

	vv := indirect(reflect.ValueOf(v))

	if vv.Kind() != reflect.Slice && vv.Kind() != reflect.Array {
		v = []interface{}{v}
		vv = reflect.ValueOf(v)
	}

	label := indirect(vv.Index(0))
	if label.Kind() != reflect.Struct {
		return errors.New("object: expected struct value")
	}

	fields := structs.Fields(label.Interface())
	var buf bytes.Buffer

	// Print headline.
	for i, field := range fields {
		label := field.Name()
		if s := field.Tag(p.Tag); s != "" {
			label = s
		}

		label = strings.ToUpper(label)

		c := '\t'
		if i == len(fields)-1 {
			c = '\n'
		}

		fmt.Fprintf(tw, "%s%c", label, c)
		fmt.Fprintf(&buf, "%"+p.format()+"%c", c)
	}

	format := buf.String()

	for i := 0; i < vv.Len(); i++ {
		args := []reflect.Value{
			reflect.ValueOf(tw),
			reflect.ValueOf(format),
		}

		elem := indirect(vv.Index(i))

		for j := 0; j < elem.NumField(); j++ {
			field := elem.Field(j)

			if s, ok := field.Interface().(fmt.Stringer); ok {
				field = reflect.ValueOf(s)
			} else if field.CanAddr() {
				if s, ok := field.Addr().Interface().(fmt.Stringer); ok {
					field = reflect.ValueOf(s)
				}
			}

			args = append(args, field)
		}

		fprintf.Call(args)
	}

	return tw.Flush()
}

func (p *Printer) format() string {
	if p.Format != "" {
		return p.Format
	}
	return "%v"
}
