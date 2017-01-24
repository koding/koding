package algoliasearch

import (
	"os"
	"testing"
)

func TestSecuredApiKeyGeneration(t *testing.T) {
	t.Parallel()
	apiKey := os.Getenv("ALGOLIA_API_KEY")
	if apiKey == "" {
		t.Fatal("TestSecuredApiKeyGeneration: Missing ALGOLIA_API_KEY")
	}

	t.Log("TestSecuredApiKeyGeneration: Tests invalid key generations")
	{
		cases := []struct {
			params      Map
			expectedErr error
		}{
			{Map{"userToken": 42}, invalidType("userToken", "string")},
			{Map{"restrictIndices": 42}, invalidType("restrictIndices", "string")},
			{Map{"restrictSources": 42}, invalidType("restrictSources", "string")},
			{Map{"validUntil": "NaN"}, invalidType("validUntil", "int")},
			{Map{"referers": 42}, invalidType("referers", "[]string")},
		}

		for _, c := range cases {
			_, err := GenerateSecuredAPIKey(apiKey, c.params)
			if err == nil || err.Error() != c.expectedErr.Error() {
				t.Errorf("TestSecuredApiKeyGeneration: Calling GenerateSecuredAPIKey(%#v)\nexpected error:  \"%s\"\nbut got instead: \"%s\"",
					c.params,
					c.expectedErr,
					err)
			}
		}
	}

	t.Log("TestSecuredApiKeyGeneration: Tests valid key generations")
	{
		cases := []struct {
			params      Map
			expectedKey string
		}{
			{Map{"userToken": "user42"}, "NTc5YjBkMTgwYjdkMzBlYzllYzY5MmY3OGRmOGQzMWU3ZWU0ZTI2ZmY4MGQ0ZTZhMWZlNzJiMzllMjg5YzhmZnVzZXJUb2tlbj11c2VyNDI="},
			{Map{"restrictIndices": "myIndex"}, "ZGQ5NjRjYTdmOWRkYzYwMjBkNWQ4ZGQ3MmZlY2RkOTYyZjIxM2FjNDBhMjBhYzhhNDFiYWI4NDE4ZGJiOTgxYXJlc3RyaWN0SW5kaWNlcz1teUluZGV4"},
			{Map{"restrictSources": ""}, "NmNjYzQ0MzI0MmU3OTg1NDJiZDYyNTIwZjE2OWMwYjU1MjQ0ZmFhNDdmNzdjNDg1MGYxYmY1YWJjNWZkOTU2OHJlc3RyaWN0U291cmNlcz0="},
			{Map{"validUntil": 1481901339150}, "NDZiMWNlNDMyMzEzNTRkZjFiYmMyYjE2ZWFmNzVjOWE5MjkzNTllMTgxZjM3NDI1OWNiZjAyOGZjMTc0NzU3MXZhbGlkVW50aWw9MTQ4MTkwMTMzOTE1MA=="},
			{Map{"referers": []string{"https://algolia.com/*"}}, "NGUyMTdjNzNjMDM0ODM1NzI5MTAyNTA3YmU0ZTEzNDYxOWJmYjI4ZjFhMTZiYjc1ODliYmRjNDRmMTU2MmMyNnJlZmVyZXJzPSU1QiUyMmh0dHBzJTNBJTJGJTJGYWxnb2xpYS5jb20lMkYlMkElMjIlNUQ="},
		}

		for _, c := range cases {
			generatedKey, err := GenerateSecuredAPIKey(apiKey, c.params)
			if err != nil {
				t.Errorf("TestSecuredApiKeyGeneration: Key with params %#v should have been generated withouth error but got: %s", c.params, err)
			}

			if generatedKey != c.expectedKey {
				t.Errorf("TestSecuredApiKeyGeneration: Key was not generated correctly for params %#v:\nexpected key:  \"%s\"\nbut got instead: \"%s\"",
					c.params,
					c.expectedKey,
					generatedKey)
			}
		}
	}
}
