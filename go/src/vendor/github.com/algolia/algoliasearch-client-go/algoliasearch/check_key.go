package algoliasearch

func checkGenerateSecuredAPIKey(params Map) error {
	if err := checkQuery(params, "userToken", "validUntil", "restrictIndices", "referers", "restrictSources"); err != nil {
		return err
	}

	for k, v := range params {
		switch k {
		case "userToken", "restrictIndices", "restrictSources":
			if _, ok := v.(string); !ok {
				return invalidType(k, "string")
			}

		case "validUntil":
			if _, ok := v.(int); !ok {
				return invalidType(k, "int")
			}

		case "referers":
			if _, ok := v.([]string); !ok {
				return invalidType(k, "[]string")
			}
		}
	}

	return nil
}

func checkKey(params Map) error {
	for k, v := range params {
		switch k {
		case "acl", "indexes", "referers":
			if _, ok := v.([]string); !ok {
				return invalidType(k, "[]string")
			}

		case "description", "queryParameters":
			if _, ok := v.(string); !ok {
				return invalidType(k, "string")
			}

		case "maxHitsPerQuery", "maxQueriesPerIPPerHour", "validity":
			if _, ok := v.(int); !ok {
				return invalidType(k, "int")
			}

		default:
		}
	}

	return nil
}
