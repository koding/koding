/*
 *
 * gosign - Go HTTP signing library for the Joyent Public Cloud and Joyent Manta
 *
 *
 * Copyright (c) 2016 Joyent Inc.
 *
 * Written by Daniele Stroppa <daniele.stroppa@joyent.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package gosign

import (
	gc "launchpad.net/gocheck"
	"testing"
)

func Test(t *testing.T) {
	gc.TestingT(t)
}

type GoSignTestSuite struct {
}

var _ = gc.Suite(&GoSignTestSuite{})
