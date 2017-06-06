package cassette

import "net/http"

type Matcher interface {
	Match(interactions []*Interaction, r *http.Request) (*Interaction, error)
	MatchUrlStrings(expected, actual string) bool
}

type DefaultMatcher struct {
	Matcher
}

func (m *DefaultMatcher) Match(interactions []*Interaction, r *http.Request) (
	*Interaction, error) {

	for _, i := range interactions {
		if r.Method == i.Request.Method && r.URL.String() == i.Request.URL {
			return i, nil
		}
	}

	return nil, InteractionNotFound
}
