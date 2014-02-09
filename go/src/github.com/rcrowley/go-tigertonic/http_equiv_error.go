package tigertonic

import "net/http"

// SnakeCaseHTTPEquivErrors being true will cause tigertonic.HTTPEquivError
// error responses to be written as (for example) "not_found" rather than
// "tigertonic.NotFound".
var SnakeCaseHTTPEquivErrors bool

// Err is an alias for the built-in error type so that it can be publicly
// exported when embedding.
type Err error

type HTTPEquivError interface {
	error
	StatusCode() int
}

type Continue struct {
	Err
}

func (err Continue) Name() string { return errorName(err.Err, "") }

func (err Continue) StatusCode() int { return http.StatusContinue }

type SwitchingProtocols struct {
	Err
}

func (err SwitchingProtocols) Name() string { return errorName(err.Err, "") }

func (err SwitchingProtocols) StatusCode() int { return http.StatusSwitchingProtocols }

type OK struct {
	Err
}

func (err OK) Name() string { return errorName(err.Err, "") }

func (err OK) StatusCode() int { return http.StatusOK }

type Created struct {
	Err
}

func (err Created) Name() string { return errorName(err.Err, "") }

func (err Created) StatusCode() int { return http.StatusCreated }

type Accepted struct {
	Err
}

func (err Accepted) Name() string { return errorName(err.Err, "") }

func (err Accepted) StatusCode() int { return http.StatusAccepted }

type NonAuthoritativeInfo struct {
	Err
}

func (err NonAuthoritativeInfo) Name() string { return errorName(err.Err, "") }

func (err NonAuthoritativeInfo) StatusCode() int { return http.StatusNonAuthoritativeInfo }

type NoContent struct {
	Err
}

func (err NoContent) Name() string { return errorName(err.Err, "") }

func (err NoContent) StatusCode() int { return http.StatusNoContent }

type ResetContent struct {
	Err
}

func (err ResetContent) Name() string { return errorName(err.Err, "") }

func (err ResetContent) StatusCode() int { return http.StatusResetContent }

type PartialContent struct {
	Err
}

func (err PartialContent) Name() string { return errorName(err.Err, "") }

func (err PartialContent) StatusCode() int { return http.StatusPartialContent }

type MultipleChoices struct {
	Err
}

func (err MultipleChoices) Name() string { return errorName(err.Err, "") }

func (err MultipleChoices) StatusCode() int { return http.StatusMultipleChoices }

type MovedPermanently struct {
	Err
}

func (err MovedPermanently) Name() string { return errorName(err.Err, "") }

func (err MovedPermanently) StatusCode() int { return http.StatusMovedPermanently }

type Found struct {
	Err
}

func (err Found) Name() string { return errorName(err.Err, "") }

func (err Found) StatusCode() int { return http.StatusFound }

type SeeOther struct {
	Err
}

func (err SeeOther) Name() string { return errorName(err.Err, "") }

func (err SeeOther) StatusCode() int { return http.StatusSeeOther }

type NotModified struct {
	Err
}

func (err NotModified) Name() string { return errorName(err.Err, "") }

func (err NotModified) StatusCode() int { return http.StatusNotModified }

type UseProxy struct {
	Err
}

func (err UseProxy) Name() string { return errorName(err.Err, "") }

func (err UseProxy) StatusCode() int { return http.StatusUseProxy }

type TemporaryRedirect struct {
	Err
}

func (err TemporaryRedirect) Name() string { return errorName(err.Err, "") }

func (err TemporaryRedirect) StatusCode() int { return http.StatusTemporaryRedirect }

type BadRequest struct {
	Err
}

func (err BadRequest) Name() string { return errorName(err.Err, "") }

func (err BadRequest) StatusCode() int { return http.StatusBadRequest }

type Unauthorized struct {
	Err
}

func (err Unauthorized) Name() string { return errorName(err.Err, "") }

func (err Unauthorized) StatusCode() int { return http.StatusUnauthorized }

type PaymentRequired struct {
	Err
}

func (err PaymentRequired) Name() string { return errorName(err.Err, "") }

func (err PaymentRequired) StatusCode() int { return http.StatusPaymentRequired }

type Forbidden struct {
	Err
}

func (err Forbidden) Name() string { return errorName(err.Err, "") }

func (err Forbidden) StatusCode() int { return http.StatusForbidden }

type NotFound struct {
	Err
}

func (err NotFound) Name() string { return errorName(err.Err, "") }

func (err NotFound) StatusCode() int { return http.StatusNotFound }

type MethodNotAllowed struct {
	Err
}

func (err MethodNotAllowed) Name() string { return errorName(err.Err, "") }

func (err MethodNotAllowed) StatusCode() int { return http.StatusMethodNotAllowed }

type NotAcceptable struct {
	Err
}

func (err NotAcceptable) Name() string { return errorName(err.Err, "") }

func (err NotAcceptable) StatusCode() int { return http.StatusNotAcceptable }

type ProxyAuthRequired struct {
	Err
}

func (err ProxyAuthRequired) Name() string { return errorName(err.Err, "") }

func (err ProxyAuthRequired) StatusCode() int { return http.StatusProxyAuthRequired }

type RequestTimeout struct {
	Err
}

func (err RequestTimeout) Name() string { return errorName(err.Err, "") }

func (err RequestTimeout) StatusCode() int { return http.StatusRequestTimeout }

type Conflict struct {
	Err
}

func (err Conflict) Name() string { return errorName(err.Err, "") }

func (err Conflict) StatusCode() int { return http.StatusConflict }

type Gone struct {
	Err
}

func (err Gone) Name() string { return errorName(err.Err, "") }

func (err Gone) StatusCode() int { return http.StatusGone }

type LengthRequired struct {
	Err
}

func (err LengthRequired) Name() string { return errorName(err.Err, "") }

func (err LengthRequired) StatusCode() int { return http.StatusLengthRequired }

type PreconditionFailed struct {
	Err
}

func (err PreconditionFailed) Name() string { return errorName(err.Err, "") }

func (err PreconditionFailed) StatusCode() int { return http.StatusPreconditionFailed }

type RequestEntityTooLarge struct {
	Err
}

func (err RequestEntityTooLarge) Name() string { return errorName(err.Err, "") }

func (err RequestEntityTooLarge) StatusCode() int { return http.StatusRequestEntityTooLarge }

type RequestURITooLong struct {
	Err
}

func (err RequestURITooLong) Name() string { return errorName(err.Err, "") }

func (err RequestURITooLong) StatusCode() int { return http.StatusRequestURITooLong }

type UnsupportedMediaType struct {
	Err
}

func (err UnsupportedMediaType) Name() string { return errorName(err.Err, "") }

func (err UnsupportedMediaType) StatusCode() int { return http.StatusUnsupportedMediaType }

type RequestedRangeNotSatisfiable struct {
	Err
}

func (err RequestedRangeNotSatisfiable) Name() string { return errorName(err.Err, "") }

func (err RequestedRangeNotSatisfiable) StatusCode() int {
	return http.StatusRequestedRangeNotSatisfiable
}

type ExpectationFailed struct {
	Err
}

func (err ExpectationFailed) Name() string { return errorName(err.Err, "") }

func (err ExpectationFailed) StatusCode() int { return http.StatusExpectationFailed }

type Teapot struct {
	Err
}

func (err Teapot) Name() string { return errorName(err.Err, "") }

func (err Teapot) StatusCode() int { return http.StatusTeapot }

type InternalServerError struct {
	Err
}

func (err InternalServerError) Name() string { return errorName(err.Err, "") }

func (err InternalServerError) StatusCode() int { return http.StatusInternalServerError }

type NotImplemented struct {
	Err
}

func (err NotImplemented) Name() string { return errorName(err.Err, "") }

func (err NotImplemented) StatusCode() int { return http.StatusNotImplemented }

type BadGateway struct {
	Err
}

func (err BadGateway) Name() string { return errorName(err.Err, "") }

func (err BadGateway) StatusCode() int { return http.StatusBadGateway }

type ServiceUnavailable struct {
	Err
}

func (err ServiceUnavailable) Name() string { return errorName(err.Err, "") }

func (err ServiceUnavailable) StatusCode() int { return http.StatusServiceUnavailable }

type GatewayTimeout struct {
	Err
}

func (err GatewayTimeout) Name() string { return errorName(err.Err, "") }

func (err GatewayTimeout) StatusCode() int { return http.StatusGatewayTimeout }

type HTTPVersionNotSupported struct {
	Err
}

func (err HTTPVersionNotSupported) Name() string { return errorName(err.Err, "") }

func (err HTTPVersionNotSupported) StatusCode() int { return http.StatusHTTPVersionNotSupported }

type httpEquivError struct {
	Err
	code int
}

// Return a new HTTPEquivError whose StatusCode method returns the given
// status code.
func NewHTTPEquivError(err error, code int) error {
	return httpEquivError{err, code}
}

// Name implements the NamedError interface so that the underlying error's type
// is communicated to the caller.
func (err httpEquivError) Name() string {
	return errorName(err.Err, "")
}

func (err httpEquivError) StatusCode() int {
	if http.StatusContinue > err.code {
		return http.StatusInternalServerError
	}
	return err.code
}
