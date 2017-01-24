package algoliasearch

import (
	"net/http"
)

// Client is a representation of an Algolia application. Once initialized it
// allows manipulations over the indexes of the application as well as network
// related parameters.
type Client interface {
	// SetExtraHeader allows to set custom headers while reaching out to
	// Algolia servers.
	SetExtraHeader(key, value string)

	// SetTimeout specifies timeouts to use with the HTTP connection.
	SetTimeout(connectTimeout, readTimeout int)

	// SetHTTPClient allows a custom HTTP client to be specified.
	// NOTE: using this may prevent timeouts set on this client from
	// working if the underlying transport is not of type *http.Transport.
	SetHTTPClient(client *http.Client)

	// ListIndexes returns the list of all indexes belonging to this Algolia
	// application.
	ListIndexes() (indexes []IndexRes, err error)

	// InitIndex returns an Index object targeting `name`.
	InitIndex(name string) Index

	// ListKeys returns all the API keys available for this Algolia
	// application.
	ListKeys() (keys []Key, err error)

	// MoveIndex renames the index named `source` as `destination`.
	MoveIndex(source, destination string) (UpdateTaskRes, error)

	// CopyIndex duplicates the index named `source` as `destination`.
	CopyIndex(source, destination string) (UpdateTaskRes, error)

	// DeleteIndex removes the `name` Algolia index.
	DeleteIndex(name string) (res DeleteTaskRes, err error)

	// ClearIndex removes every record from the `name` Algolia index.
	ClearIndex(name string) (res UpdateTaskRes, err error)

	// AddKey creates a new API key from the supplied `ACL` and the specified
	// optional parameters. More details here:
	// https://www.algolia.com/doc/rest#add-a-global-api-key
	AddUserKey(ACL []string, params Map) (res AddKeyRes, err error)

	// UpdateKey updates the API key identified by its value `key` with the
	// given parameters.
	UpdateUserKey(key string, params Map) (res UpdateKeyRes, err error)

	// GetKey returns the key identified by its value `key`.
	GetUserKey(key string) (res Key, err error)

	// DeleteKey deletes the API key identified by its `key`.
	DeleteUserKey(key string) (res DeleteRes, err error)

	// GetLogs retrieves the logs according to the given `params` map which can
	// contain the following fields:
	//   - `length` (number of entries to retrieve)
	//   - `offset` (offset to the first entry)
	//   - `type` (type of logs to retrieve, can be "all", "query", "build" or
	//     "error")
	// More details here:
	// https://www.algolia.com/doc/rest#get-last-logs
	GetLogs(params Map) (logs []LogRes, err error)

	// MultipleQueries performs all the queries specified in `queries` and
	// aggregates the results. The `strategy` can either be set to `none`
	// (default) which executes all the queries until the last one, or set to
	// `stopIfEnoughMatches` to limit the number of results according to the
	// `hitsPerPage` parameter. More details here:
	// https://www.algolia.com/doc/rest#query-multiple-indexes
	MultipleQueries(queries []IndexedQuery, strategy string) (res []MultipleQueryRes, err error)

	// Batch performs all queries in `operations`.
	Batch(operations []BatchOperationIndexed) (res MultipleBatchRes, err error)
}

// Index is a representation used to manipulate an Algolia index.
type Index interface {
	// Delete removes the Algolia index.
	Delete() (res DeleteTaskRes, err error)

	// Clear removes every record from the index.
	Clear() (res UpdateTaskRes, err error)

	// GetObject retrieves the object as an interface representing the
	// JSON-encoded object. The `objectID` is used to uniquely identify the
	// object in the index while `attributes` contains the list of attributes
	// to retrieve.
	GetObject(objectID string, attributes []string) (object Object, err error)

	// GetObjects retrieves the objects identified according to their
	// `objectIDs`.
	GetObjects(objectIDs []string) (objects []Object, err error)

	// GetObjectsAttrs retrieves the selected attributes of the objects
	// identified according to their `objectIDs`.
	GetObjectsAttrs(objectIDs, attributesToRetrieve []string) (objs []Object, err error)

	// DeleteObject deletes an object from the index that is uniquely
	// identified by its `objectID`.
	DeleteObject(objectID string) (res DeleteTaskRes, err error)

	// GetSettings retrieves the index's settings.
	GetSettings() (settings Settings, err error)

	// SetSettings changes the index settings.
	SetSettings(settings Map) (res UpdateTaskRes, err error)

	// WaitTask stops the current execution until the task identified by its
	// `taskID` is finished. The waiting time between each check is usually
	// implemented by starting at 1s and increases by a factor of 2 at each
	// retry (but is bounded at around 20min).
	WaitTask(taskID int) error

	// ListKeys lists all the keys that can access the index.
	ListKeys() (keys []Key, err error)

	// AddKey creates a new API key from the supplied `ACL` and the specified
	// optional `params` parameters for the current index. More details here:
	// https://www.algolia.com/doc/rest#add-an-index-specific-api-key
	AddUserKey(ACL []string, params Map) (res AddKeyRes, err error)

	// UpdateKey updates the key identified by its `key` with all the fields
	// present in the `params` Map. More details here:
	// https://www.algolia.com/doc/rest#update-an-index-specific-api-key
	UpdateUserKey(key string, params Map) (res UpdateKeyRes, err error)

	// GetKey retrieves the key identified by its `value`.
	GetUserKey(value string) (key Key, err error)

	// DeleteKey deletes the key identified by its `value`.
	DeleteUserKey(value string) (res DeleteRes, err error)

	// AddObject adds a new record to the index.
	AddObject(object Object) (res CreateObjectRes, err error)

	// UpdateObject replaces the record in the index matching the one given in
	// parameter, according to its `objectID` attribute.
	UpdateObject(object Object) (res UpdateObjectRes, err error)

	// PartialUpdateObject modifies the record in the index matching the one
	// given in parameter, according to its `objectID` attribute. However, the
	// record is only partially updated i.e. only the specified attributes will
	// be updated, the original record won't be replaced.
	PartialUpdateObject(object Object) (res UpdateTaskRes, err error)

	// PartialUpdateObjectNoCreate modifies the record in the index matching the one
	// given in parameter, according to its `objectID` attribute with a partial
	// update. However, if the object does not exist in the Algolia index, the
	// object is not created.
	PartialUpdateObjectNoCreate(object Object) (res UpdateTaskRes, err error)

	// AddObjects adds several objects to the index.
	AddObjects(objects []Object) (BatchRes, error)

	// UpdateObjects adds or replaces several objects at the same time,
	// according to their respective `objectID` attribute.
	UpdateObjects(objects []Object) (BatchRes, error)

	// PartialUpdateObjects partially updates several objects at the same time,
	// according to their respective `objectID` attribute.
	PartialUpdateObjects(objects []Object) (BatchRes, error)

	// PartialUpdateObjectsNoCreate partially updates several objects at the
	// same time, according to their respective `objectID` attribute, but does
	// not create them if they do not exist.
	PartialUpdateObjectsNoCreate(objects []Object) (BatchRes, error)

	// DeleteObjects removes several objects at the same time, according to
	// their respective `objectID` attribute.
	DeleteObjects(objectIDs []string) (BatchRes, error)

	// Batch processes all the specified `operations` in a batch manner. The
	// operations's actions could be one of the following:
	//   - `addObject`
	//   - `updateObject`
	//   - `partialUpdateObject`
	//   - `partialUpdateObjectNoCreate`
	//   - `deleteObject`
	//   - `clear`
	// More details here:
	// https://www.algolia.com/doc/rest#batch-write-operations.
	Batch(operations []BatchOperation) (res BatchRes, err error)

	// Copy copies the index into a new one called `name`.
	Copy(name string) (UpdateTaskRes, error)

	// Move renames the index into `name`.
	Move(name string) (UpdateTaskRes, error)

	// GetStatus returns the status of a task given its ID `taskID`.
	GetStatus(taskID int) (res TaskStatusRes, err error)

	// SearchSynonyms returns the synonyms matching `query` whose types match
	// `types`. To retrieve the first page, `page` should be set to 0.
	// `hitsPerPage` specifies how many synonym sets will be returned per page.
	SearchSynonyms(query string, types []string, page, hitsPerPage int) (synonyms []Synonym, err error)

	// GetSynonym retrieves the synonym identified by its `objectID`.
	GetSynonym(objectID string) (s Synonym, err error)

	// AddSynonym adds the given `synonym`. This addition can be forwarded to
	// the index replicas by setting `forwardToReplicas` to `true`.
	AddSynonym(synonym Synonym, forwardToReplicas bool) (res UpdateTaskRes, err error)

	// DeleteSynonym removes the synonym identified by its `objectID`. This
	// deletion can be forwarded to the index replicas by setting
	// `forwardToReplicas` to `true`.
	DeleteSynonym(objectID string, forwardToReplicas bool) (res DeleteTaskRes, err error)

	// ClearSynonyms removes all synonyms from the index. The clear operation
	// can be forwarded to the index replicas by setting `forwardToReplicas` to
	// `true`.
	ClearSynonyms(forwardToReplicas bool) (res UpdateTaskRes, err error)

	// BatchSynonyms adds all `synonyms` to the index. The index can be cleared
	// before by setting `replaceExistingSynonyms` to `true`. The optional
	// clear operation and the additions can be forwarded to the index replicas
	// by setting `forwardToReplicas` to `true'.
	BatchSynonyms(synonyms []Synonym, replaceExistingSynonyms, forwardToReplicas bool) (res UpdateTaskRes, err error)

	// Browse returns the hits found according to the given `params`. The
	// `cursor` parameter controls the pagination of the results that `Browse`
	// is able to load. The first time `Browse` is called, `cursor` should be
	// an empty string. After that, subsequent calls must used the updated
	// `cursor` received in the response. This is a low-level function, if you
	// simply want to iterate through all the results, it is preferable to use
	// `BrowseAll` instead. More details here:
	// https://www.algolia.com/doc/rest#browse-all-index-content
	Browse(params Map, cursor string) (res BrowseRes, err error)

	// BrowseAll returns an iterator pointing to the first result that matches
	// the search query given the `params`. Calling `Next()` on the iterator
	// will returns all the hits one by one, without the 1000 elements limit of
	// the Search function.
	BrowseAll(params Map) (it IndexIterator, err error)

	// Search performs a search query according to the `query` search query and
	// the given `params`. More details here:
	// https://www.algolia.com/doc/rest#query-an-index
	Search(query string, params Map) (res QueryRes, err error)

	// DeleteByQuery finds all the records that match the `query`, according to
	// the given 'params` and deletes them. It hangs until all the deletion
	// operations have completed.
	DeleteByQuery(query string, params Map) error

	// SearchForFacetValues searches inside a facet's values, optionally
	// restricting the returned values to those contained in objects matching
	// other (regular) search criteria. The `facet` parameter is the name of
	// the facet to search (must be declared in `attributesForFaceting`). The
	// `query` string is the text used to matched against facet's values. The
	// `params` controls the search parameters you want to apply against the
	// matching records. Note that it can be `nil` and that pagination
	// parameters are not taken into account.
	SearchForFacetValues(facet, query string, params Map) (res SearchFacetRes, err error)

	// SearchFacet does exactly the same as `SearchForFacetValues`. This method
	// is only kept for backward-compatibility reason as we decided to change
	// its name.
	SearchFacet(facet, query string, params Map) (res SearchFacetRes, err error)
}

// IndexIterator is used by the BrowseAll functions to iterate over all the
// records of an index (or a subset according to what the query and the params
// are).
type IndexIterator interface {
	// Next returns the next record each time is is called. Subsequent pages of
	// results are automatically loaded and an error is returned if a problem
	// occurs. When the last element is reached, an error is returned with the
	// following message: "No more hits".
	Next() (res Map, err error)
}
