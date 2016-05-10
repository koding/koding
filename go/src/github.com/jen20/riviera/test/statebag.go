package test

import (
	"sync"

	"github.com/hashicorp/go-multierror"
	"github.com/jen20/riviera/azure"
)

type AzureStateBag interface {
	Get(string) interface{}
	GetOk(string) (interface{}, bool)
	Put(string, interface{})
	Remove(string)

	Client() *azure.Client

	AppendError(error)
	ErrorsOrNil() error
}

// AzureStateBag implements StateBag by using a normal map underneath
// protected by a RWMutex.
type basicAzureStateBag struct {
	AzureClient *azure.Client

	errors *multierror.Error
	data   map[string]interface{}

	l    sync.RWMutex
	once sync.Once
}

func (b *basicAzureStateBag) Client() *azure.Client {
	b.l.RLock()
	defer b.l.RUnlock()

	return b.AzureClient
}

func (b *basicAzureStateBag) AppendError(err error) {
	b.l.Lock()
	defer b.l.Unlock()

	b.errors = multierror.Append(b.errors, err)
}

func (b *basicAzureStateBag) ErrorsOrNil() error {
	b.l.RLock()
	defer b.l.RUnlock()

	if b.errors == nil {
		return nil
	}

	return b.errors.ErrorOrNil()
}

func (b *basicAzureStateBag) Get(k string) interface{} {
	result, _ := b.GetOk(k)
	return result
}

func (b *basicAzureStateBag) GetOk(k string) (interface{}, bool) {
	b.l.RLock()
	defer b.l.RUnlock()

	result, ok := b.data[k]
	return result, ok
}

func (b *basicAzureStateBag) Put(k string, v interface{}) {
	b.l.Lock()
	defer b.l.Unlock()

	// Make sure the map is initialized one time, on write
	b.once.Do(func() {
		b.data = make(map[string]interface{})
	})

	// Write the data
	b.data[k] = v
}

func (b *basicAzureStateBag) Remove(k string) {
	b.l.Lock()
	defer b.l.Unlock()

	delete(b.data, k)
}
