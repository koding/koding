package client_test

//TODO: need a fake Golang HTTPClient to implement this test.

//Public methods
// DoRawHttpRequestWithObjectMask
// DoRawHttpRequestWithObjectFilter
// DoRawHttpRequestWithObjectFilterAndObjectMask
// DoRawHttpRequest
// GenerateRequestBody
// HasErrors
// CheckForHttpResponseErrors

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"strconv"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"

	slclient "github.com/maximilien/softlayer-go/client"
)

var _ = Describe("A HTTP Client", func() {
	var (
		server               *ghttp.Server
		client               *slclient.HttpClient
		err                  error
		slUsername, slAPIKey string
		port                 = 9999
	)

	Context("when the target HTTP server is stable", func() {
		BeforeEach(func() {
			server = ghttp.NewServer()
			fmt.Fprintf(os.Stdout, "server addr is: "+server.Addr())
			slUsername = os.Getenv("SL_USERNAME")
			slAPIKey = os.Getenv("SL_API_KEY")
			client = slclient.NewHttpClient(slUsername, slAPIKey, server.Addr(), "templates", false)
		})

		AfterEach(func() {
			server.Close()
		})

		Context("#DoRawHttpRequest", func() {
			Context("when a successful request", func() {
				BeforeEach(func() {
					server.CloseClientConnections()
					server.AppendHandlers(
						ghttp.VerifyRequest("GET", "/test"),
						ghttp.VerifyBasicAuth(slUsername, slAPIKey),
					)
				})

				It("make a request to access /test", func() {
					client.DoRawHttpRequest("test", "GET", bytes.NewBufferString("random text"))
					Ω(err).ShouldNot(HaveOccurred())
					Ω(server.ReceivedRequests()).Should(HaveLen(1))
				})
			})
		})
	})

	Context("when the target HTTP server is not stable", func() {
		BeforeEach(func() {
			os.Setenv("SL_API_RETRY_COUNT", "10")
			os.Setenv("SL_API_WAIT_TIME", "1")
			server.AllowUnhandledRequests = true
			client = slclient.NewHttpClient(slUsername, slAPIKey, "127.0.0.1:"+strconv.Itoa(port), "templates", false)
			client.HTTPClient.Transport = &http.Transport{
				DialContext: dialContextTimeout,
			}
		})

		It("send a request to an instable HTTP server", func() {
			go delayStartHTTPServer(4, port)
			_, _, err := client.DoRawHttpRequest("timeoutTest", "GET", bytes.NewBufferString("test"))
			Expect(err).ToNot(HaveOccurred())
		})
	})
})

// private functions
func dialContextTimeout(ctx context.Context, network, addr string) (net.Conn, error) {
	return net.DialTimeout(network, addr, time.Duration(1*time.Second))
}

func delayStartHTTPServer(waitTime int, port int) error {
	time.Sleep(time.Duration(waitTime) * time.Second)
	http.HandleFunc("/", handler)
	err := http.ListenAndServe(":"+strconv.Itoa(port), nil)
	if err != nil {
		return err
	}
	return nil
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%s", r.URL.Path[1:])
}
