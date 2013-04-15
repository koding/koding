package main

import (
	"io/ioutil"
	"os"
	"strconv"
	"syscall"
)

func main() {
	amount, err := strconv.Atoi(os.Args[2])
	if err != nil {
		panic(err)
	}
	shift(os.Args[1], amount)
}

func shift(path string, amount int) {
	info, err := os.Lstat(path)
	if err != nil {
		panic(err)
	}

	if err := os.Lchown(path, int(info.Sys().(*syscall.Stat_t).Uid+uint32(amount)), int(info.Sys().(*syscall.Stat_t).Gid+uint32(amount))); err != nil {
		panic(err)
	}

	if info.IsDir() {
		children, err := ioutil.ReadDir(path)
		if err != nil {
			panic(err)
		}
		for _, child := range children {
			shift(path+"/"+child.Name(), amount)
		}
	}
}
