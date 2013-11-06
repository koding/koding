// +build linux

// Copyright © 2013, S.Çağlar Onur
// Use of this source code is governed by a LGPLv2.1
// license that can be found in the LICENSE file.
//
// Authors:
// S.Çağlar Onur <caglar@10ur.org>

// +build linux

package lxc

// #include <stdlib.h>
import "C"

import (
	"unsafe"
)

func makeArgs(args []string) []*C.char {
	ret := make([]*C.char, len(args)+1)
	for i, s := range args {
		ret[i] = C.CString(s)
	}
	ret[len(ret)-1] = nil
	return ret
}

func freeArgs(cArgs []*C.char) {
	for _, s := range cArgs {
		C.free(unsafe.Pointer(s))
	}
}
