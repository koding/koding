package main

const (
	Version = "0.0.1"

	// kloudctl is being printed as `kd` on runtime
	Name = "kd"

	// The user facing name for Klient, since we may be hiding it
	// like in the Klient Installer.
	KlientName = "Koding Service Connector"

	// The klient addres to connect to
	KlientAddress = "http://127.0.0.1:56789/kite"

	// A path to the kite key that we will use to authenticate to the given
	// klient
	KiteHome = "/etc/kite"

	// The directory that klient will be downloaded/installed to
	KlientDirectory = "/opt/kite/klient"

	KontrolUrl = "http://kdonkd.leeolayvar.koding.io:8090/kontrol/kite"
)
