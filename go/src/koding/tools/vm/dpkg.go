package vm

import (
	"bufio"
	"io"
	"os"
)

type Package struct {
	Fields []string
	Values map[string]string
}

func ReadDpkgStatusDB(fileName string) []*Package {
	f, err := os.Open(fileName)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	r := bufio.NewReader(f)

	packages := make([]*Package, 0)
	for !atEndOfFile(r) {
		pkg := &Package{make([]string, 0), make(map[string]string)}
		packages = append(packages, pkg)
		for !tryReadByte(r, '\n') {
			field := readUntil(r, ':')
			value := ""
			if tryReadByte(r, '\n') {
				value += "\n"
			}
			for tryReadByte(r, ' ') {
				line := readUntil(r, '\n')
				value += " " + line + "\n"
			}
			pkg.Fields = append(pkg.Fields, field)
			pkg.Values[field] = value
		}
	}
	return packages
}

func WriteDpkgStatusDB(packages []*Package, fileName string) {
	f, err := os.Create(fileName)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	for _, pkg := range packages {
		for _, field := range pkg.Fields {
			f.Write([]byte(field + ":" + pkg.Values[field]))
		}
		f.Write([]byte{'\n'})
	}
}

func atEndOfFile(r *bufio.Reader) bool {
	_, err := r.ReadByte()
	if err != nil {
		if err == io.EOF {
			return true
		}
		panic(err)
	}
	r.UnreadByte()
	return false
}

func tryReadByte(r *bufio.Reader, b byte) bool {
	c, err := r.ReadByte()
	if err != nil {
		panic(err)
	}
	if c == b {
		return true
	}
	r.UnreadByte()
	return false
}

func readUntil(r *bufio.Reader, delim byte) string {
	line, err := r.ReadString(delim)
	if err != nil {
		panic(err)
	}
	return line[:len(line)-1]
}
