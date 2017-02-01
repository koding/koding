// (c) Copyright 2016 Hewlett Packard Enterprise Development LP
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	gas "github.com/HewlettPackard/gas/core"
	"github.com/HewlettPackard/gas/output"
)

// #nosec flag
var flagIgnoreNoSec = flag.Bool("nosec", false, "Ignores #nosec comments when set")

// format output
var flagFormat = flag.String("fmt", "text", "Set output format. Valid options are: json, csv of text")

// output file
var flagOutput = flag.String("out", "", "Set output file for results")

var usageText = `
GAS - Go AST Scanner

Gas analyzes Go source code to look for common programming mistakes that
can lead to security problems.

USAGE:

	# Check a single Go file
	$ gas example.go

	# Check all files under the current directory and save results in
	# json format.
	$ gas -fmt=json -out=results.json ./...

	# Run a specific set of rules (by default all rules will be run):
	$ gas -rule=sql -rule=sql ./...

`

func usage() {
	fmt.Fprintln(os.Stderr, usageText)
	fmt.Fprint(os.Stderr, "OPTIONS:\n\n")
	flag.PrintDefaults()
}

func main() {

	// Setup usage description
	flag.Usage = usage

	//  Exclude files
	var excluded filelist = []string{"*_test.go"}
	flag.Var(&excluded, "exclude", "File pattern to exclude from scan")

	// Rule configuration
	rules := newRulelist()
	flag.Var(&rules, "rule", "GAS rules enabled when performing a scan")

	// Custom commands / utilities to run instead of default analyzer
	tools := newUtils()
	flag.Var(tools, "tool", "GAS utilities to assist with rule development")

	// Parse command line arguments
	flag.Parse()

	// Setup logging
	logger := log.New(os.Stderr, "[gas]", log.LstdFlags)

	// Ensure at least one file was specified
	if flag.NArg() == 0 {

		fmt.Fprintf(os.Stderr, "\nerror: FILE [FILE...] or './...' expected\n")
		flag.Usage()
		os.Exit(1)
	}

	// Run utils instead of analysis
	if len(tools.call) > 0 {
		tools.run(flag.Args()...)
		os.Exit(0)
	}

	// Setup analyzer
	analyzer := gas.NewAnalyzer(*flagIgnoreNoSec, logger)
	if !rules.overwritten {
		rules.useDefaults()
	}
	rules.apply(&analyzer)

	// Traverse directory structure if './...'
	if flag.NArg() == 1 && flag.Arg(0) == "./..." {

		cwd, err := os.Getwd()
		if err != nil {
			logger.Fatalf("Unable to traverse path %s, reason - %s", flag.Arg(0), err)
		}
		filepath.Walk(cwd, func(path string, info os.FileInfo, err error) error {
			if excluded.Contains(path) && info.IsDir() {
				logger.Printf("Skipping %s\n", path)
				return filepath.SkipDir
			}
			if !info.IsDir() && !excluded.Contains(path) &&
				strings.HasSuffix(path, ".go") {
				err = analyzer.Process(path)
				if err != nil {
					logger.Fatal(err)
				}
			}
			return nil
		})

	} else {

		// Process each file individually
		for _, filename := range flag.Args() {
			if finfo, err := os.Stat(filename); err == nil {
				if !finfo.IsDir() && !excluded.Contains(filename) &&
					strings.HasSuffix(filename, ".go") {
					if err = analyzer.Process(filename); err != nil {
						logger.Fatal(err)
					}
				}
			} else {
				logger.Fatal(err)
			}
		}
	}

	// Create output report
	if *flagOutput != "" {
		outfile, err := os.Create(*flagOutput)
		if err != nil {
			logger.Fatalf("Couldn't open: %s for writing. Reason - %s", *flagOutput, err)
		}
		defer outfile.Close()
		output.CreateReport(outfile, *flagFormat, &analyzer)
	} else {
		output.CreateReport(os.Stdout, *flagFormat, &analyzer)
	}
}
