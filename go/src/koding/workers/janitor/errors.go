package main

import "fmt"

var (
	ErrSubjectNotFound           = fmt.Errorf("subject not found")
	ErrKloudKlientNotInitialized = fmt.Errorf("kloud klient not initialized")
)
