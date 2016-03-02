// Copyright 2012 Rémy Oudompheng. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package vdeck

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"reflect"
	"strings"
)

// This file implements RFC2426 for VCard 3.0.

type VCard struct {
	// Section 3.1: identification
	FullName string    `vcard:"FN"`
	Name     NameField `vcard:"N"`
	Nickname string    `vcard:"NICKNAME"`
	Photo    string    `vcard:"PHOTO"`
	Birthday string    `vcard:"BDAY"`

	// Section 3.2: delivery addressing
	Address []AddrField `vcard:"ADR"`
	Label   string      `vcard:"LABEL"`

	// Section 3.3: telecommunications addressing
	Tel    []TypedString `vcard:"TEL"`
	Email  []TypedString `vcard:"EMAIL"`
	Mailer string        `vcard:"MAILER"`

	// Section 3.4: geographical
	TZ  string `vcard:"TZ"`
	Geo string `vcard:"GEO"`

	// Section 3.5: organizational
	Title string `vcard:"TITLE"`
	Role  string `vcard:"ROLE"`
	Logo  string `vcard:"LOGO"`
	Agent string `vcard:"AGENT"`
	Org   string `vcard:"ORG"`

	// Section 3.6: explanatory
	Categories CSV    `vcard:"CATEGORIES"`
	Note       string `vcard:"NOTE"`
	ProdID     string `vcard:"PRODID"`
	Rev        string `vcard:"REV"`
	SortString string `vcard:"SORT-STRING"`
	Sound      string `vcard:"SOUND"`
	Uid        string `vcard:"UID"`
	Url        string `vcard:"URL"`
	Version    string `vcard:"VERSION"`

	// Section 3.7: security
	Class string `vcard:"CLASS"`
	Key   string `vcard:"KEY"`

	Filename string // The path whence the vCard was loaded.
}

type NameField struct {
	FamilyName        string
	GivenName         string
	Additional        []string
	HonorificPrefixes []string
	HonorificSuffixes []string
}

type AddrField struct {
	Type         []string
	POBox        string
	ExtendedAddr string
	Street       string
	Locality     string
	Region       string
	PostalCode   string
	Country      string
}

type TypedString struct {
	Type  []string
	Value string
}

func (t TypedString) String() string { return t.Value }

type CSV []string

var vcard_t = reflect.TypeOf(VCard{})   // The reflect.Type of VCard
var vcard_fields = make(map[string]int) // vcard_fields["N"] = 1

func init() {
	for i, imax := 0, vcard_t.NumField(); i < imax; i++ {
		fld := vcard_t.Field(i)
		if tag := fld.Tag.Get("vcard"); tag != "" {
			vcard_fields[tag] = i
		}
	}
}

func (vc VCard) String() string {
	vc.Version = "3.0"
	buf := new(bytes.Buffer)
	buf.WriteString("BEGIN:VCARD\n")
	v := reflect.ValueOf(vc)
	for i, imax := 0, v.NumField(); i < imax; i++ {
		fname := vcard_t.Field(i).Tag.Get("vcard")
		if fname == "" {
			continue
		}
		field := v.Field(i)
		if field.Type().Kind() == reflect.Slice && field.Type().Name() == "" {
			for j, jmax := 0, field.Len(); j < jmax; j++ {
				buf.WriteString(toLine(fname, field.Index(j)))
			}
		} else {
			buf.WriteString(toLine(fname, field))
		}
	}
	buf.WriteString("END:VCARD\n")
	return buf.String()
}

func ParseVcard(r io.Reader) (vc *VCard, err error) {
	buf := bufio.NewReader(r)
	// parse BEGIN:VCARD
	fname, types, data, err := readLine(buf)
	switch {
	case err != nil:
		return nil, err
	case fname != "BEGIN" || types != nil || data != "VCARD":
		return nil, fmt.Errorf("expected %q", "BEGIN:VCARD")
	}
	// parse fields
	vc = new(VCard)
	v := reflect.ValueOf(vc).Elem()
	for {
		fname, types, data, err = readLine(buf)
		if fname == "END" {
			break
		}
		idx, ok := vcard_fields[fname]
		if !ok {
			return nil, fmt.Errorf("unknown field %q", fname)
		}
		fv := v.Field(idx)
		if fv.Kind() == reflect.Slice && fv.Type().Name() == "" {
			item := reflect.New(fv.Type().Elem()).Elem()
			err = fromLine(fname, item, types, data)
			fv.Set(reflect.Append(fv, item))
		} else {
			err = fromLine(fname, fv, types, data)
		}
		if err != nil {
			return nil, err
		}
	}
	if vc.Version != "3.0" {
		return nil, fmt.Errorf("unsupported version %q", vc.Version)
	}
	// parse END:VCARD
	if fname != "END" || types != nil || data != "VCARD" {
		return nil, fmt.Errorf("expected %q", "END:VCARD")
	}
	return vc, nil
}

func readLine(r *bufio.Reader) (fname string, types []string, data string, err error) {
	var line []byte
	for len(line) == 0 {
		var short bool
		line, short, err = r.ReadLine()
		if short {
			err = fmt.Errorf("line too long")
			return
		}
		if err != nil {
			return
		}
		line = bytes.TrimSpace(line)
	}

	b, err := r.ReadByte()
	if err == io.EOF || b != ' ' {
		r.UnreadByte()
		return parseLine(string(line))
	}
	for b == ' ' && err != io.EOF {
		r.UnreadByte()
		stub, short, err := r.ReadLine()
		if !short {
			err = fmt.Errorf("line too long")
			return fname, types, data, err
		}
		line = append(line, bytes.TrimSpace(stub)...)
		b, err = r.ReadByte()
	}
	r.UnreadByte()
	return parseLine(string(line))
}

func parseLine(s string) (fname string, types []string, data string, err error) {
	chunks := strings.SplitN(s, ":", 2)
	if len(chunks) != 2 {
		err = fmt.Errorf("no semicolon in %q", s)
		return
	}
	field := chunks[0]
	data = chunks[1]

	chunks = strings.Split(field, ";")
	fname = chunks[0]
	for _, c := range chunks {
		if strings.HasPrefix(c, "TYPE=") {
			c = c[len("TYPE="):]
			types = strings.Split(c, ",")
		}
	}
	return
}

func fromLine(fname string, value reflect.Value, types []string, data string) error {
	if !value.CanSet() {
		panic("non-settable value in fromLine()")
	}

	switch v := value.Interface().(type) {
	case string:
		value.SetString(data)
	case CSV:
		v = splitList(data, ',')
		value.Set(reflect.ValueOf(v))
	default:
		words := splitList(data, ';')
		for i := 0; i < value.NumField(); i++ {
			fv := value.Field(i)
			if value.Type().Field(i).Name == "Type" {
				fv.Set(reflect.ValueOf(types))
				continue
			}
			if len(words) == 0 {
				return fmt.Errorf("missing value for structured field %s", value.Type().Field(i).Name)
			}
			word := words[0]
			words = words[1:]
			switch fv.Interface().(type) {
			case string:
				fv.SetString(word)
			case []string:
				items := splitList(word, ',')
				fv.Set(reflect.ValueOf(items))
			default:
				err := fmt.Errorf("unsupported field type %s", fv.Type())
				panic(err)
			}
		}
	}
	return nil
}

func toLine(fname string, value reflect.Value) string {
	var data string
	switch v := value.Interface().(type) {
	case string:
		data = v
	case CSV:
		data = joinList(v, ',')
	default:
		components := make([]string, 0, value.NumField())
		for i := 0; i < value.NumField(); i++ {
			if value.Type().Field(i).Name == "Type" {
				types := value.Field(i).Interface().([]string)
				if len(types) > 0 {
					fname = fmt.Sprintf("%s;TYPE=%s", fname, strings.Join(types, ","))
				}
				continue
			}
			switch x := value.Field(i).Interface().(type) {
			case string:
				components = append(components, x)
			case []string:
				components = append(components, joinList(x, ','))
			default:
				err := fmt.Errorf("unsupported field type %s", value.Field(i).Type())
				panic(err)
			}
		}
		data = joinList(components, ';')
	}
	if len(data) == 0 {
		return ""
	}
	return fname + ":" + data + "\n"
}

func splitList(s string, sep rune) (parts []string) {
	if s == "" {
		return nil
	}
	for {
		var last int
		for last < len(s) {
			i := strings.IndexRune(s[last:], sep)
			if i > 0 && s[last+i-1] == '\\' {
				last += i + 1
				continue
			}
			last += i
			if i < 0 {
				last = len(s)
			}
			break
		}
		parts = append(parts, strings.Replace(s[:last], "\\"+string(sep), string(sep), -1))
		if last < len(s) {
			s = s[last+1:]
		} else {
			break
		}
	}
	return parts
}

func joinList(s []string, sep byte) string {
	buf := new(bytes.Buffer)
	for i, v := range s {
		if i > 0 {
			buf.WriteByte(sep)
		}
		buf.WriteString(strings.Replace(v, string(sep), "\\"+string(sep), -1))
	}
	return buf.String()
}
