package stackcred

import (
	"fmt"

	"koding/db/mongodb"
	"koding/kites/kloud/utils/object"

	"github.com/koding/logging"
)

// NotFoundError represents an error fetching credentials.
//
// Identfiers of credentials that are missing in the underlying
// storage are listed in the Identifiers field.
type NotFoundError struct {
	Identifiers []string
	Err         error
}

// Error implements the built-in error interface.
func (e *NotFoundError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%v credentials not found due to the error: %s", e.Identifiers, e.Err)
	}

	return fmt.Sprintf("%v credentials not found", e.Identifiers)
}

// Fetcher provides an interface for fetching credentials.
type Fetcher interface {
	// Fetch obtains credentials from the underlying store for the given
	// username and credential identifiers.
	//
	// The creds parameters maps identifier string to a credential
	// data value.
	//
	// If the data value is non-nil, the method will decode fetched
	// credential data from the underlying representation (e.g. bson.M
	// for MongoDB credentials store) to the given value. The behaviour
	// for the decoding can be altered by providing custom ObjectBuilder
	// via StoreOptions param. By default object.HCLBuilder decoding
	// is used. If the data value implements kloud.Validator interface,
	// it will be used to ensure decoding was successful.
	//
	// If the data value is nil, the fetcher will use store-specific
	// representation. This is used to defer decoding of the data
	// value, leaving it to the caller.
	Fetch(username string, creds map[string]interface{}) error
}

// StoreOptions are used to alter default behavior of credential store
// implementations.
type StoreOptions struct {
	MongoDB            *mongodb.MongoDB
	Log                logging.Logger
	CredentialEndpoint string
	ObjectBuilder      *object.Builder
}

func (opts *StoreOptions) objectBuilder() *object.Builder {
	if opts.ObjectBuilder != nil {
		return opts.ObjectBuilder
	}

	return object.HCLBuilder
}

// NewStore gives new credential store for the given options.
func NewStore(opts *StoreOptions) Fetcher {
	return &mongoStore{
		StoreOptions: opts,
	}
}

func toIdents(creds map[string]interface{}) []string {
	idents := make([]string, 0, len(creds))
	for ident := range creds {
		idents = append(idents, ident)
	}

	return idents
}
