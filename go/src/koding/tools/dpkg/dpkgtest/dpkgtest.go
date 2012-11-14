package main

import (
	"koding/tools/dpkg"
)

func main() {
	packages := dpkg.ReadStatusDB("/var/lib/dpkg/status")
	dpkg.WriteStatusDB(packages, "out")
}
