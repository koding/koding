package cache

// ShardedCache is the contract for all of the sharded cache backends that are supported by
// this package
type ShardedCache interface {
	// Get returns single item from the backend if the requested item is not
	// found, returns NotFound err
	Get(shardId, key string) (interface{}, error)

	// Set sets a single item to the backend
	Set(shardId, key string, value interface{}) error

	// Delete deletes single item from backend
	Delete(shardId, key string) error

	// Deletes all items in that shard
	DeleteShard(shardId string) error
}
