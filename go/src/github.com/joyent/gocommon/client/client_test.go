//
// gocommon - Go library to interact with the JoyentCloud
//
//
// Copyright (c) 2013 Joyent Inc.
//
// Written by Daniele Stroppa <daniele.stroppa@joyent.com>
//

package client_test

import (
	"flag"
	"fmt"
	"github.com/joyent/gocommon/client"
	joyenthttp "github.com/joyent/gocommon/http"
	"github.com/joyent/gocommon/jpc"
	"github.com/joyent/gosign/auth"
	gc "launchpad.net/gocheck"
	"net/http"
	"testing"
	"time"
)

type ClientSuite struct {
	creds *auth.Credentials
}

var keyName = flag.String("key.name", "", "Specify the full path to the private key, defaults to ~/.ssh/id_rsa")

func Test(t *testing.T) {
	creds, err := jpc.CompleteCredentialsFromEnv(*keyName)
	if err != nil {
		t.Fatalf("Error setting up test suite: %v", err)
	}

	gc.Suite(&ClientSuite{creds: creds})
	gc.TestingT(t)
}

func (s *ClientSuite) TestNewClient(c *gc.C) {
	cl := client.NewClient(s.creds.SdcEndpoint.URL, "", s.creds, nil)
	c.Assert(cl, gc.NotNil)
}

func (s *ClientSuite) TestSendRequest(c *gc.C) {
	cl := client.NewClient(s.creds.SdcEndpoint.URL, "", s.creds, nil)
	c.Assert(cl, gc.NotNil)

	req := joyenthttp.RequestData{}
	resp := joyenthttp.ResponseData{ExpectedStatus: []int{http.StatusOK}}
	err := cl.SendRequest(client.GET, "", "", &req, &resp)
	c.Assert(err, gc.IsNil)
}

func (s *ClientSuite) TestSignURL(c *gc.C) {
	cl := client.NewClient(s.creds.MantaEndpoint.URL, "", s.creds, nil)
	c.Assert(cl, gc.NotNil)

	path := fmt.Sprintf("/%s/stor", s.creds.UserAuthentication.User)
	singedUrl, err := cl.SignURL(path, time.Now().Add(time.Minute*5))
	c.Assert(err, gc.IsNil)
	c.Assert(singedUrl, gc.Not(gc.Equals), "")
}
