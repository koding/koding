package sneaker

import "bytes"

// Rotate downloads all of the secrets whose paths match the given pattern,
// decrypts them, re-encrypts them with new data keys, and re-uploads them.
func (m *Manager) Rotate(pattern string, f func(string)) error {
	files, err := m.List(pattern)
	if err != nil {
		return err
	}

	paths := make([]string, 0, len(files))
	for _, file := range files {
		paths = append(paths, file.Path)
	}

	secrets, err := m.Download(paths)
	if err != nil {
		return err
	}

	for _, path := range paths {
		if f != nil {
			f(path)
		}

		if err := m.Upload(path, bytes.NewReader(secrets[path])); err != nil {
			return err
		}
	}

	return nil
}
