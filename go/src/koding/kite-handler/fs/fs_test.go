package fs

import (
	"testing"

	"github.com/koding/kite"
)

var fs *kite.Kite

func init() {
	fs = kite.New("fs", "0.0.1")
	fs.Config.DisableAuthentication = true
	fs.Config.Port = 3636
	fs.HandleFunc("readDirectory", ReadDirectory)
	fs.HandleFunc("glob", Glob)
	fs.HandleFunc("readFile", ReadFile)
	fs.HandleFunc("writeFile", WriteFile)
	fs.HandleFunc("uniquePath", UniquePath)
	fs.HandleFunc("getInfo", GetInfo)
	fs.HandleFunc("setPermissions", SetPermissions)
	fs.HandleFunc("remove", Remove)
	fs.HandleFunc("rename", Rename)
	fs.HandleFunc("createDirectory", CreateDirectory)
	fs.HandleFunc("move", Move)
	fs.HandleFunc("copy", Copy)

	go fs.Run()
	<-fs.ServerReadyNotify()
}

func TestReadDirectory(t *testing.T)   {}
func TestGlob(t *testing.T)            {}
func TestReadFile(t *testing.T)        {}
func TestWriteFile(t *testing.T)       {}
func TestUniquePath(t *testing.T)      {}
func TestGetInfo(t *testing.T)         {}
func TestSetPermissions(t *testing.T)  {}
func TestRemove(t *testing.T)          {}
func TestRename(t *testing.T)          {}
func TestCreateDirectory(t *testing.T) {}
func TestMove(t *testing.T)            {}
func TestCopy(t *testing.T)            {}
