package main

import (
	"errors"
	"fmt"
	"log"
)

type strToInf map[string]interface{}

func logAndReturnErr(errorMsg string, values ...interface{}) error {
	errorMsg = "Error: " + errorMsg
	errorMsg = fmt.Sprintf(errorMsg, values...)

	log.Printf(errorMsg)

	return errors.New(errorMsg)
}
