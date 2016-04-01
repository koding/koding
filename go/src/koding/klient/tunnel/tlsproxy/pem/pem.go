package pem

// In order to use different certs, update {fullchain,privkey}.pem files
// and run go generate.
const Hostname = "dev.kodi.ng"

//go:generate go get github.com/jteeuwen/go-bindata
//go:generate go-bindata -pkg pem fullchain.pem privkey.pem
