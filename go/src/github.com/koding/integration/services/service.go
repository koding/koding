// services package is used for providing a Service interface. All the third
// party integrations need to implement this
package services

import (
	"fmt"
	"net/http"

	"github.com/koding/integration/helpers"
)

type Service interface {
	// ServeHTTP is default handler for incoming requests
	ServeHTTP(w http.ResponseWriter, req *http.Request)
	// Configure is used for sending webhook configuration requests
	// to services
	Configure(req *http.Request) (helpers.ConfigureResponse, error)
}

func prepareEndpoint(rootPath, service, token string) string {
	return fmt.Sprintf("%s/push/%s/%s", rootPath, service, token)
}
