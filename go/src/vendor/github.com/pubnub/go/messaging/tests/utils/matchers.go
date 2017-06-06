package utils

import (
	"bytes"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"sync"

	"github.com/pubnub/go-vcr/cassette"
)

var logMu sync.Mutex

func NewPubnubMatcher(skipFields []string) cassette.Matcher {
	return &PubnubMatcher{
		skipFields: skipFields,
	}
}

func NewPubnubSubscribeMatcher(skipFields []string) cassette.Matcher {
	return &PubnubMatcher{
		skipFields: skipFields,
	}
}

type pubnubService int

const (
	serviceRegular pubnubService = 1 << iota
	serviceCGAddRemove
	serviceSubscribe
)

func getServiceForUrl(path string) pubnubService {
	if isSubscribeRe.MatchString(path) {
		return serviceSubscribe
		// TODO: add cg and pam matchers
	} else {
		return serviceRegular
	}
}

// Matcher for non-subscribe requests
type PubnubMatcher struct {
	cassette.Matcher

	isSubscribe bool
	skipFields  []string
}

func (m *PubnubMatcher) Match(interactions []*cassette.Interaction,
	r *http.Request) (*cassette.Interaction, error) {

	for _, i := range interactions {
		if r.Method != i.Request.Method {
			continue
		}

		expectedURL, err := url.Parse(i.URL)
		if err != nil {
			continue
		}

		if m.MatchUrl(expectedURL, r.URL) {
			return i, nil
		}
	}

	return nil, errorInteractionNotFound(interactions)
}

func (m *PubnubMatcher) MatchUrlStrings(expected, actual string) bool {
	expectedUrl, err := url.Parse(expected)
	if err != nil {
		return false
	}

	actualUrl, err := url.Parse(actual)
	if err != nil {
		return false
	}

	return m.MatchUrl(expectedUrl, actualUrl)
}

func (m *PubnubMatcher) MatchUrl(expected, actual *url.URL) bool {
	serviceType := getServiceForUrl(expected.Path)

	if expected.Host != actual.Host {
		return false
	}

	switch serviceType {
	case serviceSubscribe:
		pathOk := matchSubscribePath(expected.Path, actual.Path)
		queryOk := matchQuery(expected.Query(), actual.Query(),
			m.skipFields, []string{"channel-group"})

		if !pathOk || !queryOk {
			return false
		}
	case serviceRegular:
		pathOk := matchPath(expected.Path, actual.Path)
		queryOk := matchQuery(expected.Query(), actual.Query(),
			m.skipFields, []string{})

		if !pathOk || !queryOk {
			return false
		}
	}

	return true
}

func errorInteractionNotFound(
	interactions []*cassette.Interaction) error {

	var urlsBuffer bytes.Buffer

	for _, i := range interactions {
		urlsBuffer.WriteString(i.URL)
		urlsBuffer.WriteString("\n")
	}

	return errors.New(fmt.Sprintf(
		"Interaction not found in:\n%s",
		urlsBuffer.String()))
}

var isSubscribeRe = regexp.MustCompile("/subscribe/.*$")
var subscribePathRe = regexp.MustCompile("(/subscribe/[^/]+)/([^/]+)/([^?]*)")

func matchPath(expected, actual string) bool {
	return expected == actual
}

func matchSubscribePath(expected, actual string) bool {
	eAllMatches := subscribePathRe.FindAllStringSubmatch(expected, -1)
	aAllMatches := subscribePathRe.FindAllStringSubmatch(actual, -1)

	if len(eAllMatches) == 0 || len(aAllMatches) == 0 {
		return false
	}

	eMatches := eAllMatches[0][1:]
	aMatches := aAllMatches[0][1:]

	if eMatches[0] != aMatches[0] {
		return false
	}

	eChannels := strings.Split(eMatches[1], ",")
	aChannels := strings.Split(aMatches[1], ",")

	if !AssertStringSliceElementsEqual(eChannels, aChannels) {
		return false
	}

	if eMatches[2] != aMatches[2] {
		return false
	}

	return true
}

func matchQuery(eQuery, aQuery url.Values, ignore, mixed []string) bool {
	if len(eQuery) != len(aQuery) {
		return false
	}

	for fKey := range eQuery {
		if hasKey(fKey, ignore) {
			continue
		}

		if hasKey(fKey, mixed) {
			if _, ok := aQuery[fKey]; ok {
				eCgs := eQuery.Get(fKey)
				aCgs := aQuery.Get(fKey)
				eChannels := strings.Split(eCgs, ",")
				aChannels := strings.Split(aCgs, ",")
				if AssertStringSliceElementsEqual(eChannels, aChannels) {
					continue
				}
			}

			return false
		}

		if aQuery[fKey] == nil || eQuery.Get(fKey) != aQuery.Get(fKey) {
			return false
		}
	}

	return true
}
