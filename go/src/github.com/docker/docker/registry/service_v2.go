package registry

import (
	"fmt"
	"strings"

	"github.com/docker/docker/reference"
	"github.com/docker/go-connections/tlsconfig"
)

func (s *Service) lookupV2Endpoints(repoName reference.Named) (endpoints []APIEndpoint, err error) {
	var cfg = tlsconfig.ServerDefault
	tlsConfig := &cfg
	nameString := repoName.FullName()
	if strings.HasPrefix(nameString, DefaultNamespace+"/") {
		// v2 mirrors
		for _, mirror := range s.Config.Mirrors {
			mirrorTLSConfig, err := s.tlsConfigForMirror(mirror)
			if err != nil {
				return nil, err
			}
			endpoints = append(endpoints, APIEndpoint{
				URL: mirror,
				// guess mirrors are v2
				Version:      APIVersion2,
				Mirror:       true,
				TrimHostname: true,
				TLSConfig:    mirrorTLSConfig,
			})
		}
		// v2 registry
		endpoints = append(endpoints, APIEndpoint{
			URL:          DefaultV2Registry,
			Version:      APIVersion2,
			Official:     true,
			TrimHostname: true,
			TLSConfig:    tlsConfig,
		})

		return endpoints, nil
	}

	slashIndex := strings.IndexRune(nameString, '/')
	if slashIndex <= 0 {
		return nil, fmt.Errorf("invalid repo name: missing '/':  %s", nameString)
	}
	hostname := nameString[:slashIndex]

	tlsConfig, err = s.TLSConfig(hostname)
	if err != nil {
		return nil, err
	}

	endpoints = []APIEndpoint{
		{
			URL:          "https://" + hostname,
			Version:      APIVersion2,
			TrimHostname: true,
			TLSConfig:    tlsConfig,
		},
	}

	if tlsConfig.InsecureSkipVerify {
		endpoints = append(endpoints, APIEndpoint{
			URL:          "http://" + hostname,
			Version:      APIVersion2,
			TrimHostname: true,
			// used to check if supposed to be secure via InsecureSkipVerify
			TLSConfig: tlsConfig,
		})
	}

	return endpoints, nil
}
