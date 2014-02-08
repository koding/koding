package main

import (
	"errors"
	"flag"
	"fmt"
	"kite"
	"kite/kontrol"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"strconv"
)

var flagProfile = flag.String("c", "", "Configuration profile from file")

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please specify profile via -c. Aborting.")
	}

	conf := config.MustConfig(*flagProfile)

	kiteOptions := &kite.Options{
		Kitename:    "kontrol",
		Version:     "0.0.1",
		Port:        strconv.Itoa(conf.NewKontrol.Port),
		Region:      "sj",
		Environment: "development",
	}

	// Read list of etcd servers from config.
	machines := make([]string, len(conf.Etcd))
	for i, s := range conf.Etcd {
		machines[i] = "http://" + s.Host + ":" + strconv.FormatUint(uint64(s.Port), 10)
	}

	kon := kontrol.New(kiteOptions, machines, Public, Private)

	kon.AddAuthenticator("kodingKey", authenticateFromKodingKey)
	kon.AddAuthenticator("sessionID", authenticateFromSessionID)

	kon.Run()
}

func authenticateFromSessionID(r *kite.Request) error {
	username, err := findUsernameFromSessionID(r.Authentication.Key)
	if err != nil {
		return err
	}

	r.Username = username

	return nil
}

func findUsernameFromSessionID(sessionID string) (string, error) {
	session, err := modelhelper.GetSession(sessionID)
	if err != nil {
		return "", err
	}

	return session.Username, nil
}

func authenticateFromKodingKey(r *kite.Request) error {
	username, err := findUsernameFromKey(r.Authentication.Key)
	if err != nil {
		return err
	}

	r.Username = username

	return nil
}

func findUsernameFromKey(key string) (string, error) {
	kodingKey, err := modelhelper.GetKodingKeysByKey(key)
	if err != nil {
		return "", errors.New("kodingkey not found in kontrol db")
	}

	account, err := modelhelper.GetAccountById(kodingKey.Owner)
	if err != nil {
		return "", fmt.Errorf("register get user err %s", err)
	}

	if account.Profile.Nickname == "" {
		return "", errors.New("nickname is empty, could not register kite")
	}

	return account.Profile.Nickname, nil
}

const Public = `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1pUZ74ZTUgqnwWuvsYJ1
C0S4y/b3zeSuzlEnYGRiyZ/TC8OEx42qvXYODPB6v9FtoFXWQvzKobtML2j3tuP+
bKFuPXeD/8mwXTbzYax/sr4wx5gFmL2okHVqoVAdrO7qcO66fzkQAWtxbKxkVnPS
HP9NrsSoYxRhCfvbHOmF1jHrV86S9ysQJ4MCYkNii0UbO91lEKG/zNrMnO4Uq5eT
iJS05T4yERQdQpnrxHXEVeLEZCEMlXDG++K8fwRLBa31yHVNMRBT5NciE22fAQ0d
MNUxiajW1YoOC7jyHVWgeAPF+OBlcbEsU/raqdS87u0x4IutLxdMo5au4Glp5qab
gQIDAQAB
-----END PUBLIC KEY-----`

const Private = `-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA1pUZ74ZTUgqnwWuvsYJ1C0S4y/b3zeSuzlEnYGRiyZ/TC8OE
x42qvXYODPB6v9FtoFXWQvzKobtML2j3tuP+bKFuPXeD/8mwXTbzYax/sr4wx5gF
mL2okHVqoVAdrO7qcO66fzkQAWtxbKxkVnPSHP9NrsSoYxRhCfvbHOmF1jHrV86S
9ysQJ4MCYkNii0UbO91lEKG/zNrMnO4Uq5eTiJS05T4yERQdQpnrxHXEVeLEZCEM
lXDG++K8fwRLBa31yHVNMRBT5NciE22fAQ0dMNUxiajW1YoOC7jyHVWgeAPF+OBl
cbEsU/raqdS87u0x4IutLxdMo5au4Glp5qabgQIDAQABAoIBAQDNJ+yOBv0uWSWe
VZi6vCGvTlroFw1A+rzuYMSm8hNI9ddPTfVq3NU7It24HUsejdqkCq05inspOetT
AKalY0HjFkxR1CyNp4VI+bqjzcqhWBlHGt9u8xVwV/JEnFZi+mGG65e+/w2AbfsZ
jZC43y8priXVTAw5/kfwxazt7Y6aA4uNmrduvKXiKnsxYnZXbiDR7I4/AdUhiT29
aU7lZdpc3qY85lfx1UWULjv2pTsK2/gsulsgZIzh0VzXbfLpiFgXNnR3cTTOB+Pv
zJkhN/28oPHD6gZ1FSsrczVRai8j4aowRWgiyEDit202CwyBQb66FLI+wY2UpLvE
d8yava4BAoGBAPSHbi8khl04VcrNe1IEQJfw+1+g5hqfe6xyYjBKGokBlIf9K8HX
Oe//52wfykNZeDp41s+oB6K7BKEpN0ghYe2TVsSu9RJ4TajM8VpRZvjYr/42kBv/
iVcqMPSKOXvGHpTxrPLz+xYaMNfw6ArWp52a9gHxmxBxwpkQF0GBq6yRAoGBAOCm
CilkTBYdXiQ9evPlPU1758PWtTrrb3zVsOHtMNo9a/m07NrcfVxlI+ZgwMZvEoNH
95oPsNkdy5JMarmY0kOlzMOQHQ1gKao04+0ZJx1SlgVGi9ifx39jCYtFd8ZGVz0Y
82YJg2B3cuNYuOlhgJnSJGvCXlW2g3DHyJ0FljfxAoGBAK3UvOp8f5wzWSHTk3BJ
n5Wj9T8VBZ81ctizc8O6WkS9P9awjnO9Se2oMN73dnUMXGDM2IBEhjET3AWpZCg9
uv0F+e/WJFgd968hCg5XwejzOaFxLl8I+JxjXOvqe1TXEZR2fak08nDS65gHJR3X
XM64g1v8Ymx9QoZHHxEtWlpRAoGAaDng4Q9dla0ObnXvw5SJ+pcQEnZdIvb0hNCH
/moTjk2M+Q+ODITbzLBIFayyA96okiwjnmDFRhZiyn+VzIIwm54jAGCuefQxoHxl
ey1+TkZwwAXZACoxXtLOLMWQKnecJgabdq3XPDxvGzegovbPuY4bw7ssFUxWc07d
rqxW46ECgYEAvSmgxWGutjZIvjU8A5/7q+2zb9z4VW+yMGY1zn2ERLjFlkKUkk3T
3CBCvHh4XkExFUGbNEw0igRljX2z2ND7GYN01Kk2iL03IIbqjarpzCZoQmJJFP2h
YMsaLV9nB0nlXfg7uQZFybUT2qbnVn7Bv6z5m/wonQpO61vzn5FxvGI=
-----END RSA PRIVATE KEY-----`
