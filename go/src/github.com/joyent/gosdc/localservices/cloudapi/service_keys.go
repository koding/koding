package cloudapi

import (
	"fmt"

	"github.com/joyent/gosdc/cloudapi"
)

// ListKeys lists keys in the double
func (c *CloudAPI) ListKeys() ([]cloudapi.Key, error) {
	if err := c.ProcessFunctionHook(c); err != nil {
		return nil, err
	}

	return c.keys, nil
}

// GetKey gets a single key from the double by name
func (c *CloudAPI) GetKey(keyName string) (*cloudapi.Key, error) {
	if err := c.ProcessFunctionHook(c, keyName); err != nil {
		return nil, err
	}

	for _, key := range c.keys {
		if key.Name == keyName {
			return &key, nil
		}
	}

	return nil, fmt.Errorf("Key %s not found", keyName)
}

// CreateKey creates a new key in the double
func (c *CloudAPI) CreateKey(keyName, key string) (*cloudapi.Key, error) {
	if err := c.ProcessFunctionHook(c, keyName, key); err != nil {
		return nil, err
	}

	// check if key already exists or keyName already in use
	for _, k := range c.keys {
		if k.Name == keyName {
			return nil, fmt.Errorf("Key name %s already in use", keyName)
		}
		if k.Key == key {
			return nil, fmt.Errorf("Key %s already exists", key)
		}
	}

	newKey := cloudapi.Key{Name: keyName, Fingerprint: "", Key: key}
	c.keys = append(c.keys, newKey)

	return &newKey, nil
}

// DeleteKey deletes an existing key from the double
func (c *CloudAPI) DeleteKey(keyName string) error {
	if err := c.ProcessFunctionHook(c, keyName); err != nil {
		return err
	}

	for i, key := range c.keys {
		if key.Name == keyName {
			c.keys = append(c.keys[:i], c.keys[i+1:]...)
			return nil
		}
	}

	return fmt.Errorf("Key %s not found", keyName)
}
