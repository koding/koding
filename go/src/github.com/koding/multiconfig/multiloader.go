package multiconfig

type multiLoader []Loader

// MultiLoader creates a loader that executes the loaders one by one in order
// and returns on the first error.
func MultiLoader(loader ...Loader) Loader {
	return multiLoader(loader)
}

func (m multiLoader) Load(s interface{}) error {
	for _, loader := range m {
		if err := loader.Load(s); err != nil {
			return err
		}
	}

	return nil
}
