/*
pkgsonames is a utility that lists sonames in Archlinux packages (tarballs).
*/
package main

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"debug/elf"
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	xz "github.com/remyoudompheng/go-liblzma"
)

type ReadCloser struct {
	io.Reader
	closers []io.Closer
}

func (x *ReadCloser) Close() error {
	for _, c := range x.closers {
		c.Close()
	}
	return nil
}

func OpenPackage(name string) (x ReadCloser, err error) {
	f, err := os.Open(name)
	if err != nil {
		return x, err
	}
	var rd io.ReadCloser
	switch filepath.Ext(name) {
	case ".xz":
		rd, err = xz.NewReader(f)
	case ".gz":
		rd, err = gzip.NewReader(f)
	default:
		return x, fmt.Errorf("not a package name: %s", name)
	}
	if err != nil {
		f.Close()
		return x, err
	}
	return ReadCloser{rd, []io.Closer{rd, f}}, nil
}

func WalkELF(tarfile io.ReadCloser, do func(filename string, data []byte)) error {
	t := tar.NewReader(tarfile)
	defer tarfile.Close()
	buf := new(bytes.Buffer)
	for {
		entry, err := t.Next()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		switch entry.Typeflag {
		case tar.TypeReg, tar.TypeRegA:
			// OK.
		default:
			continue
		}
		buf.Reset()
		n, err := io.CopyN(buf, t, 4)
		switch {
		case n < 4 || err != nil:
			continue
		case string(buf.Bytes()) != elf.ELFMAG:
			continue
		}
		io.Copy(buf, t)
		do(entry.Name, buf.Bytes())
	}
}

func getstring(table []byte, offset int) string {
	n := bytes.IndexByte(table[offset:], 0)
	return string(table[offset : offset+n])
}

func Soname(data []byte) (so string, ok bool) {
	e, err := elf.NewFile(bytes.NewReader(data))
	if err != nil {
		return so, false
	}
	section := e.Section(".dynamic")
	if section == nil {
		// not a dynamic binary.
		return so, false
	}
	// e.stringtable(section.Link)
	dynstr, _ := e.Sections[section.Link].Data()

	switch e.Class {
	case elf.ELFCLASS64:
		n := section.Size / 16 // 2*sizeof(uintptr)
		values := make([]elf.Dyn64, n)
		binary.Read(section.Open(), binary.LittleEndian, values)
		for _, v := range values {
			if elf.DynTag(v.Tag) == elf.DT_SONAME {
				return getstring(dynstr, int(v.Val)), true
			}
		}
	case elf.ELFCLASS32:
		n := section.Size / 8
		values := make([]elf.Dyn32, n)
		binary.Read(section.Open(), binary.LittleEndian, values)
		for _, v := range values {
			if elf.DynTag(v.Tag) == elf.DT_SONAME {
				return getstring(dynstr, int(v.Val)), true
			}
		}
	}
	return "", false
}

func Depends(data []byte) (needed []string, err error) {
	e, err := elf.NewFile(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	section := e.Section(".dynamic")
	if section == nil {
		// not a dynamic binary.
		return nil, nil
	}
	// e.stringtable(section.Link)
	dynstr, _ := e.Sections[section.Link].Data()

	switch e.Class {
	case elf.ELFCLASS64:
		n := section.Size / 16 // 2*sizeof(uintptr)
		values := make([]elf.Dyn64, n)
		binary.Read(section.Open(), binary.LittleEndian, values)
		for _, v := range values {
			if elf.DynTag(v.Tag) == elf.DT_NEEDED {
				so := getstring(dynstr, int(v.Val))
				needed = append(needed, so)
			}
		}
	case elf.ELFCLASS32:
		n := section.Size / 8
		values := make([]elf.Dyn32, n)
		binary.Read(section.Open(), binary.LittleEndian, values)
		for _, v := range values {
			if elf.DynTag(v.Tag) == elf.DT_NEEDED {
				so := getstring(dynstr, int(v.Val))
				needed = append(needed, so)
			}
		}
	}
	return needed, nil
}

type StringList []string

func (s *StringList) Set(arg string) error { *s = strings.Split(arg, ","); return nil }
func (s *StringList) String() string       { return strings.Join(*s, ",") }

func errorf(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
}

func main() {
	var repopath string
	var deps bool
	archs := StringList{"i686", "x86_64"}
	flag.StringVar(&repopath, "repo", "", "path to repository")
	flag.Var(&archs, "arch", "path to repository")
	flag.BoolVar(&deps, "deps", false, "print dependencies instead of sonames")
	flag.Parse()

	if repopath != "" {
		// Use repository at specified path.
		err := os.Chdir(repopath)
		if err != nil {
			errorf("%s", err)
		}
		var packages []string
		for _, arch := range archs {
			p, err := filepath.Glob("*/os/" + arch + "/*.pkg.tar.[gx]z")
			if err != nil {
				errorf("%s", err)
			}
			packages = append(packages, p...)
		}
		errorf("%d packages to process", len(packages))
		for _, pkgfile := range packages {
			elems := strings.Split(filepath.ToSlash(filepath.Clean(pkgfile)), "/")
			if len(elems) != 4 {
				errorf("invalid package path: %s", pkgfile)
				continue
			}
			repo, arch, name := elems[0], elems[2], elems[3]
			t, err := OpenPackage(pkgfile)
			if err != nil {
				errorf("%s", err)
				continue
			}
			printed := false
			WalkELF(&t, func(fname string, data []byte) {
				if soname, ok := Soname(data); ok {
					if !printed {
						printed = true
						errorf(pkgfile)
					}
					fmt.Println(strings.Join([]string{
						repo, arch, name, fname, soname}, ","))
				}
			})
		}
	} else {
		// Process packages from command line.
		for _, tarname := range flag.Args() {
			t, err := OpenPackage(tarname)
			if err != nil {
				errorf("%s", err)
				continue
			}
			WalkELF(&t, func(fname string, data []byte) {
				if !deps {
					soname, ok := Soname(data)
					if ok {
						fmt.Printf("%s,%s,%s\n", tarname, fname, soname)
					}
				} else {
					depends, err := Depends(data)
					if err != nil {
						errorf("corrupted ELF file %q: %s", fname, err)
					}
					for _, s := range depends {
						fmt.Printf("%s,%s,%s\n", tarname, fname, s)
					}
				}
			})
		}
	}
}
