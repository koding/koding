package models

import "encoding/xml"

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

func (s *ItemSet) deleteItems(c *ItemContainer) {

}

func (s *ItemSet) updateItems(c *ItemContainer) {

}
