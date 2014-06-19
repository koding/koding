package sockjs

import (
	"net/http"
	"regexp"
	"testing"
)

func TestMappingMatcher(t *testing.T) {
	m := mapping{"GET", regexp.MustCompile("/prefix/$"), nil}
	var testRequests = []struct {
		method        string
		url           string
		expectedMatch matchType
	}{
		{"GET", "http://foo/prefix/", fullMatch},
		{"POST", "http://foo/prefix/", pathMatch},
		{"GET", "http://foo/prefix_not_mapped", noMatch},
	}
	for _, request := range testRequests {
		req, _ := http.NewRequest(request.method, request.url, nil)
		match, method := m.matches(req)
		if match != request.expectedMatch {
			t.Errorf("mapping %s should match url=%s", m.path, request.url)
		}
		if request.expectedMatch == pathMatch {
			if method != m.method {
				t.Errorf("Matcher method should be %s, but got %s", m.method, method)
			}
		}
	}
}
