// +build linux darwin

package main

import (
	"syscall"
)

func init() {
	signals = append(signals, syscall.SIGQUIT, syscall.SIGABRT)
}
