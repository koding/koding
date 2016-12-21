package cache

import "container/list"

// LFUNoTS holds the cache struct
type LFUNoTS struct {
	// list holds all items in a linked list
	frequencyList *list.List

	// holds the all cache values
	cache Cache

	// size holds the limit of the LFU cache
	size int

	// currentSize holds the current item size in the list
	// after each adding of item, currentSize will be increased
	currentSize int
}

type cacheItem struct {
	// key of cache value
	k string

	// value of cache value
	v interface{}

	// holds the frequency elements
	// it holds the element's usage as count
	// if cacheItems is used 4 times (with set or get operations)
	// the freqElement's frequency counter will be 4
	// it holds entry struct inside Value of list.Element
	freqElement *list.Element
}

// NewLFUNoTS creates a new LFU cache struct for further cache operations. Size
// is used for limiting the upper bound of the cache
func NewLFUNoTS(size int) Cache {
	if size < 1 {
		panic("invalid cache size")
	}

	return &LFUNoTS{
		frequencyList: list.New(),
		cache:         NewMemoryNoTS(),
		size:          size,
		currentSize:   0,
	}
}

// Get gets value of cache item
// then increments the usage of the item
func (l *LFUNoTS) Get(key string) (interface{}, error) {
	res, err := l.cache.Get(key)
	if err != nil {
		return nil, err
	}

	ci := res.(*cacheItem)

	// increase usage of cache item
	l.incr(ci)
	return ci.v, nil
}

// Set sets a new key-value pair
// Set increments the key usage count too
//
// eg:
// cache.Set("test_key","2")
// cache.Set("test_key","1")
// if you try to set a value into same key
// its usage count will be increased
// and usage count of "test_key" will be 2 in this example
func (l *LFUNoTS) Set(key string, value interface{}) error {
	return l.set(key, value)
}

// Delete deletes the key and its dependencies
func (l *LFUNoTS) Delete(key string) error {
	res, err := l.cache.Get(key)
	if err != nil && err != ErrNotFound {
		return err
	}

	// we dont need to delete if already doesn't exist
	if err == ErrNotFound {
		return nil
	}

	ci := res.(*cacheItem)

	l.remove(ci, ci.freqElement)
	l.currentSize--
	return l.cache.Delete(key)
}

// set sets a new key-value pair
func (l *LFUNoTS) set(key string, value interface{}) error {
	res, err := l.cache.Get(key)
	if err != nil && err != ErrNotFound {
		return err
	}

	if err == ErrNotFound {
		//create new cache item
		ci := newCacheItem(key, value)

		// if cache size si reached to max size
		// then first remove lfu item from the list
		if l.currentSize >= l.size {
			// then evict some data from head of linked list.
			l.evict(l.frequencyList.Front())
		}

		l.cache.Set(key, ci)
		l.incr(ci)

	} else {
		//update existing one
		val := res.(*cacheItem)
		val.v = value
		l.cache.Set(key, val)
		l.incr(res.(*cacheItem))
	}

	return nil
}

// entry holds the frequency node informations
type entry struct {
	// freqCount holds the frequency number
	freqCount int

	// itemCount holds the items how many exist in list
	listEntry map[*cacheItem]struct{}
}

// incr increments the usage of cache items
// incrementing will be used in 'Get' & 'Set' functions
// whenever these functions are used, usage count of any key
// will be increased
func (l *LFUNoTS) incr(ci *cacheItem) {
	var nextValue int
	var nextPosition *list.Element
	// update existing one
	if ci.freqElement != nil {
		nextValue = ci.freqElement.Value.(*entry).freqCount + 1
		// replace the position of frequency element
		nextPosition = ci.freqElement.Next()
	} else {
		// create new frequency element for cache item
		// ci.freqElement is nil so next value of freq will be 1
		nextValue = 1
		// we created new element and its position will be head of linked list
		nextPosition = l.frequencyList.Front()
		l.currentSize++
	}

	// we need to check position first, otherwise it will panic if we try to fetch value of entry
	if nextPosition == nil || nextPosition.Value.(*entry).freqCount != nextValue {
		// create new entry node for linked list
		entry := newEntry(nextValue)
		if ci.freqElement == nil {
			nextPosition = l.frequencyList.PushFront(entry)
		} else {
			nextPosition = l.frequencyList.InsertAfter(entry, ci.freqElement)
		}
	}

	nextPosition.Value.(*entry).listEntry[ci] = struct{}{}
	ci.freqElement = nextPosition

	// we have moved the cache item to the next position,
	// then we need to  remove old position of the cacheItem from the list
	// then we deleted previous position of cacheItem
	if ci.freqElement.Prev() != nil {
		l.remove(ci, ci.freqElement.Prev())
	}
}

// remove removes the cache item from the cache list
// after deleting key from the list, if its linked list has no any item no longer
// then that linked list elemnet will be removed from the list too
func (l *LFUNoTS) remove(ci *cacheItem, position *list.Element) {
	entry := position.Value.(*entry).listEntry
	delete(entry, ci)
	if len(entry) == 0 {
		l.frequencyList.Remove(position)
	}
}

// evict deletes the element from list with given linked list element
func (l *LFUNoTS) evict(e *list.Element) error {
	// ne need to return err if list element is already nil
	if e == nil {
		return nil
	}

	// remove the first item of the linked list
	for entry := range e.Value.(*entry).listEntry {
		l.cache.Delete(entry.k)
		l.remove(entry, e)
		l.currentSize--
		break
	}

	return nil
}

// newEntry creates a new entry with frequency count
func newEntry(freqCount int) *entry {
	return &entry{
		freqCount: freqCount,
		listEntry: make(map[*cacheItem]struct{}),
	}
}

// newCacheItem creates a new cache item with key and value
func newCacheItem(key string, value interface{}) *cacheItem {
	return &cacheItem{
		k: key,
		v: value,
	}

}
