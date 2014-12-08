package collaboration

import "sync"

func NewMemoryStorage() *memoryStorage {
	return &memoryStorage{
		users: make(map[string]string),
	}
}

// memoryStorage satisfies Storage interface
type memoryStorage struct {
	users map[string]string
	sync.Mutex
}

func (m *memoryStorage) Get(username string) (string, error) {
	m.Lock()
	defer m.Unlock()

	if _, ok := m.users[username]; !ok {
		return "", ErrUserNotFound
	}

	return m.users[username], nil
}

func (m *memoryStorage) GetAll() ([]string, error) {
	m.Lock()
	defer m.Unlock()

	allUsers := make([]string, 0)
	for user := range m.users {
		allUsers = append(allUsers, user)
	}
	return allUsers, nil
}

func (m *memoryStorage) Set(username, value string) error {
	m.Lock()
	defer m.Unlock()

	m.users[username] = value
	return nil
}

func (m *memoryStorage) Delete(username string) error {
	m.Lock()
	defer m.Unlock()

	if _, ok := m.users[username]; ok {
		delete(m.users, username)
	}
	return nil
}

func (m *memoryStorage) Close() error {
	return nil
}
