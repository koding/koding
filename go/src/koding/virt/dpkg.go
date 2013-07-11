package virt

import (
	"bufio"
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
)

type Package struct {
	Fields []string
	Values map[string]string
}

var DPKG_INFO_EXTENSIONS = []string{"conffiles", "list", "md5sums", "postinst", "postrm", "preinst", "prerm", "shlibs", "symbols", "templates"}

func (pkg *Package) ID() string {
	name := strings.TrimSpace(pkg.Values["Package"])
	multiArch := strings.TrimSpace(pkg.Values["Multi-Arch"])
	if multiArch == "same" {
		arch := strings.TrimSpace(pkg.Values["Architecture"])
		return name + ":" + arch
	}
	return name
}

func (pkg *Package) InfoFile(extension string) string {
	return fmt.Sprintf("/var/lib/dpkg/info/%s.%s", pkg.ID(), extension)
}

func (vm *VM) MergeDpkgDatabase() {
	dpkgStatusFile := vm.OverlayFile("/var/lib/dpkg/status")
	upperPackages, err := ReadDpkgStatus(dpkgStatusFile)
	if err != nil {
		if !os.IsNotExist(err) {
			panic(err)
		}
		return // no file in upper, no need to merge
	}

	lowerPackages, err := ReadDpkgStatus(vm.LowerdirFile("/var/lib/dpkg/status"))
	if err != nil {
		panic(err)
	}

	// merge packages from lower to upper
	for name, lowerPkg := range lowerPackages {
		upperPkg, found := upperPackages[name]
		if found && upperPkg.Values["Version"] != lowerPkg.Values["Version"] {
			conffiles := make(map[string]string)

			lines := strings.Split(upperPkg.Values["Conffiles"], "\n")
			for _, line := range lines {
				parts := strings.Split(strings.TrimSpace(line), " ")
				if len(parts) == 2 {
					conffiles[parts[0]] = parts[1]
				}
			}

			// delete package files from overlay
			listFile := upperPkg.InfoFile("list")
			list, err := ioutil.ReadFile(vm.OverlayFile(listFile))
			if err != nil {
				list, err = ioutil.ReadFile(vm.LowerdirFile(listFile))
				if err != nil {
					panic(err)
				}
			}
			files := strings.Split(string(list), "\n")
			for _, file := range files {
				overlayFile := vm.OverlayFile(file)
				originalHash, found := conffiles[file]
				if found {
					hash := md5.New()
					f, err := os.Open(overlayFile)
					if err != nil {
						if os.IsNotExist(err) {
							continue // file not found in overlay
						}
						panic(err)
					}
					io.Copy(hash, f)
					f.Close()
					if string(hash.Sum(nil)) != originalHash {
						continue // config file was changed, do not delete from overlay
					}
				}
				os.Remove(overlayFile)
			}

			// delete informations from overlay
			for _, ext := range DPKG_INFO_EXTENSIONS {
				os.Remove(vm.OverlayFile(upperPkg.InfoFile(ext)))
			}
		}
		upperPackages[name] = lowerPkg
	}

	// delete packages that were removed in lower
	for name, upperPkg := range upperPackages {
		if _, found := lowerPackages[name]; found {
			continue // still in lower
		}
		_, err := os.Stat(vm.OverlayFile(upperPkg.InfoFile("list")))
		if err == nil {
			continue // files in overlay
		}
		delete(upperPackages, name)
	}

	if err = WriteDpkgStatus(upperPackages, dpkgStatusFile); err != nil {
		panic(err)
	}
}

func ReadDpkgStatus(fileName string) (map[string]*Package, error) {
	f, err := os.Open(fileName)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	r := bufio.NewReader(f)

	packages := make(map[string]*Package)
	for !atEndOfFile(r) {
		pkg := &Package{make([]string, 0), make(map[string]string)}
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
		packages[pkg.ID()] = pkg
	}
	return packages, nil
}

func WriteDpkgStatus(packages map[string]*Package, fileName string) error {
	f, err := os.Create(fileName)
	if err != nil {
		return err
	}
	defer f.Close()

	for _, pkg := range packages {
		for _, field := range pkg.Fields {
			f.Write([]byte(field + ":" + pkg.Values[field]))
		}
		f.Write([]byte{'\n'})
	}

	return nil
}
