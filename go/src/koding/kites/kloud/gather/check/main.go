package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

type Result struct {
	Error   string  `json:"error,omitempty"`
	Name    string  `json:"name"`
	Type    string  `json:"type"`
	Number  float64 `json:"number,omitempty"`
	Boolean float64 `json:"boolean,omitempty"`
}

var EarlyExit = fmt.Sprintf("klient works")

type Results []*Result

func main() {
	if len(os.Args) < 2 || os.Args[1] != "xAboBy" {
		fmt.Println(EarlyExit)
		os.Exit(0)
	}

	var results = Results{}

	commonBytes, err := Asset("checkers/common")
	if err != nil {
		log.Fatal(err)
	}

	for scriptPath, _ := range _bindata {
		if runnable(scriptPath) {
			result, err := runScript(commonBytes, scriptPath)
			if err != nil {
				continue
			}

			results = append(results, result)
		}
	}

	resultBytes, _ := json.Marshal(results)
	fmt.Println(string(resultBytes))
}

func runnable(scriptPath string) bool {
	return strings.Contains(scriptPath, "checkers/run-")
}

func runScript(commonBytes []byte, scriptPath string) (*Result, error) {
	scriptBytes, err := Asset(scriptPath)
	if err != nil {
		return nil, err
	}

	combinedBytes := fmt.Sprintf("%s\n%s", commonBytes, scriptBytes)
	resultBytes, err := exec.Command("bash", "-c", combinedBytes).Output()
	if err != nil {
		return nil, err
	}

	return encodeResult(resultBytes)
}

func encodeResult(resultBytes []byte) (*Result, error) {
	outputBuffer := bytes.NewBuffer(resultBytes)

	var result Result
	if err := json.NewDecoder(outputBuffer).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}
