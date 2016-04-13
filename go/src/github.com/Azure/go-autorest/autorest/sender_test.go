package autorest

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
	"os"
	"reflect"
	"sync"
	"testing"
	"time"

	"github.com/Azure/go-autorest/autorest/mocks"
)

func ExampleSendWithSender() {
	r := mocks.NewResponseWithStatus("202 Accepted", http.StatusAccepted)
	mocks.SetAcceptedHeaders(r)

	client := mocks.NewSender()
	client.AppendAndRepeatResponse(r, 10)

	logger := log.New(os.Stdout, "autorest: ", 0)
	na := NullAuthorizer{}

	req, _ := Prepare(&http.Request{},
		AsGet(),
		WithBaseURL("https://microsoft.com/a/b/c/"),
		na.WithAuthorization())

	r, _ = SendWithSender(client, req,
		WithLogging(logger),
		DoErrorIfStatusCode(http.StatusAccepted),
		DoCloseIfError(),
		DoRetryForAttempts(5, time.Duration(0)))

	Respond(r,
		ByClosing())

	// Output:
	// autorest: Sending GET https://microsoft.com/a/b/c/
	// autorest: GET https://microsoft.com/a/b/c/ received 202 Accepted
	// autorest: Sending GET https://microsoft.com/a/b/c/
	// autorest: GET https://microsoft.com/a/b/c/ received 202 Accepted
	// autorest: Sending GET https://microsoft.com/a/b/c/
	// autorest: GET https://microsoft.com/a/b/c/ received 202 Accepted
	// autorest: Sending GET https://microsoft.com/a/b/c/
	// autorest: GET https://microsoft.com/a/b/c/ received 202 Accepted
	// autorest: Sending GET https://microsoft.com/a/b/c/
	// autorest: GET https://microsoft.com/a/b/c/ received 202 Accepted
}

func ExampleDoRetryForAttempts() {
	client := mocks.NewSender()
	client.SetAndRepeatError(fmt.Errorf("Faux Error"), 10)

	// Retry with backoff -- ensure returned Bodies are closed
	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoCloseIfError(),
		DoRetryForAttempts(5, time.Duration(0)))

	Respond(r,
		ByClosing())

	fmt.Printf("Retry stopped after %d attempts", client.Attempts())
	// Output: Retry stopped after 5 attempts
}

func ExampleDoErrorIfStatusCode() {
	client := mocks.NewSender()
	client.AppendAndRepeatResponse(mocks.NewResponseWithStatus("204 NoContent", http.StatusNoContent), 10)

	// Chain decorators to retry the request, up to five times, if the status code is 204
	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoErrorIfStatusCode(http.StatusNoContent),
		DoCloseIfError(),
		DoRetryForAttempts(5, time.Duration(0)))

	Respond(r,
		ByClosing())

	fmt.Printf("Retry stopped after %d attempts with code %s", client.Attempts(), r.Status)
	// Output: Retry stopped after 5 attempts with code 204 NoContent
}

func TestSendWithSenderRunsDecoratorsInOrder(t *testing.T) {
	client := mocks.NewSender()
	s := ""

	r, err := SendWithSender(client, mocks.NewRequest(),
		withMessage(&s, "a"),
		withMessage(&s, "b"),
		withMessage(&s, "c"))
	if err != nil {
		t.Errorf("autorest: SendWithSender returned an error (%v)", err)
	}

	Respond(r,
		ByClosing())

	if s != "abc" {
		t.Errorf("autorest: SendWithSender invoke decorators out of order; expected 'abc', received '%s'", s)
	}
}

func TestCreateSender(t *testing.T) {
	f := false

	s := CreateSender(
		(func() SendDecorator {
			return func(s Sender) Sender {
				return SenderFunc(func(r *http.Request) (*http.Response, error) {
					f = true
					return nil, nil
				})
			}
		})())
	s.Do(&http.Request{})

	if !f {
		t.Error("autorest: CreateSender failed to apply supplied decorator")
	}
}

func TestSend(t *testing.T) {
	f := false

	Send(&http.Request{},
		(func() SendDecorator {
			return func(s Sender) Sender {
				return SenderFunc(func(r *http.Request) (*http.Response, error) {
					f = true
					return nil, nil
				})
			}
		})())

	if !f {
		t.Error("autorest: Send failed to apply supplied decorator")
	}
}

func TestAfterDelayWaits(t *testing.T) {
	client := mocks.NewSender()

	d := 5 * time.Millisecond

	tt := time.Now()
	r, _ := SendWithSender(client, mocks.NewRequest(),
		AfterDelay(d))
	s := time.Since(tt)
	if s < d {
		t.Error("autorest: AfterDelay failed to wait for at least the specified duration")
	}

	Respond(r,
		ByClosing())
}

func TestAfterDelay_Cancels(t *testing.T) {
	client := mocks.NewSender()
	cancel := make(chan struct{})
	delay := 5 * time.Second

	var wg sync.WaitGroup
	wg.Add(1)
	tt := time.Now()
	go func() {
		req := mocks.NewRequest()
		req.Cancel = cancel
		wg.Done()
		SendWithSender(client, req,
			AfterDelay(delay))
	}()
	wg.Wait()
	close(cancel)
	time.Sleep(5 * time.Millisecond)
	if time.Since(tt) >= delay {
		t.Error("autorest: AfterDelay failed to cancel")
	}
}

func TestAfterDelayDoesNotWaitTooLong(t *testing.T) {
	client := mocks.NewSender()

	d := 5 * time.Millisecond
	start := time.Now()
	r, _ := SendWithSender(client, mocks.NewRequest(),
		AfterDelay(d))

	if time.Since(start) > (5 * d) {
		t.Error("autorest: AfterDelay waited too long (exceeded 5 times specified duration)")
	}

	Respond(r,
		ByClosing())
}

func TestAsIs(t *testing.T) {
	client := mocks.NewSender()

	r1 := mocks.NewResponse()
	client.AppendResponse(r1)

	r2, err := SendWithSender(client, mocks.NewRequest(),
		AsIs())
	if err != nil {
		t.Errorf("autorest: AsIs returned an unexpected error (%v)", err)
	} else if !reflect.DeepEqual(r1, r2) {
		t.Errorf("autorest: AsIs modified the response -- received %v, expected %v", r2, r1)
	}

	Respond(r1,
		ByClosing())
	Respond(r2,
		ByClosing())
}

func TestDoCloseIfError(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(mocks.NewResponseWithStatus("400 BadRequest", http.StatusBadRequest))

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoErrorIfStatusCode(http.StatusBadRequest),
		DoCloseIfError())

	if r.Body.(*mocks.Body).IsOpen() {
		t.Error("autorest: Expected DoCloseIfError to close response body -- it was left open")
	}

	Respond(r,
		ByClosing())
}

func TestDoCloseIfErrorAcceptsNilResponse(t *testing.T) {
	client := mocks.NewSender()

	SendWithSender(client, mocks.NewRequest(),
		(func() SendDecorator {
			return func(s Sender) Sender {
				return SenderFunc(func(r *http.Request) (*http.Response, error) {
					resp, err := s.Do(r)
					if err != nil {
						resp.Body.Close()
					}
					return nil, fmt.Errorf("Faux Error")
				})
			}
		})(),
		DoCloseIfError())
}

func TestDoCloseIfErrorAcceptsNilBody(t *testing.T) {
	client := mocks.NewSender()

	SendWithSender(client, mocks.NewRequest(),
		(func() SendDecorator {
			return func(s Sender) Sender {
				return SenderFunc(func(r *http.Request) (*http.Response, error) {
					resp, err := s.Do(r)
					if err != nil {
						resp.Body.Close()
					}
					resp.Body = nil
					return resp, fmt.Errorf("Faux Error")
				})
			}
		})(),
		DoCloseIfError())
}

func TestDoErrorIfStatusCode(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(mocks.NewResponseWithStatus("400 BadRequest", http.StatusBadRequest))

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoErrorIfStatusCode(http.StatusBadRequest),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: DoErrorIfStatusCode failed to emit an error for passed code")
	}

	Respond(r,
		ByClosing())
}

func TestDoErrorIfStatusCodeIgnoresStatusCodes(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(newAcceptedResponse())

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoErrorIfStatusCode(http.StatusBadRequest),
		DoCloseIfError())
	if err != nil {
		t.Error("autorest: DoErrorIfStatusCode failed to ignore a status code")
	}

	Respond(r,
		ByClosing())
}

func TestDoErrorUnlessStatusCode(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(mocks.NewResponseWithStatus("400 BadRequest", http.StatusBadRequest))

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoErrorUnlessStatusCode(http.StatusAccepted),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: DoErrorUnlessStatusCode failed to emit an error for an unknown status code")
	}

	Respond(r,
		ByClosing())
}

func TestDoErrorUnlessStatusCodeIgnoresStatusCodes(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(newAcceptedResponse())

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoErrorUnlessStatusCode(http.StatusAccepted),
		DoCloseIfError())
	if err != nil {
		t.Error("autorest: DoErrorUnlessStatusCode emitted an error for a knonwn status code")
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForAttemptsStopsAfterSuccess(t *testing.T) {
	client := mocks.NewSender()

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForAttempts(5, time.Duration(0)))
	if client.Attempts() != 1 {
		t.Errorf("autorest: DoRetryForAttempts failed to stop after success -- expected attempts %v, actual %v",
			1, client.Attempts())
	}
	if err != nil {
		t.Errorf("autorest: DoRetryForAttempts returned an unexpected error (%v)", err)
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForAttemptsStopsAfterAttempts(t *testing.T) {
	client := mocks.NewSender()
	client.SetAndRepeatError(fmt.Errorf("Faux Error"), 10)

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForAttempts(5, time.Duration(0)),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: Mock client failed to emit errors")
	}

	Respond(r,
		ByClosing())

	if client.Attempts() != 5 {
		t.Error("autorest: DoRetryForAttempts failed to stop after specified number of attempts")
	}
}

func TestDoRetryForAttemptsReturnsResponse(t *testing.T) {
	client := mocks.NewSender()
	client.SetError(fmt.Errorf("Faux Error"))

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForAttempts(1, time.Duration(0)))
	if err == nil {
		t.Error("autorest: Mock client failed to emit errors")
	}

	if r == nil {
		t.Error("autorest: DoRetryForAttempts failed to return the underlying response")
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForDurationStopsAfterSuccess(t *testing.T) {
	client := mocks.NewSender()

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForDuration(10*time.Millisecond, time.Duration(0)))
	if client.Attempts() != 1 {
		t.Errorf("autorest: DoRetryForDuration failed to stop after success -- expected attempts %v, actual %v",
			1, client.Attempts())
	}
	if err != nil {
		t.Errorf("autorest: DoRetryForDuration returned an unexpected error (%v)", err)
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForDurationStopsAfterDuration(t *testing.T) {
	client := mocks.NewSender()
	client.SetAndRepeatError(fmt.Errorf("Faux Error"), -1)

	d := 5 * time.Millisecond
	start := time.Now()
	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForDuration(d, time.Duration(0)),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: Mock client failed to emit errors")
	}

	if time.Since(start) < d {
		t.Error("autorest: DoRetryForDuration failed stopped too soon")
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForDurationStopsWithinReason(t *testing.T) {
	client := mocks.NewSender()
	client.SetAndRepeatError(fmt.Errorf("Faux Error"), -1)

	d := 5 * time.Millisecond
	start := time.Now()
	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForDuration(d, time.Duration(0)),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: Mock client failed to emit errors")
	}

	if time.Since(start) > (5 * d) {
		t.Error("autorest: DoRetryForDuration failed stopped soon enough (exceeded 5 times specified duration)")
	}

	Respond(r,
		ByClosing())
}

func TestDoRetryForDurationReturnsResponse(t *testing.T) {
	client := mocks.NewSender()
	client.SetAndRepeatError(fmt.Errorf("Faux Error"), -1)

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoRetryForDuration(10*time.Millisecond, time.Duration(0)),
		DoCloseIfError())
	if err == nil {
		t.Error("autorest: Mock client failed to emit errors")
	}

	if r == nil {
		t.Error("autorest: DoRetryForDuration failed to return the underlying response")
	}

	Respond(r,
		ByClosing())
}

func TestDelayForBackoff(t *testing.T) {
	d := 5 * time.Millisecond
	start := time.Now()
	DelayForBackoff(d, 1, nil)
	if time.Since(start) < d {
		t.Error("autorest: DelayForBackoff did not delay as long as expected")
	}
}

func TestDelayForBackoff_Cancels(t *testing.T) {
	cancel := make(chan struct{})
	delay := 5 * time.Second

	var wg sync.WaitGroup
	wg.Add(1)
	start := time.Now()
	go func() {
		wg.Done()
		DelayForBackoff(delay, 1, cancel)
	}()
	wg.Wait()
	close(cancel)
	time.Sleep(5 * time.Millisecond)
	if time.Since(start) >= delay {
		t.Error("autorest: DelayForBackoff failed to cancel")
	}
}

func TestDelayForBackoffWithinReason(t *testing.T) {
	d := 5 * time.Millisecond
	start := time.Now()
	DelayForBackoff(d, 1, nil)
	if time.Since(start) > (5 * d) {
		t.Error("autorest: DelayForBackoff delayed too long (exceeded 5 times the specified duration)")
	}
}

func TestDoPollForStatusCodes_IgnoresUnspecifiedStatusCodes(t *testing.T) {
	client := mocks.NewSender()

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Duration(0), time.Duration(0)))

	if client.Attempts() != 1 {
		t.Errorf("autorest: Sender#DoPollForStatusCodes polled for unspecified status code")
	}

	Respond(r,
		ByClosing())
}

func TestDoPollForStatusCodes_PollsForSpecifiedStatusCodes(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(newAcceptedResponse())

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))

	if client.Attempts() != 2 {
		t.Errorf("autorest: Sender#DoPollForStatusCodes failed to poll for specified status code")
	}

	Respond(r,
		ByClosing())
}

func TestDoPollForStatusCodes_CanBeCanceled(t *testing.T) {
	cancel := make(chan struct{})
	delay := 5 * time.Second

	r := mocks.NewResponse()
	mocks.SetAcceptedHeaders(r)
	client := mocks.NewSender()
	client.AppendAndRepeatResponse(r, 100)

	var wg sync.WaitGroup
	wg.Add(1)
	start := time.Now()
	go func() {
		wg.Done()
		r, _ := SendWithSender(client, mocks.NewRequest(),
			DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))
		Respond(r,
			ByClosing())
	}()
	wg.Wait()
	close(cancel)
	time.Sleep(5 * time.Millisecond)
	if time.Since(start) >= delay {
		t.Errorf("autorest: Sender#DoPollForStatusCodes failed to cancel")
	}
}

func TestDoPollForStatusCodes_ClosesAllNonreturnedResponseBodiesWhenPolling(t *testing.T) {
	resp := newAcceptedResponse()

	client := mocks.NewSender()
	client.AppendAndRepeatResponse(resp, 2)

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))

	if resp.Body.(*mocks.Body).IsOpen() || resp.Body.(*mocks.Body).CloseAttempts() < 2 {
		t.Errorf("autorest: Sender#DoPollForStatusCodes did not close unreturned response bodies")
	}

	Respond(r,
		ByClosing())
}

func TestDoPollForStatusCodes_LeavesLastResponseBodyOpen(t *testing.T) {
	client := mocks.NewSender()
	client.AppendResponse(newAcceptedResponse())

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))

	if !r.Body.(*mocks.Body).IsOpen() {
		t.Errorf("autorest: Sender#DoPollForStatusCodes did not leave open the body of the last response")
	}

	Respond(r,
		ByClosing())
}

func TestDoPollForStatusCodes_StopsPollingAfterAnError(t *testing.T) {
	client := mocks.NewSender()
	client.AppendAndRepeatResponse(newAcceptedResponse(), 5)
	client.SetError(fmt.Errorf("Faux Error"))
	client.SetEmitErrorAfter(1)

	r, _ := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))

	if client.Attempts() > 2 {
		t.Errorf("autorest: Sender#DoPollForStatusCodes failed to stop polling after receiving an error")
	}

	Respond(r,
		ByClosing())
}

func TestDoPollForStatusCodes_ReturnsPollingError(t *testing.T) {
	client := mocks.NewSender()
	client.AppendAndRepeatResponse(newAcceptedResponse(), 5)
	client.SetError(fmt.Errorf("Faux Error"))
	client.SetEmitErrorAfter(1)

	r, err := SendWithSender(client, mocks.NewRequest(),
		DoPollForStatusCodes(time.Millisecond, time.Millisecond, http.StatusAccepted))

	if err == nil {
		t.Errorf("autorest: Sender#DoPollForStatusCodes failed to return error from polling")
	}

	Respond(r,
		ByClosing())
}

func TestWithLogging_Logs(t *testing.T) {
	buf := &bytes.Buffer{}
	logger := log.New(buf, "autorest: ", 0)
	client := mocks.NewSender()

	r, _ := SendWithSender(client, &http.Request{},
		WithLogging(logger))

	if buf.String() == "" {
		t.Error("autorest: Sender#WithLogging failed to log the request")
	}

	Respond(r,
		ByClosing())
}

func TestWithLogging_HandlesMissingResponse(t *testing.T) {
	buf := &bytes.Buffer{}
	logger := log.New(buf, "autorest: ", 0)
	client := mocks.NewSender()
	client.AppendResponse(nil)
	client.SetError(fmt.Errorf("Faux Error"))

	r, err := SendWithSender(client, &http.Request{},
		WithLogging(logger))

	if r != nil || err == nil {
		t.Error("autorest: Sender#WithLogging returned a valid response -- expecting nil")
	}
	if buf.String() == "" {
		t.Error("autorest: Sender#WithLogging failed to log the request for a nil response")
	}

	Respond(r,
		ByClosing())
}

func newAcceptedResponse() *http.Response {
	resp := mocks.NewResponseWithStatus("202 Accepted", http.StatusAccepted)
	mocks.SetAcceptedHeaders(resp)
	return resp
}
