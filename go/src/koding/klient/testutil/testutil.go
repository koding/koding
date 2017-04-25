package testutil

import (
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"net"
	"net/url"
	"os"
	"strconv"
	"time"

	"koding/klient/registrar"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

var DiscardLogger logging.Logger

func init() {
	DiscardLogger = logging.NewLogger("DiscardLogger")
	DiscardLogger.SetHandler(logging.NewWriterHandler(ioutil.Discard))
}

func init() {
	rand.Seed(time.Now().UnixNano() + int64(os.Getpid()))
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

// FileCopy copies file from dst to src, overwriting src if it exists.
//
// Upon successful calls fsync on the file.
func FileCopy(src, dst string) error {
	fsrc, err := os.Open(src)
	if err != nil {
		return err
	}
	defer fsrc.Close()

	fi, err := fsrc.Stat()
	if err != nil {
		return err
	}

	fdst, err := os.OpenFile(dst, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, fi.Mode())
	if err != nil {
		return err
	}

	_, err = io.Copy(fdst, fsrc)
	return nonil(err, fdst.Sync(), fdst.Close())
}

// URL is a wrapper for url.URL which guarantees that embedded
// (*net.URL).Host is always in host:port format.
type URL struct {
	*url.URL
}

// Port gives port part of the (*net.URL).Host.
func (u URL) Port() int {
	_, port, err := net.SplitHostPort(u.URL.Host)
	if err != nil {
		panic(err)
	}
	n, err := strconv.Atoi(port)
	if err != nil {
		panic(err)
	}
	return n
}

// Host gives host part of the (*net.URL).Host.
func (u URL) Host() string {
	host, _, err := net.SplitHostPort(u.URL.Host)
	if err != nil {
		panic(err)
	}
	return host
}

// GenKiteURL tries to generate random kite URL. Tries, because there's
// no guarantee the generated port is available to listen on.
func GenKiteURL() URL {
	// Generate random port in 500000 - 59999 range.
	port := int(50000 + rand.Int31n(10000))
	return URL{
		URL: &url.URL{
			Scheme: "http",
			Host:   "127.0.0.1:" + strconv.Itoa(port),
			Path:   "/kite",
		},
	}
}

// GetKites creates a test pair of kites with the provided method/handler
// mapping. This method will create a kite server that is running on a
// currently free port, and sets up the corresponding kite client that is
// configured to talk to said kite server.
func GetKites(m map[string]kite.HandlerFunc) (*kite.Kite, *kite.Client) {
    k := kite.New("proxy_test", "0.0.1")

    for name, handler := range m {
        k.HandleFunc(name, handler).DisableAuthentication()
        registrar.Register(name)
    }

    go k.Run()
    <-k.ServerReadyNotify()

    url := fmt.Sprintf("http://localhost:%d/kite", k.Port())
    client := k.NewClient(url)
	client.Dial()

    return k, client
}
