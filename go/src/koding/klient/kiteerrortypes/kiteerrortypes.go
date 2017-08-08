// A series of kite error type constants. Because the usage of the kite error
// types can be used anywhere, these types should never be changed.
// Incosistencies in formatting likely means that the type came from somewhere
// else. New types should adhere to camelcase.
//
// Leave existing cases as is!
//
package kiteerrortypes

const (
	// SubNotFound is used in klient/client.ErrSubNotFound
	SubNotFound = "SubNotFound"

	// Returned from a klient/command.Command when running the command fails in a
	// non-exit status way.
	ProcessError = "ProcessError"

	// Returned from klient/client/Publish when there are no listeners for the given
	// event.
	NoSubscribers = "NoSubscribers"
)
