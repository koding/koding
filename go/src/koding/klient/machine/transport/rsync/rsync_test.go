package rsync_test

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"koding/klient/machine/transport/rsync"
)

var update = flag.Bool("update", false, "update golden files")

const dataDir = "testdata"

func dumpFile(name string) *exec.Cmd {
	args := append([]string{"-test.run=TestHelperProcess", "--", "file", name})
	cmd := exec.Command(os.Args[0], args...)
	cmd.Env = []string{"GO_WANT_HELPER_PROCESS=1"}
	return cmd
}

func TestRsyncProgress(t *testing.T) {
	files, err := ioutil.ReadDir(dataDir)
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	for _, file := range files {
		var (
			name = filepath.Join(dataDir, file.Name())
			base = strings.TrimRight(file.Name(), ".out")
		)

		// Skip other files than process .out.
		if filepath.Ext(name) != ".out" {
			continue
		}

		t.Run(base, func(t *testing.T) {
			t.Parallel()

			var buf bytes.Buffer
			cmd := &rsync.Command{
				Cmd:             dumpFile(name),
				SourcePath:      "/ignore",
				DestinationPath: "/ignore",
				Progress: func(n, size, _ int64, err error) {
					if err == nil {
						fmt.Fprintf(&buf, "Files: %d, Size %d\n", n, size)
					} else if err != io.EOF {
						fmt.Fprintf(&buf, "Unexpected error occurred: %v\n", err)
					}
				},
			}

			if err := cmd.Run(context.Background()); err != nil {
				t.Fatalf("want err = nil; got: %v", err)
			}
			got := buf.Bytes()

			// Update golden file if necessary.
			golden := filepath.Join(dataDir, fmt.Sprintf("%s.golden", base))
			if *update {
				err := ioutil.WriteFile(golden, got, 0644)
				if err != nil {
					t.Fatalf("want err = nil; got: %v", err)
				}
				return
			}

			// Get golden file,
			want, err := ioutil.ReadFile(golden)
			if err != nil {
				t.Fatalf("want err = nil; got: %v", err)
			}

			if !bytes.Equal(got, want) {
				t.Fatalf("progress output %s\n\tgot:\n%s\n\twant:\n%s", base, got, want)
			}
		})
	}
}

// TestHelperProcess is not a real test. It is used as a helper process and
// prints each given command line argument in a separate line.
func TestHelperProcess(t *testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}
	defer os.Exit(0)

	args := os.Args
	for len(args) > 0 {
		if args[0] == "--" {
			args = args[1:]
			break
		}
		args = args[1:]
	}

	if len(args) < 2 {
		os.Exit(1)
	}

	command, args := args[0], args[1:]
	switch command {
	case "file":
		bs, err := ioutil.ReadFile(args[0])
		if err != nil {
			os.Exit(2)
		}
		io.Copy(os.Stdout, bytes.NewReader(bs))
	case "args":
		fmt.Fprintf(os.Stdout, strings.Join(args, "\n"))
	}
}
