//
// gosign - Go HTTP signing library for the Joyent Public Cloud and Joyent Manta
//
//
// Copyright (c) 2013 Joyent Inc.
//
// Written by Daniele Stroppa <daniele.stroppa@joyent.com>
//

package auth_test

import (
	"net/http"
	"testing"

	gc "launchpad.net/gocheck"

	"github.com/joyent/gosign/auth"
)

const (
	SdcSignature   = "yK0J17CQ04ZvMsFLoH163Sjyg8tE4BoIeCsmKWLQKN3BYgSpR0XyqrecheQ2A0o4L99oSumYSKIscBSiH5rqdf4/1zC/FEkYOI2UzcIHYb1MPNzO3g/5X44TppYE+8dxoH99V+Ts8RT3ZurEYjQ8wmK0TnxdirAevSpbypZJaBOFXUZSxx80m5BD4QE/MSGo/eaVdJI/Iw+nardHNvimVCr6pRNycX1I4FdyRR6kgrAl2NkY2yxx/CAY21Ir+dmbG3A1x4GiIE485LLheAL5/toPo7Gh8G5fkrF9dXWVyX0k9AZXqXNWn5AZxc32dKL2enH09j/X86RtwiR1IEuPww=="
	MantaSignature = "unBowZ/HOydMxzYkmoB192rn006vujsuZvhx/CieAl+k+YoQsHMM1tAPwbxs71o65sMMymRBZGOZU91lvbEW94rF950HDYy1mhqTf4QAHXc3Km3lInXvAQuvsMrZUofNApzxIdAacNL/ESJ8JCU8sxT2919cDCKkVI8vqOvUJvCyCSIlkBr9d+MLBHuFwr6zRgd3pZSMbMoKrrX6XzsQIUhOldrbSJXYzaQnwvvY2pygPEl491mzY+gt+jiykSVTMlLM2+iCrP4/rmMHenpGYjN2tNftNwo2U6rFwWKwWkK5G1n5YrKMLIt6CV6z+nFLsvhimCtP7WY+pOuVU+1hrA=="
	testJpcKeyName = "test_key"
	key            = `-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAyLOtVh8qXjdwfjZZYwkEgg1yoSzmpKKpmzYW745lBGtPH87F
spHVHeqjmgFnBsARsD7CHzYyQTho7oLrAEbuF7tKdGRK25wJIenPKKuL+UVwZNeJ
VEXSiMNmX3Y4IqRteqRIjhw3DmXYHEWvBc2JVy8lWtyK+o6o8jlO0aRTTT2+dETp
yqKqNJyHVNz2u6XVtm7jqyLU7tAqW+qpr5zSoNmuUAyz6JDCRnlWvwp1qzuS1LV3
2HK9yfq8TGriDVPyPRpFRmiRGWGIrIKrmm4sImpoLfuVBITjeh8V3Ee0OCDmTLgY
lTHAmCLFJxaW5Y8b4cTt5pbT7R1iu77RKJo3fwIBIwKCAQEAmtPAOx9bMr0NozE9
pCuHIn9nDp77EUpIUym57AAiCrkuaP6YgnB/1T/6jL9A2VJWycoDdynO/xzjO6bS
iy9nNuDwSyjMCH+vRgwjdyVAGBD+7rTmSFMewUZHqLpIj8CsOgm0UF7opLT3K8C6
N60vbyRepS3KTEIqjvkCSfPLO5Sp38KZYXKg0/Abb21WDSEzWonjV8JfOyMfUYhh
7QCE+Nf8s3b+vxskOuCQq1WHoqo8CqXrMYVknkvnQuRFPuaOLEjMbJVqlTb9ns2V
SKxmo46R7fl2dKgMBll+Nec+3Dn2/Iq/qnHq34HF/rhz0uvQDv1w1cSEMjLQaHtH
yZMkgwKBgQDtIAY+yqcmGFYiHQT7V35QbmfeJX1/v9KgpcA7L9Qi6H2LgKPlZu3e
Fc5Pp8C82uIzxuKBbEqauoWAEfP7r2wn1EwoQGMdsY9MpPiScS5iwLKuiSWyyjyf
Snmq+wLwVMYr71ijCuD+Ydm2xGoYeogwkV+QuTOS79s7HGM5tAN9TQKBgQDYrXHR
Nc84Xt+86cWCXJ2rAhHoTMXQQSVXoc75CjBPM2oUH6iguVBM7dPG0ORU14+o7Q7Y
gUvQCV6xoWH05nESHG++sidRifM/HT07M1bSjbMPcFmeAeA0mTFodXfRN6dKyibb
5kHUHgkgsC8qpXZr1KsNR7BcvC+xKuG1qC1R+wKBgDz5mzS3xJTEbeuDzhS+uhSu
rP6b7RI4o+AqnyUpjlIehq7X76FjnEBsAdn377uIvdLMvebEEy8aBRJNwmVKXaPX
gUwt0FgXtyJWTowOeaRdb8Z7CbGht9EwaG3LhGmvZiiOANl303Sc0ZVltOG5G7S3
qtwSXbgRyqjMyQ7WhI3vAoGBAMYa67f2rtRz/8Kp2Sa7E8+M3Swo719RgTotighD
1GWrWav/sB3rQhpzCsRnNyj/mUn9T2bcnRX58C1gWY9zmpQ3QZhoXnZvf0+ltFNi
I36tcIMk5DixQgQ0Sm4iQalXdGGi4bMbqeaB3HWoZaNVc5XJwPYy6mNqOjuU657F
pcdLAoGBAOQRc5kaZ3APKGHu64DzKh5TOam9J2gpRSD5kF2fIkAeaYWU0bE9PlqV
MUxNRzxbIC16eCKFUoDkErIXGQfIMUOm+aCT/qpoAdXIvuO7H0OYRjMDmbscSDEV
cQYaFsx8Z1KwMVBTwDtiGXhd+82+dKnXxH4bZC+WAKs7L79HqhER
-----END RSA PRIVATE KEY-----`
)

func Test(t *testing.T) { gc.TestingT(t) }

type AuthSuite struct {
}

var _ = gc.Suite(&AuthSuite{})

func (s *AuthSuite) TestCreateSdcAuthorizationHeader(c *gc.C) {
	headers := make(http.Header)
	headers["Date"] = []string{"Mon, 14 Oct 2013 18:49:29 GMT"}
	authentication, err := auth.NewAuth("test_user", key, "rsa-sha256")
	c.Assert(err, gc.IsNil)
	credentials := &auth.Credentials{
		UserAuthentication: authentication,
		SdcKeyId:           "test_key",
		SdcEndpoint:        auth.Endpoint{URL: "http://gotest.api.joyentcloud.com"},
	}
	authHeader, err := auth.CreateAuthorizationHeader(headers, credentials, false)
	c.Assert(err, gc.IsNil)
	c.Assert(authHeader, gc.Equals, "Signature keyId=\"/test_user/keys/"+testJpcKeyName+"\",algorithm=\"rsa-sha256\" "+SdcSignature)
}

func (s *AuthSuite) TestCreateMantaAuthorizationHeader(c *gc.C) {
	headers := make(http.Header)
	headers["Date"] = []string{"Mon, 14 Oct 2013 18:49:29 GMT"}
	authentication, err := auth.NewAuth("test_user", key, "rsa-sha256")
	c.Assert(err, gc.IsNil)
	credentials := &auth.Credentials{
		UserAuthentication: authentication,
		MantaKeyId:         "test_key",
		MantaEndpoint:      auth.Endpoint{URL: "http://gotest.manta.joyent.com"},
	}
	authHeader, err := auth.CreateAuthorizationHeader(headers, credentials, true)
	c.Assert(err, gc.IsNil)
	c.Assert(authHeader, gc.Equals, "Signature keyId=\"/test_user/keys/"+testJpcKeyName+"\",algorithm=\"rsa-sha256\",signature=\""+MantaSignature+"\"")
}
