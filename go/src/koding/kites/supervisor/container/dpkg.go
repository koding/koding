package container

import (
	"bufio"
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"unicode"
)

type Package struct {
	Fields []string
	Values map[string]string
}

type DpkgVersion struct {
	Epoch    int
	Version  string
	Revision string
}

func ParseDpkgVerion(s string) *DpkgVersion {
	var version DpkgVersion

	epochParts := strings.SplitN(s, ":", 2)
	if len(epochParts) == 2 {
		version.Epoch, _ = strconv.Atoi(epochParts[0])
	}

	revisionParts := strings.SplitN(epochParts[len(epochParts)-1], "-", 2)
	if len(revisionParts) == 2 {
		version.Revision = revisionParts[1]
	}

	version.Version = revisionParts[0]

	return &version
}

// translated from dpkg source code
func dpkgOrder(r rune) int {
	if unicode.IsDigit(r) {
		return 0
	}
	if unicode.IsLetter(r) {
		return int(r)
	}
	if r == '~' {
		return -1
	}
	if r == 0 {
		return 0
	}
	return int(r) + 256
}

// translated from dpkg source code
func dpkgCompare(a string, b string) int {
	c := func(s string, i int) rune {
		if i >= len(s) {
			return 0
		}
		return rune(s[i])
	}

	ai := 0
	bi := 0
	for c(a, ai) != 0 || c(b, bi) != 0 {
		for (c(a, ai) != 0 && !unicode.IsDigit(c(a, ai))) || (c(b, bi) != 0 && !unicode.IsDigit(c(b, bi))) {
			ac := dpkgOrder(c(a, ai))
			bc := dpkgOrder(c(b, bi))

			if ac != bc {
				return ac - bc
			}

			ai += 1
			bi += 1
		}

		for c(a, ai) == '0' {
			ai += 1
		}
		for c(b, bi) == '0' {
			bi += 1
		}

		firstDiff := 0
		for unicode.IsDigit(c(a, ai)) && unicode.IsDigit(c(b, bi)) {
			if firstDiff == 0 {
				firstDiff = int(c(a, ai) - c(b, bi))
			}
			ai += 1
			bi += 1
		}
		if unicode.IsDigit(c(a, ai)) {
			return 1
		}
		if unicode.IsDigit(c(b, bi)) {
			return -1
		}
		if firstDiff != 0 {
			return firstDiff
		}
	}

	return 0
}

func (a *DpkgVersion) Compare(b *DpkgVersion) int {
	if a.Epoch > b.Epoch {
		return 1
	}
	if a.Epoch < b.Epoch {
		return -1
	}

	if r := dpkgCompare(a.Version, b.Version); r != 0 {
		return r
	}

	return dpkgCompare(a.Revision, b.Revision)
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

func (c *Container) MergeDpkgDatabase() {
	dpkgStatusFile := c.OverlayPath("var/lib/dpkg/status")
	upperPackages, err := ReadDpkgStatus(dpkgStatusFile)
	if err != nil {
		if !os.IsNotExist(err) {
			panic(err)
		}
		return // no file in upper, no need to merge
	}

	lowerPackages, err := ReadDpkgStatus(vmRoot + "rootfs/var/lib/dpkg/status")
	if err != nil {
		panic(err)
	}

	// merge packages from lower to upper
	for name, lowerPkg := range lowerPackages {
		upperPkg, found := upperPackages[name]
		if found && ParseDpkgVerion(upperPkg.Values["Version"]).Compare(ParseDpkgVerion(lowerPkg.Values["Version"])) < 0 {
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
			list, err := ioutil.ReadFile(c.OverlayPath(listFile))
			if err != nil {
				list, err = ioutil.ReadFile(vmRoot + "rootfs/" + listFile)
				if err != nil {
					panic(err)
				}
			}
			files := strings.Split(string(list), "\n")
			for _, file := range files {
				overlayFile := c.OverlayPath(file)
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
				os.Remove(c.OverlayPath(upperPkg.InfoFile(ext)))
			}
		}
		upperPackages[name] = lowerPkg
	}

	// delete packages that were removed in lower
	for name, upperPkg := range upperPackages {
		if _, found := lowerPackages[name]; found {
			continue // still in lower
		}
		_, err := os.Stat(c.OverlayPath(upperPkg.InfoFile("list")))
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
