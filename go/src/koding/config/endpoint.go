package config

// Endpoint represents a single worker's endpoint
// mapped to environments.
type Endpoint struct {
	Environment []string `json:"environment"`
	URL         string   `json:"url"`
}

// Endpoints describes all workers and
// their default configuration.
type Endpoints map[string][]*Endpoint

// URL gives a url address for the given worker and environment.
//
// If specified worker does not exist
func (e Endpoints) URL(worker, environment string) string {
	endpoints, ok := e[worker]
	if !ok {
		return ""
	}

	var url string

	for _, endpoint := range endpoints {
		// Default URL is an endpoint with no explicit
		// environments set.
		if len(endpoint.Environment) == 0 {
			url = endpoint.URL
			continue
		}

		for _, env := range endpoint.Environment {
			switch env {
			case environment:
				return endpoint.URL
			case "development", "devmanaged":
				// If there's no default endpoint we fallback
				// to a development one.
				if url == "" {
					url = endpoint.URL
				}
			}
		}
	}

	return url
}

func (e Endpoints) merge(in Endpoints) {
	for inname, inendpoints := range in {
		endpoints, ok := e[inname]
		if !ok {
			// Add missing endpoints to e.
			e[inname] = inendpoints
			continue
		}

		// Remove environments from endpoints and add inendpoint to the end.
		for _, inendpoint := range inendpoints {
			for i := range endpoints {
				endpoints[i].Environment = removeStrings(endpoints[i].Environment, inendpoint.Environment...)
			}
			endpoints = append(endpoints, inendpoint)
		}

		// Merge environments which have the same endpoints.
		for i := 0; i < len(endpoints); i++ {
			if endpoints[i] == nil {
				continue
			}
			for j := i + 1; j < len(endpoints); j++ {
				if endpoints[j] == nil {
					continue
				}
				if endpoints[i].URL == endpoints[j].URL {
					endpoints[i].Environment = append(endpoints[i].Environment, endpoints[j].Environment...)
					endpoints[j] = nil
				}
			}
		}

		// Remove endpoints with empty environments.
		var outendpoints []*Endpoint
		for _, endpoint := range endpoints {
			if endpoint != nil && len(endpoint.Environment) != 0 {
				outendpoints = append(outendpoints, endpoint)
			}
		}

		// Replace endpoints.
		e[inname] = outendpoints
	}
}
