package algoliasearch

import (
	"sort"
	"sync"
	"testing"
	"time"
)

func TestIndexOperations(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestIndexOperations")

	objectID := addOneObject(t, c, i)

	t.Log("TestIndexOperations: Test Copy")
	{
		res, err := i.Copy("TestIndexOperations_copy")
		if err != nil {
			t.Fatalf("TestIndexOperations: Cannot copy the index: %s", err)
		}

		waitTask(t, i, res.TaskID)
	}

	t.Log("TestIndexOperations: Test Move")
	i = c.InitIndex("TestIndexOperations_copy")
	{
		res, err := i.Move("TestIndexOperations_move")
		if err != nil {
			t.Fatalf("TestIndexOperations: Cannot move the index: %s", err)
		}

		waitTask(t, i, res.TaskID)
	}

	t.Log("TestIndexOperations: Test Clear")
	i = c.InitIndex("TestIndexOperations_move")
	{
		res, err := i.Clear()
		if err != nil {
			t.Fatalf("TestClear: Cannot clear the index: %s, err")
		}

		waitTask(t, i, res.TaskID)

		_, err = i.GetObject(objectID, nil)
		if err == nil || err.Error() != "{\"message\":\"ObjectID does not exist\",\"status\":404}\n" {
			t.Fatalf("TestIndexOperations: Object %s should be deleted after clear: %s", objectID, err)
		}
	}

	t.Log("TestIndexOperations: Test Delete")
	{
		_, err := i.Delete()
		if err != nil {
			t.Fatalf("TestIndexOperations: Cannot delete the moved index: %s", err)
		}
	}
}

// stringSlicesAreEqual returns `true` if the two slices are the same i.e. if
// they contain the same strings. It returns `false` otherwise. Slices are
// sorted before the comparison.
func stringSlicesAreEqual(s1, s2 []string) bool {
	sort.Strings(s1)
	sort.Strings(s2)

	for i := range s1 {
		if s1[i] != s2[i] {
			return false
		}
	}

	return true
}

// settingsAreEqualByComparable returns `true` if all the comparable fields of
// the given Settings are the same. It returns `false` otherwise.
func settingsAreEqualByComparable(s1, s2 Settings) bool {
	return s1.AllowCompressionOfIntegerArray == s2.AllowCompressionOfIntegerArray &&
		s1.AttributeForDistinct == s2.AttributeForDistinct &&
		s1.SeparatorsToIndex == s2.SeparatorsToIndex &&
		s1.AdvancedSyntax == s2.AdvancedSyntax &&
		s1.AllowTyposOnNumericTokens == s2.AllowTyposOnNumericTokens &&
		s1.HighlightPostTag == s2.HighlightPostTag &&
		s1.HighlightPreTag == s2.HighlightPreTag &&
		s1.HitsPerPage == s2.HitsPerPage &&
		s1.IgnorePlurals == s2.IgnorePlurals &&
		s1.MaxValuesPerFacet == s2.MaxValuesPerFacet &&
		s1.MinProximity == s2.MinProximity &&
		s1.MinWordSizefor1Typo == s2.MinWordSizefor1Typo &&
		s1.MinWordSizefor2Typos == s2.MinWordSizefor2Typos &&
		s1.QueryType == s2.QueryType &&
		s1.ReplaceSynonymsInHighlight == s2.ReplaceSynonymsInHighlight &&
		s1.SnippetEllipsisText == s2.SnippetEllipsisText &&
		s1.TypoTolerance == s2.TypoTolerance
}

// settingsAreEqualByStringSlices returns `true` if all the string slices of
// the given Settings are the same. It returns `false` otherwise`.
func settingsAreEqualByStringSlices(s1, s2 Settings) bool {
	return stringSlicesAreEqual(s1.AttributesForFaceting, s2.AttributesForFaceting) &&
		stringSlicesAreEqual(s1.SearchableAttributes, s2.SearchableAttributes) &&
		stringSlicesAreEqual(s1.CustomRanking, s2.CustomRanking) &&
		stringSlicesAreEqual(s1.NumericAttributesForFiltering, s2.NumericAttributesForFiltering) &&
		stringSlicesAreEqual(s1.Ranking, s2.Ranking) &&
		stringSlicesAreEqual(s1.Replicas, s2.Replicas) &&
		stringSlicesAreEqual(s1.UnretrievableAttributes, s2.UnretrievableAttributes) &&
		stringSlicesAreEqual(s1.DisableTypoToleranceOnAttributes, s2.DisableTypoToleranceOnAttributes) &&
		stringSlicesAreEqual(s1.DisableTypoToleranceOnWords, s2.DisableTypoToleranceOnWords) &&
		stringSlicesAreEqual(s1.AttributesToHighlight, s2.AttributesToHighlight) &&
		stringSlicesAreEqual(s1.AttributesToRetrieve, s2.AttributesToRetrieve) &&
		stringSlicesAreEqual(s1.AttributesToSnippet, s2.AttributesToSnippet) &&
		stringSlicesAreEqual(s1.OptionalWords, s2.OptionalWords)
}

// convertInterfaceSliceToStringSlice converts the input interface{} slice into
// a string slice. This function is only needed internally by
// `settingsAreEqualByRemoveStopWords` because of the way the Settings are
// unmarshal from the JSON.
func convertInterfaceSliceToStringSlice(in []interface{}) (out []string) {
	for i := 0; i < len(in); i++ {
		out = append(out, in[i].(string))
	}

	return
}

// settingsAreEqualByRemoveStopWords checks that the `removeStopWords` fields
// of the given Settings are the same (the type can be either a []string or a
// bool).
func settingsAreEqualByRemoveStopWords(t *testing.T, s1, s2 Settings) {
	itf1 := s1.RemoveStopWords
	itf2 := s2.RemoveStopWords

	is1, ok1 := itf1.([]interface{})
	ss2, ok2 := itf2.([]string)
	if ok1 && ok2 {
		ss1 := convertInterfaceSliceToStringSlice(is1)
		if stringSlicesAreEqual(ss1, ss2) {
			return
		} else {
			t.Fatalf("settingsAreEqualByRemoveStopWords: RemoveStopWords fields are different: %v != %v\n", ss1, ss2)
		}
	} else if !ok1 && !ok2 {
		b1, ok1 := itf1.(bool)
		b2, ok2 := itf2.(bool)

		if ok1 && ok2 {
			if b1 == b2 {
				return
			} else {
				t.Fatalf("settingsAreEqualByRemoveStopWords: RemoveStopWords fields are different: %t != %t\n", b1, b2)
			}
		}
	}

	t.Fatalf("settingsAreEqualByRemoveStopWords: RemoveStopWords fields are not typed as []string or bool: %v != %v\n", itf1, itf2)
}

// settingsAreEqualByDistinct checks that the `distinct` fields of the given
// Settings are the same (the type can be either a int or a bool).
func settingsAreEqualByDistinct(t *testing.T, s1, s2 Settings) {
	itf1 := s1.Distinct
	itf2 := s2.Distinct

	f1, ok1 := itf1.(float64)
	i2, ok2 := itf2.(int)
	if ok1 && ok2 {
		i1 := int(f1)
		if i1 == i2 {
			return
		} else {
			t.Fatalf("settingsAreEqualByDistinct: Distinct fields are different: %d != %d\n", i1, i2)
		}
	} else if !ok1 && !ok2 {
		b1, ok1 := itf1.(bool)
		b2, ok2 := itf2.(bool)

		if ok1 && ok2 {
			if b1 == b2 {
				return
			} else {
				t.Fatalf("settingsAreEqualByDistinct: Distinct fields are different: %t != %t\n", b1, b2)
			}
		}
	}

	t.Fatalf("settingsAreEqualByDistinct: Distinct fields are not typed as int or bool: %v != %v\n", itf1, itf2)
}

// settingsAreEqual deeply checks that the two Settings are the same.
func settingsAreEqual(t *testing.T, s1, s2 Settings) {
	if !settingsAreEqualByComparable(s1, s2) {
		t.Fatalf("settingsAreEqual: Comparable fields are not equal:\n%#v\n%#v\n", s1, s2)
	}

	if !settingsAreEqualByStringSlices(s1, s2) {
		t.Fatalf("settingsAreEqual: String slice fields are not equal:\n%#v\n%#v\n", s1, s2)
	}

	settingsAreEqualByRemoveStopWords(t, s1, s2)
	settingsAreEqualByDistinct(t, s1, s2)
}

// setAndGetAndCompareSettings is a simple wrapper for succesive calls to
// `SetSettings`, `GetSettings` and `settingsAreEqual`.
func setAndGetAndCompareSettings(t *testing.T, i Index, expectedSettings Settings, mapSettings Map) {
	res, err := i.SetSettings(mapSettings)
	if err != nil {
		t.Fatalf("setAndGetAndCompareSettings: Cannot set settings: %s", err)
	}
	waitTask(t, i, res.TaskID)

	settings, err := i.GetSettings()
	if err != nil {
		t.Fatalf("setAndGetAndCompareSettings: Cannot get settings: %s", err)
	}

	settingsAreEqual(t, settings, expectedSettings)
}

func TestSettings(t *testing.T) {
	t.Parallel()
	_, i := initClientAndIndex(t, "TestSettings")

	expectedSettings := Settings{
		AdvancedSyntax:                   true,
		AllowCompressionOfIntegerArray:   false,
		AllowTyposOnNumericTokens:        false,
		AttributeForDistinct:             "attribute",
		AttributesForFaceting:            []string{"attribute"},
		AttributesToHighlight:            []string{"attribute"},
		SearchableAttributes:             []string{"attribute"},
		AttributesToRetrieve:             []string{"attribute"},
		AttributesToSnippet:              []string{"attribute:20"},
		CustomRanking:                    []string{"asc(attribute)"},
		DisableTypoToleranceOnAttributes: []string{"attribute"},
		DisableTypoToleranceOnWords:      []string{"word"},
		Distinct:                         true,
		HighlightPostTag:                 "<p>",
		HighlightPreTag:                  "</p>",
		HitsPerPage:                      10,
		IgnorePlurals:                    true,
		MaxValuesPerFacet:                20,
		MinProximity:                     2,
		MinWordSizefor1Typo:              2,
		MinWordSizefor2Typos:             4,
		NumericAttributesForFiltering:    []string{"attribute"},
		OptionalWords:                    []string{"optional", "words"},
		QueryType:                        "prefixAll",
		Ranking:                          []string{"typo", "geo", "words", "proximity", "attribute", "exact", "custom"},
		RemoveStopWords:                  []string{"en", "fr"},
		ReplaceSynonymsInHighlight:       false,
		SeparatorsToIndex:                "+#",
		Replicas:                         []string{},
		SnippetEllipsisText:              "...",
		TypoTolerance:                    "strict",
		UnretrievableAttributes:          []string{"unretrievable_attribute"},
		ResponseFields:                   []string{"hits", "query"},
	}

	mapSettings := Map{
		"advancedSyntax":                   true,
		"allowCompressionOfIntegerArray":   false,
		"allowTyposOnNumericTokens":        false,
		"attributeForDistinct":             "attribute",
		"attributesForFaceting":            []string{"attribute"},
		"attributesToHighlight":            []string{"attribute"},
		"searchableAttributes":             []string{"attribute"},
		"attributesToRetrieve":             []string{"attribute"},
		"attributesToSnippet":              []string{"attribute:20"},
		"customRanking":                    []string{"asc(attribute)"},
		"disableTypoToleranceOnAttributes": []string{"attribute"},
		"disableTypoToleranceOnWords":      []string{"word"},
		"distinct":                         true,
		"highlightPostTag":                 "<p>",
		"highlightPreTag":                  "</p>",
		"hitsPerPage":                      10,
		"ignorePlurals":                    true,
		"maxValuesPerFacet":                20,
		"minProximity":                     2,
		"minWordSizefor1Typo":              2,
		"minWordSizefor2Typos":             4,
		"numericAttributesForFiltering":    []string{"attribute"},
		"optionalWords":                    []string{"optional", "words"},
		"queryType":                        "prefixAll",
		"ranking":                          []string{"typo", "geo", "words", "proximity", "attribute", "exact", "custom"},
		"removeStopWords":                  []string{"en", "fr"},
		"replaceSynonymsInHighlight":       false,
		"separatorsToIndex":                "+#",
		"replicas":                         []string{},
		"snippetEllipsisText":              "...",
		"typoTolerance":                    "strict",
		"unretrievableAttributes":          []string{"unretrievable_attribute"},
		"responseFields":                   []string{"hits", "query"},
	}

	t.Log("TestSettings: Initial test")
	setAndGetAndCompareSettings(t, i, expectedSettings, mapSettings)

	t.Log("TestSettings: Change the values which can have a different type")
	expectedSettings.RemoveStopWords = true
	mapSettings["removeStopWords"] = true
	expectedSettings.Distinct = 2
	mapSettings["distinct"] = 2
	setAndGetAndCompareSettings(t, i, expectedSettings, mapSettings)
}

// objectsAreEqual returns `true` if the two Objects are deeply equal.
func objectsAreEqual(o1, o2 Object) bool {
	for k, v := range o1 {
		if o2[k] != v {
			return false
		}
	}

	return true
}

// objectsAreEqual returns `true` if the two slices contains the exact same
// Objects. Slices don't need to be sorted.
func objectSlicesAreEqual(t *testing.T, s1, s2 []Object) {
	if len(s1) != len(s2) {
		t.Fatalf("objectSlicesAreEqual: Slices have not the same size: (%d,%d)", len(s1), len(s2))
	}

	var objectIDs []string

	for _, o1 := range s1 {
		id1 := o1["objectID"].(string)

		for _, o2 := range s2 {
			id2 := o2["objectID"].(string)
			if id1 == id2 {
				if objectsAreEqual(o1, o2) {
					objectIDs = append(objectIDs, id1)
				} else {
					t.Fatalf("objectSlicesAreEqual: Objects are not the same:\n%#v\n!=\n%#v\n", o1, o2)
				}
			}
		}
	}

	if len(objectIDs) != len(s1) {
		t.Fatalf("objectSlicesAreEqual: Slices does not contain the same objects:\n%#v\n!=\n%#v\n", s1, s2)
	}
}

// getAllRecords returns all the records from the given index.
func getAllRecords(t *testing.T, i Index) (records []Map) {
	// Initialize the iterator
	it, err := i.BrowseAll(nil)
	if err != nil {
		t.Fatalf("getAllRecords: BrowseAll has failed: %s", err)
	}

	// Iterate through all the records
	record, err := it.Next()
	for err == nil {
		records = append(records, record)
		record, err = it.Next()
	}

	// Check if BrowseAll has finished properly
	if err.Error() != "No more hits" {
		t.Fatalf("getAllRecords: BrowseAll iterations have failed: %s", err)
	}

	return
}

func TestIndexingAndSearch(t *testing.T) {
	t.Parallel()
	_, i := initClientAndIndex(t, "TestIndexingAndSearch")

	var tasks []int

	t.Log("TestIndexingAndSearch: Set the settings")
	{
		res, err := i.SetSettings(Map{
			"searchableAttributes":  []string{"company", "name"},
			"attributesForFaceting": []string{"company"},
			"customRanking":         []string{"asc(company)", "asc(name)"},
		})
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot set settings: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestIndexingAndSearch: Add one object")
	{
		object := Object{"name": "Facebook", "Company": "Mark Zuckerberg"}
		res, err := i.AddObject(object)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot add one object: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestIndexingAndSearch: Add multiple objects at once")
	{
		objects := []Object{
			{"company": "Algolia", "name": "Julien Lemoine"},
			{"company": "Algolia", "name": "Nicolas Dessaigne"},
			{"company": "Amazon", "name": "Jeff Bezos"},
			{"company": "Apple", "name": "Steve Jobs"},
			{"company": "Apple", "name": "Steve Wozniak"},
			{"company": "Arista Networks", "name": "Jayshree Ullal"},
			{"company": "Google", "name": "Larry Page"},
			{"company": "Google", "name": "Rob Pike"},
			{"company": "Google", "name": "Sergueï Brin"},
			{"company": "Microsoft", "name": "Bill Gates"},
			{"company": "SpaceX", "name": "Elon Musk"},
			{"company": "Tesla", "name": "Elon Musk"},
			{"company": "Yahoo", "name": "Marissa Mayer"},
		}
		res, err := i.AddObjects(objects)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot add multiple objects: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestIndexingAndSearch: Wait for all the previous tasks to complete")
	waitTasksAsync(t, i, tasks)

	t.Log("TestIndexingAndSearch: Search for \"algolia\"")
	{
		res, err := i.Search("algolia", nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Search for 'algolia' failed: %s", err)
		}

		if res.NbHits != 2 {
			t.Fatalf("TestIndexingAndSearch: Should return 2 results instead of %d", res.NbHits)
		}
	}

	t.Log("TestIndexingAndSearch: Search for \"elon musk\" with \"company:tesla\" facet")
	{
		params := Map{
			"facets":       "*",
			"facetFilters": "company:tesla",
		}
		res, err := i.Search("elon", params)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Search for 'elon musk' failed: %s", err)
		}

		if res.NbHits != 1 {
			t.Fatalf("TestIndexingAndSearch: Should return 1 results instead of %d", res.NbHits)
		}
	}

	t.Log("TestIndexingAndSearch: Search for \"elon musk\" with \"(company:tesla,company:spacex)\" facets")
	{
		params := Map{
			"facets":       "*",
			"facetFilters": "(company:tesla,company:spacex)",
		}
		res, err := i.Search("elon musk", params)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Search for 'elon musk' failed: %s", err)
		}

		if res.NbHits != 2 {
			t.Fatalf("TestIndexingAndSearch: Should return 2 results instead of %d", res.NbHits)
		}
	}

	t.Log("TestIndexingAndSearch: Iterate and collect over all the records' `objectID`")
	var objectIDs []string
	{
		records := getAllRecords(t, i)
		for _, record := range records {
			objectIDs = append(objectIDs, record["objectID"].(string))
		}

		if len(objectIDs) != 14 {
			t.Fatalf("TestIndexingAndSearch: Should iterate 14 times instead of %d", len(objectIDs))
		}
	}

	t.Log("TestIndexingAndSearch: Test GetObject method")
	{
		_, err := i.GetObject(objectIDs[0], nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object: %s", err)
		}

		object, err := i.GetObject(objectIDs[0], []string{"name"})
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object: %s", err)
		}

		_, ok := object["company"]
		if ok {
			t.Fatalf("TestIndexingAndSearch: `company` attribute shouldn't be retrieved")
		}
	}

	t.Log("TestIndexingAndSearch: Test GetObjects method")
	{
		objects, err := i.GetObjects(objectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the objects: %s", err)
		}

		if len(objects) != len(objectIDs) {
			t.Fatalf("TestIndexingAndSearch: Objects weren't all properly retrieved")
		}
	}

	t.Log("TestIndexingAndSearch: Update first object")
	{
		object, err := i.GetObject(objectIDs[0], nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object (before update): %s", err)
		}

		object["updated"] = true
		res, err := i.UpdateObject(object)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot update the first object: %s", err)
		}

		waitTask(t, i, res.TaskID)

		updatedObject, err := i.GetObject(objectIDs[0], nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object (after update): %s", err)
		}

		if !objectsAreEqual(object, updatedObject) {
			t.Fatalf("TestIndexingAndSearch: Updated objects are not the same:\n%#v\n!=\n%#v\n", object, updatedObject)
		}
	}

	t.Log("TestIndexingAndSearch: Update all the objects")
	{
		objects, err := i.GetObjects(objectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve all the objects (before update): %s", err)
		}

		for i := range objects {
			objects[i]["updated"] = true
		}

		res, err := i.UpdateObjects(objects)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot update all the objects: %s", err)
		}

		waitTask(t, i, res.TaskID)

		updatedObjects, err := i.GetObjects(objectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve all the objects (after update): %s", err)
		}

		objectSlicesAreEqual(t, objects, updatedObjects)
	}

	t.Log("TestIndexingAndSearch: PartialUpdate the first object")
	{
		object, err := i.GetObject(objectIDs[0], nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object (before update): %s", err)
		}

		object["updated"] = false
		partialObject := Object{
			"objectID": objectIDs[0],
			"updated":  false,
		}

		res, err := i.PartialUpdateObject(partialObject)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot partial update the first object: %s", err)
		}

		waitTask(t, i, res.TaskID)

		updatedObject, err := i.GetObject(objectIDs[0], nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve the first object (after partial update): %s", err)
		}

		if !objectsAreEqual(object, updatedObject) {
			t.Fatalf("TestIndexingAndSearch: Partial updated objects are not the same:\n%#v\n!=\n%#v\n", object, updatedObject)
		}
	}

	t.Log("TestIndexingAndSearch: PartialUpdate all the objects")
	{
		objects, err := i.GetObjects(objectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve all the objects (before partial update): %s", err)
		}

		var partialObjects []Object
		for i, object := range objects {
			objects[i]["updated"] = false
			partialObjects = append(partialObjects, Object{
				"objectID": object["objectID"].(string),
				"updated":  false,
			})
		}

		res, err := i.PartialUpdateObjects(partialObjects)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot partial update all the objects: %s", err)
		}

		waitTask(t, i, res.TaskID)

		updatedObjects, err := i.GetObjects(objectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve all the objects (after partial update): %s", err)
		}

		objectSlicesAreEqual(t, objects, updatedObjects)
	}

	t.Log("TestIndexingAndSearch: DeleteByQuery with \"elon musk\" should remove 2 records")
	{
		countBefore := len(getAllRecords(t, i))

		if err := i.DeleteByQuery("elon musk", nil); err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot delete 'elon musk' by query: %s", err)
		}

		countAfter := len(getAllRecords(t, i))
		if countBefore != countAfter+2 {
			t.Fatalf("TestIndexingAndSearch: DeleteByQuery should delete 2 occurences of 'elon musk' insteaf of %d", countBefore-countAfter)
		}
	}

	t.Log("TestIndexingAndSearch: DeleteByQuery with \"\" and facet \"company:apple\" should remove 2 records")
	{
		countBefore := len(getAllRecords(t, i))

		params := Map{
			"facets":       "*",
			"facetFilters": "company:apple",
		}
		if err := i.DeleteByQuery("", params); err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot delete '' by query using 'company:apple' facet: %s", err)
		}

		countAfter := len(getAllRecords(t, i))
		if countBefore != countAfter+2 {
			t.Fatalf("TestIndexingAndSearch: DeleteByQuery should delete 2 occurences of '' using facet 'company:apple' insteaf of %d", countBefore-countAfter)
		}
	}

	t.Log("TestIndexingAndSearch: DeteteObject with \"jeff bezos\"")
	{
		queryRes, err := i.Search("jeff bezos", nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve 'jeff bezos' record: %s", err)
		}
		hit := queryRes.Hits[0]

		res, err := i.DeleteObject(hit["objectID"].(string))
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot delete 'jeff bezos' record: %s", err)
		}

		waitTask(t, i, res.TaskID)

		_, err = i.GetObject("jeff bezos", nil)
		if err == nil || err.Error() != "{\"message\":\"ObjectID does not exist\",\"status\":404}\n" {
			t.Fatalf("TestIndexingAndSearch: 'jeff bezos' record hasn't been deleted properly: %s", err)
		}
	}

	t.Log("TestIndexingAndSearch: DeteteObjects with \"google\" (3 records)")
	{
		queryRes, err := i.Search("google", nil)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot retrieve 'google' records: %s", err)
		}

		var googleObjectIDs []string
		for _, hit := range queryRes.Hits {
			googleObjectIDs = append(googleObjectIDs, hit["objectID"].(string))
		}

		res, err := i.DeleteObjects(googleObjectIDs)
		if err != nil {
			t.Fatalf("TestIndexingAndSearch: Cannot delete 'google' records: %s", err)
		}

		waitTask(t, i, res.TaskID)

		_, err = i.GetObject("google", nil)
		if err == nil || err.Error() != "{\"message\":\"ObjectID does not exist\",\"status\":404}\n" {
			t.Fatalf("TestIndexingAndSearch: 'jeff bezos' record hasn't been deleted properly: %s", err)
		}
	}
}

// synonymsAreEqual returns `true` if the two synonyms are the same.
func synonymsAreEqual(s1, s2 Synonym) bool {
	return s1.ObjectID == s2.ObjectID &&
		s1.Type == s2.Type &&
		s1.Word == s2.Word &&
		s1.Input == s2.Input &&
		s1.Placeholder == s2.Placeholder &&
		stringSlicesAreEqual(s1.Corrections, s2.Corrections) &&
		stringSlicesAreEqual(s1.Synonyms, s2.Synonyms) &&
		stringSlicesAreEqual(s1.Replacements, s2.Replacements)
}

// synonymSlicesAreEqual returns `true` if the two slices contains the exact
// same synonyms. Slices don't need to be sorted.
func synonymSlicesAreEqual(synonyms1, synonyms2 []Synonym) bool {
	count := 0

	if len(synonyms1) != len(synonyms2) {
		return false
	}

	for _, s1 := range synonyms1 {
		for _, s2 := range synonyms2 {
			if synonymsAreEqual(s1, s2) {
				count++
				break
			}
		}
	}

	return count == len(synonyms1)
}

func TestSynonym(t *testing.T) {
	t.Parallel()
	_, i := initClientAndIndex(t, "TestSynonym")

	var tasks []int

	t.Log("TestSynonym: Set the settings")
	{
		res, err := i.SetSettings(Map{
			"searchableAttributes": []string{"company"},
			"customRanking":        []string{"asc(company)"},
		})
		if err != nil {
			t.Fatalf("TestSynonym: Cannot set settings: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestSynonym: Add multiple objects at once")
	{
		objects := []Object{
			{"company": "<GOOG>"},
			{"company": "Algolia"},
			{"company": "Amazon"},
			{"company": "Apple"},
			{"company": "Arista Networks"},
			{"company": "Microsoft"},
			{"company": "SpaceX"},
			{"company": "Tesla"},
			{"company": "Yahoo"},
		}
		res, err := i.AddObjects(objects)
		if err != nil {
			t.Fatalf("TestSynonym: Cannot add multiple objects: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	synonyms := []Synonym{
		NewAltCorrectionSynonym("rob", []string{"robpike"}, "rob", AltCorrection1),
		NewAltCorrectionSynonym("pike", []string{"robpike"}, "pike", AltCorrection2),
		NewOneWaySynonym("julien", "speedblue", []string{"julien lemoine"}),
		NewPlaceholderSynonym("google_placeholder", "<GOOG>", []string{"Google", "GOOG"}),
	}

	t.Log("TestSynonym: Add multiple synonyms at once")
	{
		res, err := i.BatchSynonyms(synonyms, false, false)
		if err != nil {
			t.Fatalf("TestSynonym: Cannot add multiple synonyms: %s", err)
		}

		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestSynonym: Add one synonym")
	{
		synonym := NewSynonym("tesla", []string{"tesla", "tesla motors"})
		synonyms = append(synonyms, synonym)

		res, err := i.AddSynonym(synonym, true)
		if err != nil {
			t.Fatalf("TestSynonym: Cannot add one synonym: %s", err)
		}

		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestSynonym: Wait for all the previous tasks to complete")
	waitTasksAsync(t, i, tasks)

	t.Log("TestSynonym: SearchSynonyms with \"\"")
	{
		foundSynonyms, err := i.SearchSynonyms("", []string{}, 0, 1000)
		if err != nil {
			t.Fatalf("TestSynonym: Could not find any synonym with '' query: %s", err)
		}

		if !synonymSlicesAreEqual(synonyms, foundSynonyms) {
			t.Fatalf("TestSynonym: Synonym slices are not equal:\n%v\n%v\n", synonyms, foundSynonyms)
		}
	}

	t.Log("TestSynonym: SearchSynonyms with \"\" and hitsPerPage=1")
	{
		foundSynonyms, err := i.SearchSynonyms("", []string{}, 0, 1)
		if err != nil {
			t.Fatalf("TestSynonym: Could not find any synonym with '' query and hitsPerPage=1: %s", err)
		}

		if len(foundSynonyms) != 1 {
			t.Fatalf("TestSynonym: Should return 1 synonym instead of %d", len(foundSynonyms))
		}
	}

	t.Log("TestSynonym: Get the first synonym")
	{
		foundSynonym, err := i.GetSynonym(synonyms[0].ObjectID)
		if err != nil {
			t.Fatalf("TestSynonym: Could not get the first synonym: %s", err)
		}

		if !synonymsAreEqual(foundSynonym, synonyms[0]) {
			t.Fatalf("TestSynonym: First synonym not returned properly:\n%v\n%v\n", foundSynonym, synonyms[0])
		}
	}

	t.Log("TestSynonym: Delete the first synonym")
	{
		res, err := i.DeleteSynonym(synonyms[0].ObjectID, false)
		if err != nil {
			t.Fatalf("TestSynonym: Could not delete the first synonym: %s", err)
		}

		waitTask(t, i, res.TaskID)

		_, err = i.GetSynonym(synonyms[0].ObjectID)
		if err == nil || err.Error() != "{\"message\":\"Synonym set does not exist\",\"status\":404}" {
			t.Fatalf("TestSynonym: First synonym hasn't been deleted properly: %s", err)
		}
	}

	{
		res, err := i.ClearSynonyms(false)
		if err != nil {
			t.Fatalf("TestSynonym: Could not clear index' synonyms: %s", err)
		}

		waitTask(t, i, res.TaskID)

		foundSynonyms, err := i.SearchSynonyms("", []string{}, 0, 1000)
		if err != nil {
			t.Fatalf("TestSynonym: Could not retrieve the synonyms after clear: %s", err)
		}

		if len(foundSynonyms) != 0 {
			t.Fatalf("TestSynonym: Index' synonyms haven't been cleared properly: %s", err)
		}
	}
}

// waitIndexKey waits until the key has been properly added to the given index
// and if the given function, if not `nil`, returns `true`.
func waitIndexKey(t *testing.T, i Index, keyID string, f func(k Key) bool) {
	retries := 120

	for r := 0; r < retries; r++ {
		key, err := i.GetUserKey(keyID)

		if err == nil && (f == nil || f(key)) {
			return
		}
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("waitIndexKey: Key not found or function call failed")
}

// waitIndexKeysAsync waits until all the keys have been properly added to the
// given index and if the given function, if not `nil`, returns `true` for
// every key.
func waitIndexKeysAsync(t *testing.T, i Index, keyIDs []string, f func(k Key) bool) {
	var wg sync.WaitGroup

	for _, keyID := range keyIDs {
		wg.Add(1)

		go func(keyID string) {
			defer wg.Done()
			waitIndexKey(t, i, keyID, f)
		}(keyID)
	}

	wg.Wait()
}

// deleteIndexKey deletes the key for the given index.
func deleteIndexKey(t *testing.T, i Index, key string) {
	_, err := i.DeleteUserKey(key)
	if err != nil {
		t.Fatalf("deleteIndexKey: Cannot delete key: %s", err)
	}
}

// deleteAllIndexKeys properly deletes all previous keys associated to the
// index.
func deleteAllIndexKeys(t *testing.T, i Index) {
	keys, err := i.ListKeys()

	if err != nil {
		t.Fatalf("deleteAllKeys: Cannot list the keys: %s", err)
	}

	for _, key := range keys {
		_, err = i.DeleteUserKey(key.Value)
		if err != nil {
			t.Fatalf("deleteAllKeys: Cannot delete a key: %s", err)
		}
	}

	for len(keys) != 0 {
		keys, err = i.ListKeys()

		if err != nil {
			t.Fatalf("deleteAllKeys: Cannot list the keys: %s", err)
		}

		time.Sleep(1 * time.Second)
	}
}

func TestIndexKeys(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestIndexKeys")

	addOneObject(t, c, i)

	deleteAllIndexKeys(t, i)

	t.Log("TestIndexKeys: Check that no key was previously existing")
	{
		keys, err := i.ListKeys()

		if err != nil {
			t.Fatalf("TestIndexKeys: Cannot list the keys: %s", err)
		}

		if len(keys) != 0 {
			t.Fatalf("TestIndexKeys: Should return 0 keys instead of %d", len(keys))
		}
	}

	var searchKey, allRightsKey string

	t.Log("TestIndexKeys: Add a search key with parameters")
	{
		params := Map{
			"description":            "",
			"maxQueriesPerIPPerHour": 1000,
			"referers":               []string{},
			"queryParameters":        "typoTolerance=strict",
			"validity":               600,
			"maxHitsPerQuery":        1,
		}

		res, err := i.AddUserKey([]string{"search"}, params)
		if err != nil {
			t.Fatalf("TestIndexKeys: Cannot create the search key: %s", err)
		}

		searchKey = res.Key
	}
	defer deleteIndexKey(t, i, searchKey)

	t.Log("TestIndexKeys: Add an all-permissions key")
	{
		acl := []string{
			"search",
			"browse",
			"addObject",
			"deleteObject",
			"deleteIndex",
			"settings",
			"editSettings",
			"analytics",
			"listIndexes",
		}

		res, err := i.AddUserKey(acl, nil)
		if err != nil {
			t.Fatalf("TestIndexKeys: Cannot create the all-rights key: %s", err)
		}

		allRightsKey = res.Key
	}
	defer deleteIndexKey(t, i, allRightsKey)

	waitIndexKeysAsync(t, i, []string{searchKey, allRightsKey}, nil)

	t.Log("TestIndexKeys: Update search key description")
	{
		params := Map{"description": "Search-Only Key"}

		_, err := i.UpdateUserKey(searchKey, params)
		if err != nil {
			t.Fatalf("TestIndexKeys: Cannot update search only key's description: %s", err)
		}

		waitIndexKey(t, i, searchKey, func(k Key) bool { return k.Description == "Search-Only Key" })
	}
}

func TestSettingsToMap(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestSettingsToMap")

	addOneObject(t, c, i)

	t.Log("TestSettingsToMap: Get the original settings")
	settingsBefore, err := i.GetSettings()
	if err != nil {
		t.Fatalf("TestSettingsToMap: Cannot retrieve the settings (before): %s", err)
	}

	t.Log("TestSettingsToMap: Set the settings by calling `ToMap` on the settings")
	res, err := i.SetSettings(settingsBefore.ToMap())
	if err != nil {
		t.Fatalf("TestSettingsToMap: Cannot set the settings: %s", err)
	}
	waitTask(t, i, res.TaskID)

	t.Log("TestSettingsToMap: Get the settings once again")
	settingsAfter, err := i.GetSettings()
	if err != nil {
		t.Fatalf("TestSettingsToMap: Cannot retrieve the settings (after): %s", err)
	}

	t.Log("TestSettingsToMap: Compare the settings")
	settingsAreEqual(t, settingsBefore, settingsAfter)
}

func facetHitSliceAreEqual(fs1, fs2 []FacetHit) bool {
	if len(fs1) != len(fs2) {
		return false
	}

	ok := 0

	for _, f1 := range fs1 {
		for _, f2 := range fs2 {
			if f1 == f2 {
				ok++
				break
			}
		}
	}

	return ok == len(fs1)
}

func TestSearchForFacetValues(t *testing.T) {
	t.Parallel()
	_, i := initClientAndIndex(t, "TestSearchForFacetValues")

	var tasks []int

	t.Log("TestSearchForFacetValues: Add multiple objects at once")
	{
		objects := []Object{
			{"company": "Algolia", "name": "Julien Lemoine"},
			{"company": "Algolia", "name": "Nicolas Dessaigne"},
			{"company": "Amazon", "name": "Jeff Bezos"},
			{"company": "Apple", "name": "Steve Jobs"},
			{"company": "Apple", "name": "Steve Wozniak"},
			{"company": "Arista Networks", "name": "Jayshree Ullal"},
			{"company": "Google", "name": "Larry Page"},
			{"company": "Google", "name": "Rob Pike"},
			{"company": "Google", "name": "Sergueï Brin"},
			{"company": "Microsoft", "name": "Bill Gates"},
			{"company": "SpaceX", "name": "Elon Musk"},
			{"company": "Tesla", "name": "Elon Musk"},
			{"company": "Yahoo", "name": "Marissa Mayer"},
		}
		res, err := i.AddObjects(objects)
		if err != nil {
			t.Fatalf("TestSearchForFacetValues: Cannot add multiple objects: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestSearchForFacetValues: Set settings")
	{
		res, err := i.SetSettings(Map{
			"searchableAttributes":  []string{"company"},
			"attributesForFaceting": []string{"company"},
		})
		if err != nil {
			t.Fatalf("TestSearchForFacetValues: Cannot set attributesForFaceting setting: %s", err)
		}
		tasks = append(tasks, res.TaskID)
	}

	t.Log("TestSearchForFacetValues: Wait for all the previous tasks to complete")
	waitTasksAsync(t, i, tasks)

	t.Log("TestSearchForFacetValues: Run queries")
	{
		expected := []FacetHit{
			{Value: "Algolia", Highlighted: "<em>A</em>lgolia", Count: 2},
			{Value: "Amazon", Highlighted: "<em>A</em>mazon", Count: 1},
			{Value: "Apple", Highlighted: "<em>A</em>pple", Count: 2},
			{Value: "Arista Networks", Highlighted: "<em>A</em>rista Networks", Count: 1},
		}

		res, err := i.SearchForFacetValues("company", "a", nil)
		if err != nil {
			t.Fatalf("TestSearchForFacetValues: Cannot SearchForFacetValues: %s", err)
		}

		if len(res.FacetHits) != 4 {
			t.Fatalf("TestSearchForFacetValues: Should return 4 facet hits instead of %d", len(res.FacetHits))
		}

		if !facetHitSliceAreEqual(res.FacetHits, expected) {
			t.Fatalf("TestSearchForFacetValues: FacetHit slices should be equal:\nExpected: %#v\nGot: %#v\n", res.FacetHits, expected)
		}

		// Check that `SearchFacet` is behaving in the exact same way as
		// `SearchForFacetValues` as it was kept for backward-compatibily.
		res2, err2 := i.SearchFacet("company", "a", nil)
		if err != err2 {
			t.Fatalf("TestSearchForFacetValues: SearchFacet and SearchForFacetValues aren't returing the same error:\nearchForFacetValues: %#v\nSearchForFacet: %#v\n", err, err2)
		}

		if !facetHitSliceAreEqual(res.FacetHits, res2.FacetHits) {
			t.Fatalf("TestSearchForFacetValues: SearchFacet and SearchForFacetValues aren't returing the same slices:\nearchForFacetValues: %#v\nSearchForFacet: %#v\n", res.FacetHits, res2.FacetHits)
		}
	}

	{
		params := Map{
			"typoTolerance": "false",
		}

		res, err := i.SearchForFacetValues("company", "aglolia", params)
		if err != nil {
			t.Fatalf("TestSearchForFacetValues: Cannot SearchForFacetValues: %s", err)
		}

		if len(res.FacetHits) != 0 {
			t.Fatalf("TestSearchForFacetValues: Should return 0 facet hits instead of %d\nGot: %#v\n", len(res.FacetHits), res.FacetHits)
		}

		// Check that `SearchFacet` is behaving in the exact same way as
		// `SearchForFacetValues` as it was kept for backward-compatibily.
		res2, err2 := i.SearchFacet("company", "aglolia", params)
		if err != err2 {
			t.Fatalf("TestSearchForFacetValues: SearchFacet and SearchForFacetValues aren't returing the same error:\nearchForFacetValues: %#v\nSearchForFacet: %#v\n", err, err2)
		}

		if !facetHitSliceAreEqual(res.FacetHits, res2.FacetHits) {
			t.Fatalf("TestSearchForFacetValues: SearchFacet and SearchForFacetValues aren't returing the same slices:\nearchForFacetValues: %#v\nSearchForFacet: %#v\n", res.FacetHits, res2.FacetHits)
		}
	}
}

func TestGeoSearchParameters(t *testing.T) {
	t.Parallel()
	c, i := initClientAndIndex(t, "TestGeoSearchParameters")
	addOneObject(t, c, i)

	t.Log("TestGeoSearchParameters: Test valid parameters")
	{
		validParams := []Map{
			Map{"insideBoundingBox": "1.0,2.0,3.0,4.0"},
			Map{"insideBoundingBox": "1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0"},
			Map{"insidePolygon": "1.0,2.0,3.0,4.0,5.0,6.0"},
			Map{"insidePolygon": "[[1.0,2.0,3.0,4.0,5.0,6.0],[1.0,2.0,3.0,4.0,5.0,6.0]]"},
		}

		for _, params := range validParams {
			if _, err := i.Search("", params); err != nil {
				t.Errorf("TestGeoSearchParameters: Parameters %#v should not have raised an error but got `%s` instead",
					params,
					err,
				)
			}
		}
	}

	t.Log("TestGeoSearchParameters: Test invalid parameters")
	{
		cases := []struct {
			params      Map
			expectedErr error
		}{
			{Map{"insideBoundingBox": []string{"1.0,2.0,3.0,4.0"}}, invalidType("insideBoundingBox", "string")},
			{Map{"insidePolygon": []string{"1.0,2.0,3.0,4.0"}}, invalidType("insidePolygon", "string")},
		}

		for _, c := range cases {
			if _, err := i.Search("", c.params); err == nil || err.Error() != c.expectedErr.Error() {
				t.Errorf("TestGeoSearchParameters: Parameters %#v should have raised an error `%s` but got `%s` instead",
					c.params,
					c.expectedErr,
					err,
				)
			}
		}
	}
}
