package config

import (
	"bufio"
	"context"
	"encoding/json"
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
			env, err := readEnv(testFile)
			if err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}

			ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
			generatedRaw, err := generateConfig(ctx, env)
			if err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}

			// update golden file if necessary
			golden := strings.TrimSuffix(testFile, ".env") + ".json.golden"
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

			// Unmarshal in order to avoid map ordering issues.
			var generatedCfg, goldenCfg Config
			if err := json.Unmarshal(generatedRaw, &generatedCfg); err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}
			if err := json.Unmarshal(goldenRaw, &goldenCfg); err != nil {
				t.Fatalf("want err == nil; got %v", err)
			}

			if !reflect.DeepEqual(generatedCfg, goldenCfg) {
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

		if filepath.Ext(path) == ".env" {
			testFiles = append(testFiles, path)
		}

		return nil
	}

	if err := filepath.Walk(path, walkFn); err != nil {
		return nil, err
	}

	return testFiles, nil
}

func readEnv(path string) (env []string, err error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		env = append(env, strings.TrimSpace(scanner.Text()))
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	if env == nil {
		env = []string{"GO_CONFIG_TEST_NO_ENV=1"}
	}

	return env, nil
}

func generateConfig(ctx context.Context, env []string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, "go", "run", "genconfig.go")
	cmd.Env = env
	return cmd.Output()
}
