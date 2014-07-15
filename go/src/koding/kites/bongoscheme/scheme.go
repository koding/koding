// bongosheme is a wrapper for bongo inter-service communication
package bongoscheme

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/kite/protocol"
)

const (
	// represents instance functions
	Instance = "instance"
	// represents static functions
	Static = "static"
)

var (
	ErrKiteIsNil           = errors.New("kite is nil")
	ErrBongoNotInitialized = errors.New("bongo client is not initialized")
	ErrModelNotSet         = errors.New("model name is not set")
	ErrTypeNotSet          = errors.New("function type is not set")
	ErrTypeNotValid        = errors.New("function type is not valid")
	ErrNameNotSet          = errors.New("function name is not set")
	ErrIdNotSet            = errors.New("id is not set for instance method")
)

// Bongo kite is a wrapper for kite client of bongo
type BongoKite struct {
	bongo *kite.Client
}

// New connects to bongo kite client and wraps it, this function will wait until
// bongo client kite is connected to the system if error occures while trying to
// initialize, returns as early as possible
func New(k *kite.Kite, query *protocol.KontrolQuery) (*BongoKite, error) {
	kite, err := getOneBongoKiteClient(k, query)
	if err != nil {
		return nil, err
	}

	return &BongoKite{
		bongo: kite,
	}, nil
}

func getOneBongoKiteClient(k *kite.Kite, query *protocol.KontrolQuery) (*kite.Client, error) {
	if k == nil {
		return nil, ErrKiteIsNil
	}

	kites, err := k.GetKites(*query)
	if err != nil {
		return nil, err
	}

	kite := kites[0]

	// Connect to bongo kite
	connected, err := kite.DialForever()
	if err != nil {
		return nil, err
	}

	// Wait until connected
	<-connected

	return kite, nil
}

// bongoScheme holds fields for bongo communication
type bongoScheme struct {
	bk        *BongoKite
	ModelName string        `json:"constructorName"`
	FuncType  string        `json:"type"`
	FuncName  string        `json:"method"`
	Arguments []interface{} `json:"arguments"`

	// field for instance methods
	Id string `json:"id,omitempty"`
}

func (b *BongoKite) Close() {
	if b.bongo != nil {
		b.bongo.Close()
	}
}

// Model sets the model name
func (b *BongoKite) Model(name string) *bongoScheme {
	return &bongoScheme{bk: b, ModelName: name}
}

// Static sets this call as a static function call
func (b *bongoScheme) Static() *bongoScheme {
	b.FuncType = Static
	return b
}

// Instance sets scheme's funcType to `instance` and sets the id
func (b *bongoScheme) Instance(id string) *bongoScheme {
	b.FuncType = Instance
	b.Id = id
	return b
}

// Func sets the function name
func (b *bongoScheme) Func(n string) *bongoScheme {
	b.FuncName = n
	return b
}

// CallWith accepts multiple parameters for calling the given scheme
func (b *bongoScheme) CallWith(args ...interface{}) (*dnode.Partial, error) {
	b.Arguments = args
	return b.call()
}

// Call calls the given scheme with empty interface parameter
func (b *bongoScheme) Call() (*dnode.Partial, error) {
	b.Arguments = []interface{}{}
	return b.call()
}

// call validates the request first, then sends request to bongo with a 30
// second timeout
func (b *bongoScheme) call() (*dnode.Partial, error) {
	if err := b.validate(); err != nil {
		return nil, err
	}

	return b.bk.bongo.TellWithTimeout(
		"bongo",
		30*time.Second,
		b,
	)
}

// validate checks the given scheme against consistency
func (b *bongoScheme) validate() error {
	if b.bk == nil || b.bk.bongo == nil {
		return ErrBongoNotInitialized
	}

	if b.ModelName == "" {
		return ErrModelNotSet
	}

	if b.FuncType == "" {
		return ErrTypeNotSet
	}

	if b.ModelName == "" {
		return ErrNameNotSet
	}

	if b.FuncType != Static && b.FuncType != Instance {
		return ErrTypeNotValid
	}

	if b.FuncType == Instance {
		if b.Id == "" {
			return ErrIdNotSet
		}
	}

	return nil
}
