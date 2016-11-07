// +build ignore

package main

import (
	"crypto/md5"
	"encoding/hex"
	"flag"
	"io/ioutil"
	"log"
	"os"
	"os/exec"

	"github.com/jteeuwen/go-bindata"
)

var (
	pkg    = flag.String("pkg", "-", "")
	input  = flag.String("i", "-", "")
	output = flag.String("o", "-", "")
)

func main() {
	flag.Parse()

	outputTmp := "tmp_" + *output

	cfg := bindata.NewConfig()
	cfg.Package = *pkg
	cfg.Mode = 420
	cfg.ModTime = 1476710288
	cfg.Input = append(cfg.Input, bindata.InputConfig{Path: *input})
	cfg.Output = outputTmp

	if err := bindata.Translate(cfg); err != nil {
		log.Fatalf("cannot create %s: %v", outputTmp, err)
	}

	if err := exec.Command("go", "fmt", outputTmp).Run(); err != nil {
		log.Fatalf("cannot go fmt %s: %v", outputTmp, err)
	}

	tmpMD5, err := fileMD5(outputTmp)
	if err != nil {
		log.Fatalf("cannot create MD5 sum for %s: %v", outputTmp, err)
	}

	outMD5, err := fileMD5(*output)
	if err != nil && !os.IsNotExist(err) {
		log.Fatalf("cannot create MD5 sum for %s: %v", *output, err)
	}

	if tmpMD5 != outMD5 {
		if err := os.Rename(outputTmp, *output); err != nil {
			log.Fatalf("cannot rename %s -> %s: %v", outputTmp, *output, err)
		}
	} else {
		if err := os.Remove(outputTmp); err != nil {
			log.Println("cannot remove temporary file %s: %v", outputTmp, err)
		}
	}
}

func fileMD5(path string) (string, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return "", err
	}

	hash := md5.Sum(data)
	return hex.EncodeToString(hash[:]), nil
}
