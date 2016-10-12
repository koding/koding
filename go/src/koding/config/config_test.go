package config

import (
	"context"
	"flag"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

var update = flag.Bool("update", false, "update golden (.golden) files")

const dataDir = "testdata"

func TestConfig(t *testing.T) {
	testFiles, err := readTestFiles(dataDir)
	if err != nil {
		t.Fatalf("want err == nil; got %v", err)
	}

	for _, testFile := range testFiles {
		t.Run(testFile, func(t *testing.T) {
			ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
			generatedRaw, err := generateConfig(ctx, testFile)
			if err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}

			// update golden file if necessary
			golden := strings.TrimSuffix(testFile, ".json") + ".go.golden"
			if *update {
				err := ioutil.WriteFile(golden, generatedRaw, 0644)
				if err != nil {
					t.Error("want err == nil; got %v", err)
				}
				return
			}

			goldenRaw, err := ioutil.ReadFile(golden)
			if err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}

			if !reflect.DeepEqual(generatedRaw, goldenRaw) {
				t.Fatalf("want: \n\t%s\ngot:\n\t%s\n", string(goldenRaw), string(generatedRaw))
			}
		})
	}
}

func readTestFiles(path string) (testFiles []string, err error) {
	walkFn := func(path string, _ os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if filepath.Ext(path) == ".json" {
			testFiles = append(testFiles, path)
		}

		return nil
	}

	if err := filepath.Walk(path, walkFn); err != nil {
		return nil, err
	}

	return testFiles, nil
}

func generateConfig(ctx context.Context, input string) ([]byte, error) {
	return exec.CommandContext(ctx, "go", "run", "genconfig.go", "-i", input).Output()
}
