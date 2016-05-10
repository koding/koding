/*
 *
 * gocommon - Go library to interact with the JoyentCloud
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

package gocommon

import (
	gc "launchpad.net/gocheck"
)

type VersionTestSuite struct {
}

var _ = gc.Suite(&VersionTestSuite{})

func (s *VersionTestSuite) TestStringMatches(c *gc.C) {
	c.Assert(Version, gc.Equals, VersionNumber.String())
}
