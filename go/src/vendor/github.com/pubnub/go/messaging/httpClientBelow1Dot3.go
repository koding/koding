// +build !go1.3

package messaging

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"time"
)

func (pub *Pubnub) createNonSubHTTPClient() *http.Client {
	//TODO: Create a common implemetation to create transport for createNonSubHTTPClient and (w *requestWorker) Client()
	transport := &http.Transport{
		MaxIdleConnsPerHost: maxIdleConnsPerHost,
		Dial: (&net.Dialer{
			Timeout: time.Duration(connectTimeout) * time.Second,
			//KeepAlive: 30 * time.Minute,
		}).Dial,
		ResponseHeaderTimeout: time.Duration(nonSubscribeTimeout) * time.Second,
	}
	if proxyServerEnabled {
		proxyURL, err := url.Parse(fmt.Sprintf("http://%s:%s@%s:%d", proxyUser,
			proxyPassword, proxyServer, proxyPort))

		if err == nil {
			transport.Proxy = http.ProxyURL(proxyURL)
		} else {
			pub.infoLogger.Printf("ERROR: createNonSubHTTPClient: Proxy connection error: %s", err.Error())
		}
	}
	client := &http.Client{
		Transport: transport,
		//Timeout:   time.Duration(nonSubscribeTimeout) * time.Second,
	}
	return client
}
