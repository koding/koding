package vm

import (
	"bufio"
	"os"
)

type Package struct {
	Fields []string
	Values map[string]string
}

func ReadDpkgStatus(fileName string) []*Package {
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

func WriteDpkgStatus(packages []*Package, fileName string) {
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
