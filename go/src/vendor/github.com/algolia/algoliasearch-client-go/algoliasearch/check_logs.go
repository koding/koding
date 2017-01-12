package algoliasearch

func checkGetLogs(params Map) error {
	for k, v := range params {
		switch k {
		case "length", "offset":
			if _, ok := v.(int); !ok {
				return invalidType(k, "int")
			}

		case "type":
			if _, ok := v.(string); !ok {
				return invalidType(k, "string")
			}

		default:
		}
	}

	return nil
}
