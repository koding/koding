# Algolia Search API Client for Go





[Algolia Search](http://www.algolia.com) is a hosted full-text, numerical, and faceted search engine capable of delivering realtime results from the first keystroke.

Our Go client lets you easily use the [Algolia Search API](https://www.algolia.com/doc/rest_api) from your backend. It wraps the [Algolia Search REST API](http://www.algolia.com/doc/rest_api).




[![Build Status](https://travis-ci.org/algolia/algoliasearch-client-go.png?branch=master)](https://travis-ci.org/algolia/algoliasearch-client-go)[![Coverage Status](https://coveralls.io/repos/algolia/algoliasearch-client-go/badge.png)](https://coveralls.io/r/algolia/algoliasearch-client-go) ![Supported version](https://img.shields.io/badge/Go-%3E=1.3-green.svg)




Table of Contents
=================
**Getting Started**

1. [Setup](#setup)
1. [Quick Start](#quick-start)

1. [Online documentation](#documentation)
1. [Tutorials](#tutorials)


**Commands Reference**

1. [Add a new object](#add-a-new-object-to-the-index)
1. [Update an object](#update-an-existing-object-in-the-index)
1. [Search](#search)
1. [Multiple queries](#multiple-queries)
1. [Get an object](#get-an-object)
1. [Delete an object](#delete-an-object)
1. [Delete by query](#delete-by-query)
1. [Index settings](#index-settings)
1. [List indices](#list-indices)
1. [Delete an index](#delete-an-index)
1. [Clear an index](#clear-an-index)
1. [Wait indexing](#wait-indexing)
1. [Batch writes](#batch-writes)
1. [Security / User API Keys](#security--user-api-keys)
1. [Copy or rename an index](#copy-or-rename-an-index)
1. [Backup / Retrieve all index content](#backup--retrieve-of-all-index-content)
1. [Logs](#logs)




Setup
-------------
To setup your project, follow these steps:




 1. Download AlgoliaSearch using <code>go get github.com/algolia/algoliasearch-client-go/algoliasearch</code>.
 2. Initialize the client with your ApplicationID and API-Key. You can find all of them on [your Algolia account](http://www.algolia.com/users/edit).

 ```go
 import "github.com/algolia/algoliasearch-client-go/algoliasearch"

 client := algoliasearch.NewClient("YourApplicationID", "YourAPIKey")
```




Quick Start
-------------


In 30 seconds, this quick start tutorial will show you how to index and search objects.

Without any prior configuration, you can start indexing [500 contacts](https://github.com/algolia/algoliasearch-client-csharp/blob/master/contacts.json) in the ```contacts``` index using the following code:
```go
index := client.InitIndex("contacts")
content, err := io.ReadFile("contact.json")
var jsonArray interface{}
err = json.Unmarshal(content, jsonArray)
res, err := index.AddObjects(jsonArray)
```

You can now search for contacts using firstname, lastname, company, etc. (even with typos):
```go
// Search by firstname
res, err := index.Search("jimmie", nil)
// Search by firstname with typo
res, err = index.Search("jimie", nil)
// Search for a company
res, err = index.Search("california paint", nil)
// Search for a firstname & company
res, err = index.Search("jimmie paint", nil)
```

Settings can be customized to tune the search behavior. For example, you can add a custom sort by number of followers to the already great built-in relevance:
```go
settings := make(map[string]interface{})
settings["customRanking"] = [1]string{"desc(followers)"}
res, err := index.SetSettings(settings)
```

You can also configure the list of attributes you want to index by order of importance (first = most important):
```go
settings := make(map[string]interface{})
settings["attributesToIndex"] = [6]string{"firstname", "lastname", "company", "email", "city", "address"}
res, err := index.SetSettings(settings)
```

Since the engine is designed to suggest results as you type, you'll generally search by prefix. In this case the order of attributes is very important to decide which hit is the best:
```go
res, err := index.Search("or", nil)
res, err = index.Search("jim", nil)
```


**Notes:** If you are building a web application, you may be more interested in using our [JavaScript client](https://github.com/algolia/algoliasearch-client-js) to perform queries. It brings two benefits:
  * Your users get a better response time by not going through your servers
  * It will offload unnecessary tasks from your servers

```html
<script src="//cdn.jsdelivr.net/algoliasearch/3/algoliasearch.min.js"></script>
<script>
var client = algoliasearch('ApplicationID', 'apiKey');
var index = client.initIndex('indexName');

// perform query "jim"
index.search('jim', searchCallback);

// the last optional argument can be used to add search parameters
index.search(
  'jim', {
    hitsPerPage: 5,
    facets: '*',
    maxValuesPerFacet: 10
  },
  searchCallback
);

function searchCallback(err, content) {
  if (err) {
    console.error(err);
    return;
  }

  console.log(content);
}
</script>
```






Documentation
================
Check our [online documentation](http://www.algolia.com/doc/guides/go):
 * [Initial Import](http://www.algolia.com/doc/guides/go#InitialImport)
 * [Ranking &amp; Relevance](http://www.algolia.com/doc/guides/go#RankingRelevance)
 * [Indexing](http://www.algolia.com/doc/guides/go#Indexing)
 * [Search](http://www.algolia.com/doc/guides/go#Search)
 * [Sorting](http://www.algolia.com/doc/guides/go#Sorting)
 * [Filtering](http://www.algolia.com/doc/guides/go#Filtering)
 * [Faceting](http://www.algolia.com/doc/guides/go#Faceting)
 * [Geo-Search](http://www.algolia.com/doc/guides/go#Geo-Search)
 * [Security](http://www.algolia.com/doc/guides/go#Security)
 * [REST API](http://www.algolia.com/doc/rest)

Tutorials
================

Check out our [tutorials](http://www.algolia.com/doc/tutorials):
 * [Search bar with autocomplete menu](http://www.algolia.com/doc/tutorials/auto-complete)
 * [Search bar with multi category autocomplete menu](http://www.algolia.com/doc/tutorials/multi-auto-complete)
 * [Instant search result pages](http://www.algolia.com/doc/tutorials/instant-search)




Commands Reference
==================



Add a new object to the Index
-------------

Each entry in an index has a unique identifier called `objectID`. There are two ways to add en entry to the index:

 1. Using automatic `objectID` assignment. You will be able to access it in the answer.
 2. Supplying your own `objectID`.

You don't need to explicitly create an index, it will be automatically created the first time you add an object.
Objects are schema less so you don't need any configuration to start indexing. If you wish to configure things, the settings section provides details about advanced settings.

Example with automatic `objectID` assignment:

```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"
res, err = index.AddObject(object)
```

Example with manual `objectID` assignment:

```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"
object["objectID"] = "myID"
res, err := index.AddObject(object)
```

Update an existing object in the Index
-------------

You have three options when updating an existing object:

 1. Replace all its attributes.
 2. Replace only some attributes.
 3. Apply an operation to some attributes.

Example on how to replace all attributes of an existing object:

```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"
object["city"] = "New York"
object["objectID"] = "myID"
res, err := index.UpdateObject(object)
```

You have many ways to update an object's attributes:

 1. Set the attribute value
 2. Add a string or number element to an array
 3. Remove an element from an array
 4. Add a string or number element to an array if it doesn't exist
 5. Increment an attribute
 6. Decrement an attribute

Example to update only the city attribute of an existing object:

```go
object := make(map[string]interface{})
object["city"] = "San Francisco"
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Example to add a tag:

```go
object := make(map[string]interface{})
operation := make(map[string]interface{})
operation["value"] = "MyTags"
operation["_operation"] = "Add"
object["_tags"] = operation
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Example to remove a tag:

```go
object := make(map[string]interface{})
operation := make(map[string]interface{})
operation["value"] = "MyTags"
operation["_operation"] = "Remove"
object["_tags"] = operation
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Example to add a tag if it doesn't exist:

```go
object := make(map[string]interface{})
operation := make(map[string]interface{})
operation["value"] = "MyTags"
operation["_operation"] = "AddUnique"
object["_tags"] = operation
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Example to increment a numeric value:

```go
object := make(map[string]interface{})
operation := make(map[string]interface{})
operation["value"] = 42
operation["_operation"] = "Increment"
object["price"] = operation
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Note: Here we are incrementing the value by `42`. To increment just by one, put
`value:1`.

Example to decrement a numeric value:

```go
object := make(map[string]interface{})
operation := make(map[string]interface{})
operation["value"] = 42
operation["_operation"] = "Decrement"
object["price"] = operation
object["objectID"] = "myID"
res, err := index.PartialUpdateObject(object)
```

Note: Here we are decrementing the value by `42`. To decrement just by one, put
`value:1`.

Search
-------------

**Notes:** If you are building a web application, you may be more interested in using our [JavaScript client](https://github.com/algolia/algoliasearch-client-js) to perform queries. It brings two benefits:
  * Your users get a better response time by not going through your servers
  * It will offload unnecessary tasks from your servers.


To perform a search, you only need to initialize the index and perform a call to the search function.

The search query allows only to retrieve 1000 hits, if you need to retrieve more than 1000 hits for seo, you can use [Backup / Retrieve all index content](#backup--retrieve-of-all-index-content)

You can use the following optional arguments:

### Query Parameters

#### Full Text Search Parameters

 * **query**: (string) The instant search query string. All words of the query are interpreted as prefixes (for example "John Mc" will match "John Mccamey" and "Johnathan Mccamey"). If no query parameter is set all objects are retrieved.
 * **queryType**: Selects how the query words are interpreted. It can be one of the following values:
  * **prefixAll**: All query words are interpreted as prefixes.
  * **prefixLast**: Only the last word is interpreted as a prefix (default behavior).
  * **prefixNone**: No query word is interpreted as a prefix. This option is not recommended.
 * **removeWordsIfNoResults**: This option is used to select a strategy in order to avoid having an empty result page. There are three different options:
  * **lastWords**: When a query does not return any results, the last word will be added as optional. The process is repeated with n-1 word, n-2 word, ... until there are results.
  * **firstWords**: When a query does not return any results, the first word will be added as optional. The process is repeated with second word, third word, ... until there are results.
  * **allOptional**: When a query does not return any results, a second trial will be made with all words as optional. This is equivalent to transforming the AND operand between query terms to an OR operand.
  * **none**: No specific processing is done when a query does not return any results (default behavior).
 * **minWordSizefor1Typo**: The minimum number of characters in a query word to accept one typo in this word.<br/>Defaults to 4.
 * **minWordSizefor2Typos**: The minimum number of characters in a query word to accept two typos in this word.<br/>Defaults to 8.
 * **typoTolerance**: This option allows you to control the number of typos in the result set:
  * **true**: The typo tolerance is enabled and all matching hits are retrieved (default behavior).
  * **false**: The typo tolerance is disabled. For example, if one result matches without typos, then all results with typos will be hidden.
  * **min**: Only keep results with the minimum number of typos.
  * **strict**: Hits matching with 2 typos are not retrieved if there are some matching without typos. This option is useful if you want to avoid false positives as much as possible.
 * **allowTyposOnNumericTokens**: If set to false, disables typo tolerance on numeric tokens (numbers). Defaults to true.
 * **ignorePlural**: If set to true, plural won't be considered as a typo. For example, car and cars will be considered as equals. Defaults to false.
 * **disableTypoToleranceOnAttributes** List of attributes on which you want to disable typo tolerance (must be a subset of the `attributesToIndex` index setting). Attributes are separated with a comma such as `"name,address"`. You can also use JSON string array encoding such as `encodeURIComponent("[\"name\",\"address\"]")`. By default, this list is empty.
 * **restrictSearchableAttributes** List of attributes you want to use for textual search (must be a subset of the `attributesToIndex` index setting). Attributes are separated with a comma such as `"name,address"`. You can also use JSON string array encoding such as `encodeURIComponent("[\"name\",\"address\"]")`. By default, all attributes specified in `attributesToIndex` settings are used to search.
 * **removeStopWords**: Remove stop words from query before executing it. Defaults to false. Contains stop words for 41 languages (Arabic, Armenian, Basque, Bengali, Brazilian, Bulgarian, Catalan, Chinese, Czech, Danish, Dutch, English, Finnish, French, Galician, German, Greek, Hindi, Hungarian, Indonesian, Irish, Italian, Japanese, Korean, Kurdish, Latvian, Lithuanian, Marathi, Norwegian, Persian, Polish, Portugese, Romanian, Russian, Slovak, Spanish, Swedish, Thai, Turkish, Ukranian, Urdu).
 * **advancedSyntax**: Enables the advanced query syntax. Defaults to 0 (false).
    * **Phrase query**: A phrase query defines a particular sequence of terms. A phrase query is built by Algolia's query parser for words surrounded by `"`. For example, `"search engine"` will retrieve records having `search` next to `engine` only. Typo tolerance is _disabled_ on phrase queries.
    * **Prohibit operator**: The prohibit operator excludes records that contain the term after the `-` symbol. For example, `search -engine` will retrieve records containing `search` but not `engine`.
 * **analytics**: If set to false, this query will not be taken into account in the analytics feature. Defaults to true.
 * **synonyms**: If set to false, this query will not use synonyms defined in the configuration. Defaults to true.
 * **replaceSynonymsInHighlight**: If set to false, words matched via synonym expansion will not be replaced by the matched synonym in the highlight results. Defaults to true.
 * **optionalWords**: A string that contains the comma separated list of words that should be considered as optional when found in the query.

#### Pagination Parameters

 * **page**: (integer) Pagination parameter used to select the page to retrieve.<br/>Page is zero based and defaults to 0. Thus, to retrieve the 10th page you need to set `page=9`.
 * **hitsPerPage**: (integer) Pagination parameter used to select the number of hits per page. Defaults to 20.

#### Geo-search Parameters

 * **aroundLatLng**: Search for entries around a given latitude/longitude (specified as two floats separated by a comma).<br/>For example, `aroundLatLng=47.316669,5.016670`.<br/>By default the maximum distance is automatically guessed based on the density of the area but you can specify it manually in meters with the **aroundRadius** parameter. The precision for ranking can be set with **aroundPrecision** parameter. For example, if you set aroundPrecision=100, the distances will be considered by ranges of 100m, for example all distances 0 and 100m will be considered as identical for the "geo" ranking parameter.<br/>When **aroundRadius** is not set, the radius is computed automatically using the density of the area, you can retrieve the computed radius in the **automaticRadius** attribute of the answer, you can also use the **minimumAroundRadius** query parameter to specify a minimum radius in meters for the automatic computation of **aroundRadius**.<br/>At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form `"_geoloc":{"lat":48.853409, "lng":2.348800}` or `"_geoloc":[{"lat":48.853409, "lng":2.348800},{"lat":48.547456, "lng":2.972075}]` if you have several geo-locations in your record).

 * **aroundLatLngViaIP**: Search for entries around a given latitude/longitude automatically computed from user IP address.<br/>For example, `aroundLatLng=47.316669,5.016670`.<br/>You can specify the maximum distance in meters with the **aroundRadius** parameter and the precision for ranking with **aroundPrecision**. For example, if you set aroundPrecision=100, two objects that are in the range 0-99m will be considered as identic in the ranking for the "geo" ranking parameter (same for 100-199, 200-299, ... ranges).<br/>At indexing, you should specify the geo location of an object with the `_geoloc` attribute in the form `{"_geoloc":{"lat":48.853409, "lng":2.348800}}`.

 * **insideBoundingBox**: Search entries inside a given area defined by the two extreme points of a rectangle (defined by 4 floats: p1Lat,p1Lng,p2Lat,p2Lng).<br/>For example, `insideBoundingBox=47.3165,4.9665,47.3424,5.0201`).<br/>At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form `"_geoloc":{"lat":48.853409, "lng":2.348800}` or `"_geoloc":[{"lat":48.853409, "lng":2.348800},{"lat":48.547456, "lng":2.972075}]` if you have several geo-locations in your record). You can use several bounding boxes (OR) by passing more than 4 values. For example instead of having 4 values you can pass 8 to use or OR between two bounding boxes.
 * **insidePolygon**: Search entries inside a given area defined by a set of points (defined by a minimum of 6 floats: p1Lat,p1Lng,p2Lat,p2Lng,p3Lat,p3Long).<br/>For example, `insideBoundingBox=47.3165,4.9665,47.3424,5.0201`).<br/>At indexing, you should specify geoloc of an object with the _geoloc attribute (in the form `"_geoloc":{"lat":48.853409, "lng":2.348800}` or `"_geoloc":[{"lat":48.853409, "lng":2.348800},{"lat":48.547456, "lng":2.972075}]` if you have several geo-locations in your record).

#### Parameters to Control Results Content

 * **attributesToRetrieve**: A string that contains the list of object attributes you want to retrieve in order to minimize the answer size.<br/> Attributes are separated with a comma (for example `"name,address"`). You can also use a string array encoding (for example `["name","address"]` ). By default, all attributes are retrieved. You can also use `*` to retrieve all values when an **attributesToRetrieve** setting is specified for your index.
 * **attributesToHighlight**: A string that contains the list of attributes you want to highlight according to the query. Attributes are separated by commas. You can also use a string array encoding (for example `["name","address"]`). If an attribute has no match for the query, the raw value is returned. By default all indexed text attributes are highlighted. You can use `*` if you want to highlight all textual attributes. Numerical attributes are not highlighted. A matchLevel is returned for each highlighted attribute and can contain:
  * **full**: If all the query terms were found in the attribute.
  * **partial**: If only some of the query terms were found.
  * **none**: If none of the query terms were found.
 * **attributesToSnippet**: A string that contains the list of attributes to snippet alongside the number of words to return (syntax is `attributeName:nbWords`). Attributes are separated by commas (Example: `attributesToSnippet=name:10,content:10`). <br/>You can also use a string array encoding (Example: `attributesToSnippet: ["name:10","content:10"]`). By default, no snippet is computed.
 * **getRankingInfo**: If set to 1, the result hits will contain ranking information in the **_rankingInfo** attribute.
 * **highlightPreTag**: (string) Specify the string that is inserted before the highlighted parts in the query result (defaults to "&lt;em&gt;").
 * **highlightPostTag**: (string) Specify the string that is inserted after the highlighted parts in the query result (defaults to "&lt;/em&gt;").
 

#### Numeric Search Parameters
 * **numericFilters**: A string that contains the comma separated list of numeric filters you want to apply. The filter syntax is `attributeName` followed by `operand` followed by `value`. Supported operands are `<`, `<=`, `=`, `>` and `>=`.

You can easily perform range queries via the `:` operator. This is equivalent to combining a `>=` and `<=` operand. For example, `numericFilters=price:10 to 1000`.

You can also mix OR and AND operators. The OR operator is defined with a parenthesis syntax. For example, `(code=1 AND (price:[0-100] OR price:[1000-2000]))` translates to `encodeURIComponent("code=1,(price:0 to 10,price:1000 to 2000)")`.

You can also use a string array encoding (for example `numericFilters: ["price>100","price<1000"]`).

#### Category Search Parameters
 * **tagFilters**: Filter the query by a set of tags. You can AND tags by separating them with commas. To OR tags, you must add parentheses. For example, `tags=tag1,(tag2,tag3)` means *tag1 AND (tag2 OR tag3)*. You can also use a string array encoding. For example, `tagFilters: ["tag1",["tag2","tag3"]]` means *tag1 AND (tag2 OR tag3)*.<br/>At indexing, tags should be added in the **_tags** attribute of objects. For example `{"_tags":["tag1","tag2"]}`.

#### Faceting Parameters
 * **facetFilters**: Filter the query with a list of facets. Facets are separated by commas and is encoded as `attributeName:value`. To OR facets, you must add parentheses. For example: `facetFilters=(category:Book,category:Movie),author:John%20Doe`. You can also use a string array encoding. For example, `[["category:Book","category:Movie"],"author:John%20Doe"]`.
 * **facets**: List of object attributes that you want to use for faceting. <br/>Attributes are separated with a comma. For example, `"category,author"`. You can also use JSON string array encoding. For example, `["category","author"]`. Only the attributes that have been added in **attributesForFaceting** index setting can be used in this parameter. You can also use `*` to perform faceting on all attributes specified in **attributesForFaceting**. If the number of results is important, the count can be approximate, the attribute `exhaustiveFacetsCount` in the response is true when the count is exact.
 * **maxValuesPerFacet**: Limit the number of facet values returned for each facet. For example, `maxValuesPerFacet=10` will retrieve a maximum of 10 values per facet.

#### UNIFIED FILTER PARAMETER (SQL LIKE)
 * **filters**: Filter the query with numeric, facet or/and tag filters. The syntax is a SQL like syntax, you can use the OR and AND keywords. The syntax for the underlying numeric, facet and tag filters is the same than in the other filters:
  `available=1 AND (category:Book OR NOT category:Ebook) AND public`
  `date: 1441745506 TO 1441755506 AND inStock > 0 AND author:"John Doe"`
The list of keywords is:
 **OR**: create a disjunctive filter between two filters.
 **AND**: create a conjunctive filter between two filters.
 **TO**: used to specify a range for a numeric filter.
 **NOT**: used to negate a filter. The syntax with the ‘-‘ isn’t allowed.

 *Note*: To specify a value with spaces or with a value equal to a keyword, it's possible to add quotes.

 **Warning:**
  * Like for the other filter for performance reason, it's not possible to have FILTER1 OR (FILTER2 AND FILTER3).
  * It's not possible to mix different category of filter inside a OR like num=3 OR tag1 OR facet:value
  * It's not possible to negate an group, it's only possible to negate a filters:  NOT(FILTER1 OR (FILTER2) is not allowed.


#### Distinct Parameter
 * **distinct**: If set to 1, enables the distinct feature, disabled by default, if the `attributeForDistinct` index setting is set. This feature is similar to the SQL "distinct" keyword. When enabled in a query with the `distinct=1` parameter, all hits containing a duplicate value for the attributeForDistinct attribute are removed from results. For example, if the chosen attribute is `show_name` and several hits have the same value for `show_name`, then only the best one is kept and the others are removed.

```go
index := client.InitIndex("contacts")
params := make(map[string]interface{})
res, err := index.Search("", params)
params["attributesToRetrieve"] = "firstname,lastname"
params["hitsPerPage"] = 20
res, err = index.Search("", params)
```

The server response will look like:

```json
{
  "hits": [
    {
      "firstname": "Jimmie",
      "lastname": "Barninger",
      "objectID": "433",
      "_highlightResult": {
        "firstname": {
          "value": "<em>Jimmie</em>",
          "matchLevel": "partial"
        },
        "lastname": {
          "value": "Barninger",
          "matchLevel": "none"
        },
        "company": {
          "value": "California <em>Paint</em> & Wlpaper Str",
          "matchLevel": "partial"
        }
      }
    }
  ],
  "page": 0,
  "nbHits": 1,
  "nbPages": 1,
  "hitsPerPage": 20,
  "processingTimeMS": 1,
  "query": "jimmie paint",
  "params": "query=jimmie+paint&attributesToRetrieve=firstname,lastname&hitsPerPage=50"
}
```





Multiple queries
--------------

You can send multiple queries with a single API call using a batch of queries:

```go
// perform 3 queries in a single API call:
//  - 1st query targets index `categories`
//  - 2nd and 3rd queries target index `products`

queries := make([]interface{}, 3)

queries[0] = map[string]interface{}{"indexName": "categories", "query": myQueryString, "hitsPerPage": 3}
queries[1] = map[string]interface{}{"indexName": "products", "query": myQueryString, "hitsPerPage": 3, "tagFilters": "promotion"}
queries[2] = map[string]interface{}{"indexName": "products", "query": myQueryString, "hitsPerPage": 10}

res, err := client.MultipleQueries(queries)
```

The resulting JSON answer contains a ```results``` array storing the underlying queries answers. The answers order is the same than the requests order.

You can specify a strategy to optimize your multiple queries:
- **none**: Execute the sequence of queries until the end.
- **stopIfEnoughMatches**: Execute the sequence of queries until the number of hits is reached by the sum of hits.



Get an object
-------------

You can easily retrieve an object using its `objectID` and optionally specify a comma separated list of attributes you want:

```go
// Retrieves all attributes
res, err := index.GetObject("myID")
// Retrieves firstname and lastname attributes
res, err = index.GetObject("myID", "firstname,lastname")
// Retrieves only the firstname attribute
res, err = index.GetObject("myID", "firstname")
```

You can also retrieve a set of objects:

```go
res, err = index.GetObjects([2]string{"myObj1", "myObj2"})
```

Delete an object
-------------

You can delete an object using its `objectID`:

```go
res, err := index.DeleteObject("myID")
```


Delete by query
-------------

You can delete all objects matching a single query with the following code. Internally, the API client performs the query, deletes all matching hits, and waits until the deletions have been applied.

```go
params := make(map[string]interface{})
res, err := index.DeleteByQuery("john", params)
```


Index Settings
-------------

You can retrieve all settings using the `GetSettings` function. The result will contain the following attributes:


#### Indexing parameters
 * **attributesToIndex**: (array of strings) The list of fields you want to index.<br/>If set to null, all textual and numerical attributes of your objects are indexed. Be sure to update it to get optimal results.<br/>This parameter has two important uses:
  * *Limit the attributes to index*.<br/>For example, if you store a binary image in base64, you want to store it and be able to retrieve it, but you don't want to search in the base64 string.
  * *Control part of the ranking*.<br/>(see the ranking parameter for full explanation) Matches in attributes at the beginning of the list will be considered more important than matches in attributes further down the list. In one attribute, matching text at the beginning of the attribute will be considered more important than text after. You can disable this behavior if you add your attribute inside `unordered(AttributeName)`. For example, `attributesToIndex: ["title", "unordered(text)"]`.
You can decide to have the same priority for two attributes by passing them in the same string using a comma as a separator. For example `title` and `alternative_title` have the same priority in this example, which is different than text priority: `attributesToIndex:["title,alternative_title", "text"]`.
* **numericAttributesToIndex**: (array of strings) All numerical attributes are automatically indexed as numerical filters. If you don't need filtering on some of your numerical attributes, you can specify this list to speed up the indexing.<br/> If you only need to filter on a numeric value with the operator '=', you can speed up the indexing by specifying the attribute with `equalOnly(AttributeName)`. The other operators will be disabled.
 * **attributesForFaceting**: (array of strings) The list of fields you want to use for faceting. All strings in the attribute selected for faceting are extracted and added as a facet. If set to null, no attribute is used for faceting.
 * **attributeForDistinct**: The attribute name used for the `Distinct` feature. This feature is similar to the SQL "distinct" keyword. When enabled in queries with the `distinct=1` parameter, all hits containing a duplicate value for this attribute are removed from results. For example, if the chosen attribute is `show_name` and several hits have the same value for `show_name`, then only the best one is kept and others are removed.
 * **ranking**: (array of strings) Controls the way results are sorted.<br/>We have nine available criteria:
  * **typo**: Sort according to number of typos.
  * **geo**: Sort according to decreasing distance when performing a geo location based search.
  * **words**: Sort according to the number of query words matched by decreasing order. This parameter is useful when you use the `optionalWords` query parameter to have results with the most matched words first.
  * **proximity**: Sort according to the proximity of the query words in hits.
  * **attribute**: Sort according to the order of attributes defined by attributesToIndex.
  * **exact**:
    * If the user query contains one word: sort objects having an attribute that is exactly the query word before others. For example, if you search for the TV show "V", you want to find it with the "V" query and avoid getting all popular TV shows starting by the letter V before it.
    * If the user query contains multiple words: sort according to the number of words that matched exactly (not as a prefix).
  * **custom**: Sort according to a user defined formula set in the **customRanking** attribute.
  * **asc(attributeName)**: Sort according to a numeric attribute using ascending order. **attributeName** can be the name of any numeric attribute in your records (integer, double or boolean).
  * **desc(attributeName)**: Sort according to a numeric attribute using descending order. **attributeName** can be the name of any numeric attribute in your records (integer, double or boolean). <br/>The standard order is ["typo", "geo", "words", "proximity", "attribute", "exact", "custom"].
 * **customRanking**: (array of strings) Lets you specify part of the ranking.<br/>The syntax of this condition is an array of strings containing attributes prefixed by the asc (ascending order) or desc (descending order) operator. For example, `"customRanking" => ["desc(population)", "asc(name)"]`.
 * **queryType**: Select how the query words are interpreted. It can be one of the following values:
  * **prefixAll**: All query words are interpreted as prefixes.
  * **prefixLast**: Only the last word is interpreted as a prefix (default behavior).
  * **prefixNone**: No query word is interpreted as a prefix. This option is not recommended.
 * **separatorsToIndex**: Specify the separators (punctuation characters) to index. By default, separators are not indexed. Use `+#` to be able to search Google+ or C#.
 * **slaves**: The list of indices on which you want to replicate all write operations. In order to get response times in milliseconds, we pre-compute part of the ranking during indexing. If you want to use different ranking configurations depending of the use case, you need to create one index per ranking configuration. This option enables you to perform write operations only on this index and automatically update slave indices with the same operations.
 * **unretrievableAttributes**: The list of attributes that cannot be retrieved at query time. This feature allows you to have attributes that are used for indexing and/or ranking but cannot be retrieved. Defaults to null.
 * **allowCompressionOfIntegerArray**: Allows compression of big integer arrays. We recommended enabling this feature and then storing the list of user IDs or rights as an integer array. When enabled, the integer array is reordered to reach a better compression ratio. Defaults to false.

#### Query expansion
 * **synonyms**: (array of array of string considered as equals). For example, you may want to retrieve the **black ipad** record when your users are searching for **dark ipad**, even if the word **dark** is not part of the record. To do this, you need to configure **black** as a synonym of **dark**. For example, `"synomyms": [ [ "black", "dark" ], [ "small", "little", "mini" ], ... ]`. Synonym feature also supports multi-words expression like `"synonyms": [ ["NY", "New York"] ]`
 * **placeholders**: (hash of array of words). This is an advanced use case to define a token substitutable by a list of words without having the original token searchable. It is defined by a hash associating placeholders to lists of substitutable words. For example, `"placeholders": { "<streetnumber>": ["1", "2", "3", ..., "9999"]}` would allow it to be able to match all street numbers. We use the `< >` tag syntax to define placeholders in an attribute. For example:
  * Push a record with the placeholder: `{ "name" : "Apple Store", "address" : "&lt;streetnumber&gt; Opera street, Paris" }`.
  * Configure the placeholder in your index settings: `"placeholders": { "<streetnumber>" : ["1", "2", "3", "4", "5", ... ], ... }`.
 * **disableTypoToleranceOnWords**: (string array) Specify a list of words on which automatic typo tolerance will be disabled.
 * **disableTypoToleranceOnAttributes**: (string array) List of attributes on which you want to disable typo tolerance (must be a subset of the `attributesToIndex` index setting). By default the list is empty.
 * **altCorrections**: (object array) Specify alternative corrections that you want to consider. Each alternative correction is described by an object containing three attributes:
  * **word**: The word to correct.
  * **correction**: The corrected word.
  * **nbTypos** The number of typos (1 or 2) that will be considered for the ranking algorithm (1 typo is better than 2 typos).

  For example `"altCorrections": [ { "word" : "foot", "correction": "feet", "nbTypos": 1 }, { "word": "feet", "correction": "foot", "nbTypos": 1 } ]`.

#### Default query parameters (can be overwritten by queries)
 * **minWordSizefor1Typo**: (integer) The minimum number of characters needed to accept one typo (default = 4).
 * **minWordSizefor2Typos**: (integer) The minimum number of characters needed to accept two typos (default = 8).
 * **hitsPerPage**: (integer) The number of hits per page (default = 10).
 * **attributesToRetrieve**: (array of strings) Default list of attributes to retrieve in objects. If set to null, all attributes are retrieved.
 * **attributesToHighlight**: (array of strings) Default list of attributes to highlight. If set to null, all indexed attributes are highlighted.
 * **attributesToSnippet**: (array of strings) Default list of attributes to snippet alongside the number of words to return (syntax is 'attributeName:nbWords').<br/>By default, no snippet is computed. If set to null, no snippet is computed.
 * **highlightPreTag**: (string) Specify the string that is inserted before the highlighted parts in the query result (defaults to "&lt;em&gt;").
 * **highlightPostTag**: (string) Specify the string that is inserted after the highlighted parts in the query result (defaults to "&lt;/em&gt;").
 * **optionalWords**: (array of strings) Specify a list of words that should be considered optional when found in the query.
 * **allowTyposOnNumericTokens**: (boolean) If set to false, disable typo-tolerance on numeric tokens (=numbers) in the query word. For example the query `"304"` will match with `"30450"`, but not with `"40450"` that would have been the case with typo-tolerance enabled. Can be very useful on serial numbers and zip codes searches. Default to false.
 * **ignorePlurals**: (boolean) If set to true, simple plural forms won’t be considered as typos (for example car/cars will be considered as equal). Default to false.
 * **advancedSyntax**: Enable the advanced query syntax. Defaults to 0 (false).

  * **Phrase query:** a phrase query defines a particular sequence of terms. A phrase query is build by Algolia's query parser for words surrounded by `"`. For example, `"search engine"` will retrieve records having `search` next to `engine` only. Typo-tolerance is disabled on phrase queries.

  * **Prohibit operator:** The prohibit operator excludes records that contain the term after the `-` symbol. For example `search -engine` will retrieve records containing `search` but not `engine`.
 * **replaceSynonymsInHighlight**: (boolean) If set to false, words matched via synonyms expansion will not be replaced by the matched synonym in the highlighted result. Default to true.
 * **maxValuesPerFacet**: (integer) Limit the number of facet values returned for each facet. For example: `maxValuesPerFacet=10` will retrieve max 10 values per facet.
 * **distinct**: (integer) Enable the distinct feature (disabled by default) if the `attributeForDistinct` index setting is set. This feature is similar to the SQL "distinct" keyword: when enabled in a query with the `distinct=1` parameter, all hits containing a duplicate value for the`attributeForDistinct` attribute are removed from results. For example, if the chosen attribute is `show_name` and several hits have the same value for `show_name`, then only the best one is kept and others are removed.
 * **typoTolerance**: (string) This setting has four different options:

  * **true:** activate the typo-tolerance (default value).

  * **false:** disable the typo-tolerance

  * **min:** keep only results with the lowest number of typo. For example if one result match without typos, then all results with typos will be hidden.

  * **strict:** if there is a match without typo, then all results with 2 typos or more will be removed. This option is useful if you want to avoid as much as possible false positive.
 * **removeStopWords**: (boolean) Remove stop words from query before executing it. Defaults to false. Contains stop words for 41 languages (Arabic, Armenian, Basque, Bengali, Brazilian, Bulgarian, Catalan, Chinese, Czech, Danish, Dutch, English, Finnish, French, Galician, German, Greek, Hindi, Hungarian, Indonesian, Irish, Italian, Japanese, Korean, Kurdish, Latvian, Lithuanian, Marathi, Norwegian, Persian, Polish, Portugese, Romanian, Russian, Slovak, Spanish, Swedish, Thai, Turkish, Ukranian, Urdu)

You can easily retrieve settings or update them:

```go
settings, err := index.GetSettings()
```

```go
settings := make(map[string]interface{})
settings["customRanking"] = [1]string{"desc(followers)"}
res, err := index.SetSettings(settings)
```

List indices
-------------
You can list all your indices along with their associated information (number of entries, disk size, etc.) with the `ListIndexes` method:

```go
res, err := client.ListIndexes()
```

Delete an index
-------------
You can delete an index using its name:

```go
index := client.InitIndex("contacts")
res, err := index.Delete()
```

Clear an index
-------------
You can delete the index contents without removing settings and index specific API keys by using the clearIndex command:

```go
res, err := index.Clear()
```

Wait indexing
-------------

All write operations in Algolia are asynchronous by design.

It means that when you add or update an object to your index, our servers will
reply to your request with a `taskID` as soon as they understood the write
operation.

The actual insert and indexing will be done after replying to your code.

You can wait for a task to complete using the `waitTask` method on the `taskID` returned by a write operation.

For example, to wait for indexing of a new object:
```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"
task, _ := index.AddObject(object)
_, err := index.WaitTask(task)
```

If you want to ensure multiple objects have been indexed, you only need to check
the biggest `taskID`.

Batch writes
-------------

You may want to perform multiple operations with one API call to reduce latency.
We expose four methods to perform batch operations:
 * `AddObjects`: Add an array of objects using automatic `objectID` assignment.
 * `UpdateObjects`: Add or update an array of objects that contains an `objectID` attribute.
 * `DeleteObjects`: Delete an array of objectIDs.
 * `PartialUpdateObjects`: Partially update an array of objects that contain an `objectID` attribute (only specified attributes will be updated).

Example using automatic `objectID` assignment:
```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"

objects := make([]interface{}, 1)
objects[0] = object
res, err := index.AddObjects(objects)
```

Example with user defined `objectID` (add or update):
```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["lastname"] = "Barninger"
object["objectID"] = "myID"

objects := make([]interface{}, 1)
objects[0] = object
res, err := index.UpdateObjects(objects)
```

Example that deletes a set of records:
```go
objectIDs := []string{"myIDs"}

res, err := index.DeleteObjects(objectIDs)
```

Example that updates only the `firstname` attribute:
```go
object := make(map[string]interface{})
object["firstname"] = "Jimmie"
object["objectID"] = "myID"

objects := make([]interface{}, 1)
objects[0] = object
res, err := index.PartialUpdateObjects(objects)
```



If you have one index per user, you may want to perform a batch operations across severals indexes.
We expose a method to perform this type of batch:
```go
requests := []]interface{}{
	map[string]interface{}{
		"body": map[string]interface{}{"firstname": "Jimmie", "lastname": "Barninger"},
		"indexName": "index1",
		"action": "addObject"
	}
}
res, err := client.CustomBatch(requests)
```

The attribute **action** can have these values:
- addObject
- updateObject
- partialUpdateObject
- partialUpdateObjectNoCreate
- deleteObject

Security / User API Keys
-------------

The admin API key provides full control of all your indices.
You can also generate user API keys to control security.
These API keys can be restricted to a set of operations or/and restricted to a given index.

```go
// Lists global API Keys
res, err := client.ListKeys()
// Lists API Keys that can access only to this index
res, err = index.ListKeys()
```

Each key is defined by a set of permissions that specify the authorized actions. The different permissions are:
 * **search**: Allowed to search.
 * **browse**: Allowed to retrieve all index contents via the browse API.
 * **addObject**: Allowed to add/update an object in the index.
 * **deleteObject**: Allowed to delete an existing object.
 * **deleteIndex**: Allowed to delete index content.
 * **settings**: allows to get index settings.
 * **editSettings**: Allowed to change index settings.
 * **analytics**: Allowed to retrieve analytics through the analytics API.
 * **listIndexes**: Allowed to list all accessible indexes.

Example of API Key creation:
```go
// Creates a new index specific API key valid for 300 seconds, with a rate limit of 100 calls per hour per IP and a maximum of 20 hits
acl := make([]string, 1)
acl[0] = "search"
key, err := index.AddKey(acl, 300, 100, 20)
fmt.Printf(key.(map[string]interface{})["key"].(string))
```

You can also create an API Key with advanced settings:

 * **validity**: Add a validity period. The key will be valid for a specific period of time (in seconds).
 * **maxQueriesPerIPPerHour**: Specify the maximum number of API calls allowed from an IP address per hour. Each time an API call is performed with this key, a check is performed. If the IP at the source of the call did more than this number of calls in the last hour, a 403 code is returned. Defaults to 0 (no rate limit). This parameter can be used to protect you from attempts at retrieving your entire index contents by massively querying the index.


  Note: If you are sending the query through your servers, you must use the `Algolia.with_rate_limits("EndUserIP", "APIKeyWithRateLimit") do ... end` block to enable rate-limit.

 * **maxHitsPerQuery**: Specify the maximum number of hits this API key can retrieve in one call. Defaults to 0 (unlimited). This parameter can be used to protect you from attempts at retrieving your entire index contents by massively querying the index.
 * **indexes**: Specify the list of targeted indices. You can target all indices starting with a prefix or ending with a suffix using the '\*' character. For example, "dev\_\*" matches all indices starting with "dev\_" and "\*\_dev" matches all indices ending with "\_dev". Defaults to all indices if empty or blank.
 * **referers**: Specify the list of referers. You can target all referers starting with a prefix or ending with a suffix using the '\*' character. For example, "algolia.com/\*" matches all referers starting with "algolia.com/" and "\*.algolia.com" matches all referers ending with ".algolia.com". Defaults to all referers if empty or blank.
 * **queryParameters**: Specify the list of query parameters. You can force the query parameters for a query using the url string format (param1=X&param2=Y...).
 * **description**: Specify a description to describe where the key is used.


```go
// Creates a new index specific API key valid for 300 seconds, with a rate limit of 100 calls per hour per IP and a maximum of 20 hits
acl := []string{"search"}
indexes := []string{"myIndex"}
key, err := client.AddKey(acl, indexes, 300, 100, 20)
fmt.Printf(key.(map[string]interface{})["key"].(string))
```

Update the permissions of an existing key:
```go
// Update an existing index specific API key valid for 300 seconds, with a rate limit of 100 calls per hour per IP and a maximum of 20 hits
acl := []string{"search"}
indexes := []string{"myIndex"}
key, err := client.UpdateKey(acl, indexes, 300, 100, 20)
fmt.Printf(key.(map[string]interface{})["key"].(string))
```
Get the permissions of a given key:
```go
// Gets the rights of a global key
key, err := client.GetKey("f420238212c54dcfad07ea0aa6d5c45f")
// Gets the rights of an index specific key
key, err = index.GetKey("71671c38001bf3ac857bc82052485107")
```

Delete an existing key:
```go
// Deletes a global key
task, err := client.DeleteKey("f420238212c54dcfad07ea0aa6d5c45f")
// Deletes an index specific key
task, err := index.DeleteKey("71671c38001bf3ac857bc82052485107")
```



You may have a single index containing per user data. In that case, all records should be tagged with their associated user_id in order to add a `tagFilters=user_42` filter at query time to retrieve only what a user has access to. If you're using the [JavaScript client](http://github.com/algolia/algoliasearch-client-js), it will result in a security breach since the user is able to modify the `tagFilters` you've set by modifying the code from the browser. To keep using the JavaScript client (recommended for optimal latency) and target secured records, you can generate a secured API key from your backend:

```go
key, err := client.GenerateSecuredApiKey("YourSearchOnlyApiKey", map[string]interface{}{"tagFilters": "user_42"})
```

This public API key can then be used in your JavaScript code as follow:

```js
var client = algoliasearch('YourApplicationID', '<%= public_api_key %>');

var index = client.initIndex('indexName')

index.search('something', function(err, content) {
  if (err) {
    console.error(err);
    return;
  }

  console.log(content);
});
```

You can mix rate limits and secured API keys by setting a `userToken` query parameter at API key generation time. When set, a unique user will be identified by her `IP + user_token` instead of only by her `IP`. This allows you to restrict a single user to performing a maximum of `N` API calls per hour, even if she shares her `IP` with another user.

```go
key, error := client.GenerateSecuredApiKey("YourSearchOnlyApiKey", map[string]interface{}{"tagFilters": "user_42", "userToken": "user_42"})
```

This public API key can then be used in your JavaScript code as follow:

```js
var client = algoliasearch('YourApplicationID', '<%= public_api_key %>');

var index = client.initIndex('indexName')

index.search('another query', function(err, content) {
  if (err) {
    console.error(err);
    return;
  }

  console.log(content);
});
```


Copy or rename an index
-------------

You can easily copy or rename an existing index using the `copy` and `move` commands.
**Note**: Move and copy commands overwrite the destination index.

```go
// Rename MyIndex in MyIndexName
res, err := client.InitIndex("MyIndex").Move("MyIndexName")
// Copy MyIndex in MyIndexName
res, err = client.InitIndex("MyIndex").Copy("MyIndexName")
```

The move command is particularly useful if you want to update a big index atomically from one version to another. For example, if you recreate your index `MyIndex` each night from a database by batch, you only need to:
 1. Import your database into a new index using [batches](#batch-writes). Let's call this new index `MyNewIndex`.
 1. Rename `MyNewIndex` to `MyIndex` using the move command. This will automatically override the old index and new queries will be served on the new one.

```go
// Rename MyNewIndex in MyIndex (and overwrite it)
res, err := client.InitIndex("MyNewIndex").Move("MyIndex")
```


Backup / Retrieve of all index content
-------------

The `search` method cannot return more than 1,000 results. If you need to
retrieve all the content of your index (for backup, SEO purposes or for running
a script on it), you should use the `browse` method instead. This method lets
you retrieve objects beyond the 1,000 limit.

This method is optimized for speed. To make it fast, distinct, typo-tolerance,
word proximity, geo distance and number of matched words are disabled. Results
are still returned ranked by attributes and custom ranking.


It will return a `cursor` alongside your data, that you can then use to retrieve
the next chunk of your records.

You can specify custom parameters (like `page` or `hitsPerPage`) on your first
`browse` call, and these parameters will then be included in the `cursor`. Note
that it is not possible to access records beyond the 1,000th on the first call.

Example:

```go
// Iterate with a filter over the index
items, err := index.BrowseAll(map[string]interface{}{"query": "text", "numericFilters": "i<42"}
for {
	hit, err := items.Next()
	if err {
		break
	}
}

// Retrieve the next cursor from the browse method
res, err := index.BrowseFrom(map[string]interface{}{"query": "text", "numericFilters": "i<42", "")
fmt.Printf(res.(map[string]interface{})["cursor"])
```




Logs
-------------

You can retrieve the latest logs via this API. Each log entry contains:
 * Timestamp in ISO-8601 format
 * Client IP
 * Request Headers (API Key is obfuscated)
 * Request URL
 * Request method
 * Request body
 * Answer HTTP code
 * Answer body
 * SHA1 ID of entry

You can retrieve the logs of your last 1,000 API calls and browse them using the offset/length parameters:
 * ***offset***: Specify the first entry to retrieve (0-based, 0 is the most recent log entry). Defaults to 0.
 * ***length***: Specify the maximum number of entries to retrieve starting at the offset. Defaults to 10. Maximum allowed value: 1,000.
 * ***onlyErrors***: Retrieve only logs with an HTTP code different than 200 or 201. (deprecated)
 * ***type***: Specify the type of logs to retrieve:
  * ***query***: Retrieve only the queries.
  * ***build***: Retrieve only the build operations.
  * ***error***: Retrieve only the errors (same as ***onlyErrors*** parameters).

```go
// Get last 10 log entries
res, err := client.GetLogs(0, 10, false)
// Get last 100 log entries
res, err = client.GetLogs(0, 100, false)
// Get last 100 log errors
res, err = client.GetLogs(0, 100, true)
```






