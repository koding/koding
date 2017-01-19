package algoliasearch

func checkQuery(query Map, ignore ...string) error {
Outer:
	for k, v := range query {
		// Continue if `k` is to be ignored.
		for _, s := range ignore {
			if s == k {
				continue Outer
			}
		}

		switch k {
		case "query",
			"queryType",
			"typoTolerance",
			"removeWordsIfNoResults",
			"restrictSearchableAttributes",
			"highlightPreTag",
			"highlightPostTag",
			"snippetEllipsisText",
			"filters",
			"analyticsTags",
			"optionalWords",
			"numericFilters",
			"tagFilters",
			"facets",
			"facetFilters",
			"aroundLatLng",
			"insideBoundingBox",
			"insidePolygon",
			"exactOnSingleWordQuery":
			if _, ok := v.(string); !ok {
				return invalidType(k, "string")
			}

		case "attributesToRetrieve",
			"disableTypoToleranceOnAttributes",
			"attributesToSnippet",
			"attributesToHighlight",
			"alternativesAsExact",
			"responseFields":
			if _, ok := v.([]string); !ok {
				return invalidType(k, "[]string")
			}

		case "minWordSizefor1Typo",
			"minWordSizefor2Typos",
			"minProximity",
			"page",
			"hitsPerPage",
			"getRankingInfo",
			"distinct",
			"maxValuesPerFacet",
			"aroundPrecision",
			"minimumAroundRadius":
			if _, ok := v.(int); !ok {
				return invalidType(k, "int")
			}

		case "allowTyposOnNumericTokens",
			"advancedSyntax",
			"analytics",
			"synonyms",
			"replaceSynonymsInHighlight",
			"aroundLatLngViaIP",
			"facetingAfterDistinct":
			if _, ok := v.(bool); !ok {
				return invalidType(k, "bool")
			}

		case "removeStopWords",
			"ignorePlurals":
			switch v.(type) {
			case []string, bool:
				// OK
			default:
				return invalidType(k, "[]string or bool")
			}

		case "aroundRadius":
			switch v.(type) {
			case int, string:
				// OK
			default:
				return invalidType(k, "int or string")
			}

		default:
		}

	}
	return nil
}
