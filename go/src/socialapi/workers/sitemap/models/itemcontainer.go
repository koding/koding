package models

// ItemContainer used for grouping sitemap feed items
type ItemContainer struct {
	Add    []*ItemDefinition
	Update []*ItemDefinition
	Delete []*ItemDefinition
}

func NewItemContainer() *ItemContainer {
	return &ItemContainer{
		Add:    make([]*ItemDefinition, 0),
		Update: make([]*ItemDefinition, 0),
		Delete: make([]*ItemDefinition, 0),
	}
}
