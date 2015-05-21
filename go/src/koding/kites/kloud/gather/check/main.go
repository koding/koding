package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

type Result struct {
	Error     string  `json:"error,omitempty"`
	Name      string  `json:"name"`
	Type      string  `json:"type"`
	Number    float64 `json:"number"`
	Timestamp string  `json:"timestamp"`
}

var EarlyExit = fmt.Sprintf("klient works")

func init() {
	if len(os.Args) < 2 || os.Args[1] != "xAboBy" {
		fmt.Println(EarlyExit)
		os.Exit(0)
	}
}

func main() {
	var results = []interface{}{}

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

	log.Println(results)
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

	var result = &Result{Timestamp: time.Now().String()}
	if err := json.NewDecoder(outputBuffer).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}
