package sh

import (
	"runtime"
	"testing"
)

func TestAlias(t *testing.T) {
	s := NewSession()
	s.Alias("gr", "echo", "hi")
	out, err := s.Command("gr", "sky").Output()
	if err != nil {
		t.Error(err)
	}
	if string(out) != "hi sky\n" {
		t.Errorf("expect 'hi sky' but got:%s", string(out))
	}
}

func TestCommand1(t *testing.T) {
	var err error
	err = Command("echo", "hello123").Run()
	if err != nil {
		t.Error(err)
	}
}

/*
func TestCapture(t *testing.T) {
	r, err := Capture("echo", []string{"hello"})
	if err != nil {
		t.Error(err)
	}
	_ = r
	if r.Trim() != "hello" {
		t.Errorf("expect hello, but got %s", r.Trim())
	}
}
*/

func TestSession(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Log("ignore test on windows")
		return
	}
	session := NewSession()
	session.ShowCMD = true
	err := session.Call("pwd")
	if err != nil {
		t.Error(err)
	}
	out, err := session.SetDir("/").Command("pwd").Output()
	if err != nil {
		t.Error(err)
	}
	if string(out) != "/\n" {
		t.Errorf("expect /, but got %s", string(out))
	}
}

/*
	#!/bin/bash -
	#
	export PATH=/usr/bin:/bin
	alias ll='ls -l'
	cd /usr
	if test -d "local"
	then
		ll local | awk '{print $1, $NF}' | grep bin
	fi
*/
func TestExample(t *testing.T) {
	s := NewSession()
	s.ShowCMD = true
	s.Env["PATH"] = "/usr/bin:/bin"
	s.SetDir("/usr")
	s.Alias("ll", "ls", "-l")
	//s.Stdout = nil
	if s.Test("d", "local") {
		//s.Command("ll", []string{"local"}).Command("awk", []string{"{print $1, $NF}"}).Command("grep", []string{"bin"}).Run()
		s.Command("ll", "local").Command("awk", "{print $1, $NF}").Command("grep", "bin").Run()
	}
}
