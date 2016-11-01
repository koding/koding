package pem

// In order to use different certs, update {fullchain,privkey}.pem files
// and run go generate.
const Hostname = "dev.kodi.ng"

//go:generate go get github.com/jteeuwen/go-bindata
//go:generate go-bindata -mode 420 -modtime 1474360936 -pkg pem -o bindata.go fullchain.pem privkey.pem
