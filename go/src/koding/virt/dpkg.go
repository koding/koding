package virt

import (
	"bufio"
	"crypto/md5"
	"io"
	"io/ioutil"
	"os"
	"strings"
)

type Package struct {
	Fields []string
	Values map[string]string
}

func (vm *VM) MergeDpkgDatabase() {
	dpkgStatusFile := vm.File("overlayfs-upperdir/var/lib/dpkg/status")
	upperPackages, err := ReadDpkgStatus(dpkgStatusFile)
	if err != nil {
		if os.IsNotExist(err) {
			return // no dpkg files in upper, no need to merge
		} else {
			panic(err)
		}
	}

	lowerPackages, err := ReadDpkgStatus("/var/lib/lxc/vmroot/rootfs/var/lib/dpkg/status")
	if err != nil {
		panic(err)
	}

	// merge packages from lower to upper
	for name, lowerPkg := range lowerPackages {
		upperPkg, found := upperPackages[name]
		if found && upperPkg.Values["Version"] != lowerPkg.Values["Version"] {
			trimmedName := strings.TrimSpace(name)
			conffiles := make(map[string]string)

			//upperPkg["Conffiles"]

			// delete package files from overlay
			list, err := ioutil.ReadFile(vm.File("overlayfs-upperdir/var/lib/dpkg/info/" + trimmedName + ".list"))
			if err != nil {
				panic(err)
			} else {
				files := strings.Split(string(list), "\n")
				for _, file := range files {
					originalHash, found := conffiles[file]
					if found {
						hash := md5.New()
						f, err := os.Open(file)
						if err != nil {
							panic(err)
						}
						io.Copy(hash, f)
						f.Close()
						if string(hash.Sum(nil)) != originalHash {
							// config file was changes, do not delete from overlay
							continue
						}
					}
					os.Remove(file)
				}
			}

			// delete informations from overlay
			for _, ext := range DPKG_INFO_EXTENSIONS {
				os.Remove(vm.File("overlayfs-upperdir/var/lib/dpkg/info/" + trimmedName + ext))
			}
		}
		upperPackages[name] = lowerPkg
	}

	// delete packages that were removed in lower
	for name := range upperPackages {
		if _, found := lowerPackages[name]; found {
			continue // still in lower
		}
		_, err := os.Stat(vm.File("overlayfs-upperdir/var/lib/dpkg/info/" + name + ".list"))
		if err == nil {
			continue // files in overlay
		}
		delete(upperPackages, name)
	}

	err = WriteDpkgStatus(upperPackages, dpkgStatusFile)
	if err != nil {
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
		packages[pkg.Values["Package"]] = pkg
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
