// fuzzgc feeds a go compiler with random input and checks for errors.
package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

var gofiles = make([]string, 0, 1024)

func initContents() {
	goroot := runtime.GOROOT()
	gopath := os.Getenv("GOPATH")
	filepath.Walk(goroot, func(p string, info os.FileInfo, err error) error {
		if info.IsDir() {
			return nil
		}
		if strings.HasSuffix(p, ".go") {
			gofiles = append(gofiles, p)
		}
		return nil
	})
	filepath.Walk(gopath, func(p string, info os.FileInfo, err error) error {
		if info.IsDir() {
			return nil
		}
		if strings.HasSuffix(p, ".go") {
			gofiles = append(gofiles, p)
		}
		return nil
	})
	log.Printf("%d files found", len(gofiles))
}

var lines []string

func readContents() {
	args := []string{"-comments=false"}
	args = append(args, gofiles...)
	data, _ := exec.Command("gofmt", args...).Output()
	for _, line := range strings.Split(string(data), "\n") {
		if strings.Contains(line, "var rows") {
			// HACK: known to cause problems.
			continue
		}
		if len(line) > 0 && line[0] < 128 {
			// ignore blank lines and non-ASCII initials.
			lines = append(lines, strings.TrimSpace(line))
		}
	}
	log.Printf("%d lines read", len(lines))
}

func main() {
	initContents()
	readContents()
	go loop()
	go loop()
	go loop()
	loop()
}

func loop() {
	for {
		tmpdir, files, err := writeRandomPackage("/dev/shm")
		if err != nil {
			log.Fatal(err)
		}
		err = compilePackage(tmpdir, files)
		if err == nil {
			os.RemoveAll(tmpdir)
		} else {
			log.Printf("%s: %s", tmpdir, err)
		}
	}
}

func writeRandomFile(name string) error {
	f, err := os.Create(name)
	if err != nil {
		return err
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	defer w.Flush()

	n_lines := rand.Intn(300) + 50
	for i := 0; i < n_lines; i++ {
		line := lines[rand.Intn(len(lines))]
		words := strings.Fields(line)
		if i := rand.Intn(100); i < len(words) {
			// pop a random word
			words = append(words[:i], words[i+1:]...)
		}
		line = strings.Join(words, " ")
		w.WriteString(line)
		w.WriteString("\n")
	}
	return nil
}

func writeRandomPackage(tmpdir string) (string, []string, error) {
	tmpname, err := ioutil.TempDir(tmpdir, "fuzzgc")
	if err != nil {
		return "", nil, err
	}
	n_files := rand.Intn(7) + 2
	files := make([]string, n_files)
	for i := 0; i < n_files; i++ {
		fname := fmt.Sprintf("%s/%d.go", tmpname, i)
		files[i] = fname
		err := writeRandomFile(fname)
		if err != nil {
			return "", nil, fmt.Errorf("cound not write to %q: %s", fname, err)
		}
	}
	return tmpname, files, nil
}

func compilePackage(tmpdir string, files []string) error {
	args := []string{"-c", "-O2", "-g", "-pipe", "-Wall"}
	args = append(args, files...)
	cmd := exec.Command("gccgo", args...)
	cmd.Env = []string{"PATH=" + os.Getenv("PATH"), "MALLOC_CHECK_=1", "LIBC_FATAL_STDERR_=1"}
	out, _ := cmd.CombinedOutput()
	for _, line := range strings.Split(string(out), "\n") {
		if strings.Contains(line, "strings.Contains") {
			// don't fuzz myself.
			continue
		}
		switch {
		case strings.Contains(line, "internal compiler error"),
			strings.Contains(line, "out of memory"),
			strings.Contains(line, "glibc detected"):
			return fmt.Errorf("%s", line)
		}
	}
	return nil
}
