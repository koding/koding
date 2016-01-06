package collaboration

import "sync"

func NewMemoryStorage() *memoryStorage {
	return &memoryStorage{
		users: make(map[string]*Option),
	}
}

// memoryStorage satisfies Storage interface
type memoryStorage struct {
	users map[string]*Option
	sync.Mutex
}

func (m *memoryStorage) Get(username string) (*Option, error) {
	m.Lock()
	defer m.Unlock()

	option, ok := m.users[username]
	if !ok {
		return nil, ErrUserNotFound
	}

	return option, nil
}

func (m *memoryStorage) GetAll() (map[string]*Option, error) {
	m.Lock()
	defer m.Unlock()

	return m.users, nil
}

func (m *memoryStorage) Set(username string, value *Option) error {
	m.Lock()
	defer m.Unlock()

	m.users[username] = value
	return nil
}

func (m *memoryStorage) Delete(username string) error {
	m.Lock()
	defer m.Unlock()

	delete(m.users, username)
	return nil
}

func (m *memoryStorage) Close() error {
	return nil
}
