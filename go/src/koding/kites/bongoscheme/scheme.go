package bongoscheme

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

const (
	Instance = "instance"
	Static   = "static"
)

var (
	ModelNotSet  = errors.New("model name is not set")
	TypeNotSet   = errors.New("function type is not set")
	TypeNotValid = errors.New("function type is not valid")
	NameNotSet   = errors.New("function name is not set")
	IdNotSet     = errors.New("id is not set for instance method")
)

type BongoKite struct {
	bongo  *kite.Client
	config *Config
}

type Config struct {
	ClientURL string
	Version   string
}

func New(c *Config) (*BongoKite, error) {
	// Create a kite
	k := kite.New("bongo", c.Version)

	// Create bongo client
	bongo := k.NewClient(c.ClientURL)

	// Connect to bongo kite
	connected, err := bongo.DialForever()
	if err != nil {
		return nil, err
	}

	// Wait until connected
	<-connected

	return &BongoKite{
		bongo:  bongo,
		config: c,
	}, nil
}

type bongoScheme struct {
	bk        *BongoKite
	ModelName string `json:"constructorName"`
	FuncType  string `json:"type"`
	FuncName  string `json:"method"`
	// field for instance methods
	Id        string        `json:"id,omitempty"`
	Arguments []interface{} `json:"arguments"`
}

func (b *BongoKite) Model(name string) *bongoScheme {
	return &bongoScheme{bk: b, ModelName: name}
}

func (b *bongoScheme) Static() *bongoScheme {
	b.FuncType = Static
	return b
}

func (b *bongoScheme) Instance(id string) *bongoScheme {
	b.FuncType = Instance
	b.Id = id
	return b
}

func (b *bongoScheme) Model(m string) *bongoScheme {
	b.ModelName = m
	return b
}

func (b *bongoScheme) Type(t string) *bongoScheme {
	b.FuncType = t
	return b
}

func (b *bongoScheme) Func(n string) *bongoScheme {
	b.FuncName = n
	return b
}

func (b *bongoScheme) CallWith(args ...interface{}) (*dnode.Partial, error) {
	b.Arguments = args
	return b.call()
}

func (b *bongoScheme) Call() (*dnode.Partial, error) {
	b.Arguments = []interface{}{}
	return b.call()
}

func (b *bongoScheme) call() (*dnode.Partial, error) {
	if err := b.validate(); err != nil {
		return nil, err
	}

	return b.bk.bongo.TellWithTimeout(
		"bongo",
		4*time.Second,
		b,
	)
}

func (b *bongoScheme) validate() error {
	if b.ModelName == "" {
		return ModelNotSet
	}

	if b.FuncType == "" {
		return TypeNotSet
	}

	if b.ModelName == "" {
		return NameNotSet
	}

	if b.FuncType != Static && b.FuncType != Instance {
		return TypeNotValid
	}

	if b.FuncType == Instance {
		if b.Id == "" {
			return IdNotSet
		}
	}

	return nil
}
