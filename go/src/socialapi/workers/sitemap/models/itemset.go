package models

import (
	"encoding/xml"
	"fmt"
	"time"
)

// ItemSet corresponds to sitemap parent urlset element.
type ItemSet struct {
	XMLName     xml.Name          `xml:"http://www.sitemaps.org/schemas/sitemap/0.9 urlset,name"`
	Definitions []*ItemDefinition `xml:"url"`
}

func NewItemSet() *ItemSet {
	return &ItemSet{
		Definitions: make([]*ItemDefinition, 0),
	}
}

func (s *ItemSet) Populate(c *ItemContainer) {
	s.addItems(c)
	s.deleteItems(c)
	s.updateItems(c)
}

func (s *ItemSet) addItems(c *ItemContainer) {
	for _, v := range c.Add {
		s.Definitions = append(s.Definitions, v)
	}
}

func (s *ItemSet) updateItems(c *ItemContainer) {
	// for preventing iteration of current items for each updated element
	// first we store current item pointers in a map with their unique slugs
	itemMap := make(map[string]*ItemDefinition)
	for _, v := range s.Definitions {
		itemMap[v.Location] = v
	}

	// then while iterating the updated items, we are fetching related item
	// from map and updating it
	for _, v := range c.Update {
		currentDefinition, ok := itemMap[v.Location]
		if !ok {
			// TODO log this
			fmt.Println("item does not exist")
			continue
		}
		currentDefinition.LastModified = time.Now().UTC().Format(time.RFC3339)
	}
}

func (s *ItemSet) deleteItems(c *ItemContainer) {
	itemMap := make(map[string]int)
	// first we store item pointers in a map with their indexes
	for i, v := range s.Definitions {
		itemMap[v.Location] = i
	}

	// then while iterationg the deleted items, we are deleting the related
	// item from existing item definitions
	for _, v := range c.Delete {
		_, ok := itemMap[v.Location]
		if !ok {
			// TODO log this
			fmt.Println("item does not exist")
			continue
		}

		// TODO it looks like it sucks in performance
		removedIndex := itemMap[v.Location]
		temp := s.Definitions
		temp = append(temp[:removedIndex], temp[removedIndex+1:]...)
		s.Definitions = temp
	}
}
