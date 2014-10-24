package main

type Outputter struct {
	OnItem  chan *Item
	OnError chan error
}

type Item struct {
	Name string
	Data interface{}
}
