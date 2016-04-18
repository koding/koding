//
// gosdc - Go library to interact with the Joyent CloudAPI
//
//
// Copyright (c) 2013 Joyent Inc.
//
// Written by Daniele Stroppa <daniele.stroppa@joyent.com>
//

package gosdc

import (
	gc "launchpad.net/gocheck"
	"testing"
)

func Test(t *testing.T) {
	gc.TestingT(t)
}

type GoSdcTestSuite struct {
}

var _ = gc.Suite(&GoSdcTestSuite{})
