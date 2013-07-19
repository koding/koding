package main

import (
	"encoding/json"
	"fmt"
	"koding/testtool/chromr"
	"strings"
	"time"
)

type Document struct {
	Tab           *chromr.ChromeTab
	Nodes         map[int]*Node
	Root          *Node
	NodeListeners []func(*Node)
}

type Node struct {
	NodeId     int
	NodeType   int
	NodeName   string
	LocalName  string
	NodeValue  string
	Children   []*Node
	Attributes []string

	doc     *Document
	attrMap map[string]string
	obj     *RemoteObject
}

type RemoteObject struct {
	ObjectId    string
	Type        string
	Subtype     string
	ClassName   string
	Description string
}

type CallArgument struct {
	Value    interface{} `json:"value,omitempty"`
	ObjectId string      `json:"objectId,omitempty"`
}

var startTime time.Time
var tab *chromr.ChromeTab

func main() {
	tabs, err := chromr.GetTabs("localhost:9222")
	if err != nil {
		panic(err)
	}
	tab = tabs[0]
	tab.Connect()

	doc := Document{
		Tab:   tab,
		Nodes: make(map[int]*Node),
	}
	tab.Command("DOM.getDocument", nil, &doc)
	// doc.AddNode(doc.Root)
	// tab.Command("Page.navigate", chromr.P{"url": "https://koding.com/Activity"}, nil)
	tab.Command("Page.reload", nil, nil)
	startTime = time.Now()

	// doc.Root.FindNode(func(n *Node) { strings.Contains(n.attrMap["class"], "activity-item") })
	// fmt.Println(time.Now().Sub(startTime))

	inviteButton := doc.WaitForNode(func(n *Node) bool {
		return n.attrMap["href"] == "/Join" && strings.Contains(n.attrMap["class"], "green")
	})
	inviteButton.Click()

	nameInput := doc.WaitForNode(func(n *Node) bool {
		return n.attrMap["placeholder"] == "Enter your email address"
	})
	nameInput.SetProperty("value", "mail@richard-musiol.de")
}

func (doc *Document) ProcessNotification() {
	notification := <-tab.NotificationChan
	switch notification.Method {
	case "DOM.documentUpdated":
		doc.Nodes = make(map[int]*Node)
		tab.Command("DOM.getDocument", nil, &doc)
		doc.AddNode(doc.Root)

	case "DOM.setChildNodes":
		var params struct {
			ParentId int
			Nodes    []*Node
		}
		if err := json.Unmarshal(notification.Params, &params); err != nil {
			panic(err)
		}
		doc.Nodes[params.ParentId].Children = params.Nodes
		for _, n := range params.Nodes {
			doc.AddNode(n)
		}

	case "DOM.childNodeInserted":
		var params struct {
			ParentNodeId   int
			PreviousNodeId int
			Node           *Node
		}
		if err := json.Unmarshal(notification.Params, &params); err != nil {
			panic(err)
		}
		parent := doc.Nodes[params.ParentNodeId]
		index := 0
		for i, n := range parent.Children {
			if n.NodeId == params.PreviousNodeId {
				index = i + 1
				break
			}
		}
		parent.Children = append(append(parent.Children[:index], params.Node), parent.Children[index:]...)
		doc.AddNode(params.Node)

	case "DOM.childNodeRemoved":
	case "DOM.childNodeCountUpdated":
	case "DOM.attributeModified":
		// fmt.Println(string(notification.Params))
	case "DOM.attributeRemoved":
	case "DOM.characterDataModified":
	case "DOM.inlineStyleInvalidated":
	case "CSS.styleSheetAdded":
	case "CSS.styleSheetRemoved":
	default:
		fmt.Println(notification.Method)
	}
}

func (doc *Document) AddNode(n *Node) {
	n.attrMap = make(map[string]string)
	for i := 0; i < len(n.Attributes); i += 2 {
		n.attrMap[n.Attributes[i]] = n.Attributes[i+1]
	}
	n.doc = doc
	doc.Nodes[n.NodeId] = n

	if n.attrMap["placeholder"] == "Enter your email address" {
		fmt.Println("received element")
	}

	for _, listener := range doc.NodeListeners {
		listener(n)
	}

	if n.Children != nil {
		for _, c := range n.Children {
			doc.AddNode(c)
		}
		return
	}

	doc.Tab.Command("DOM.requestChildNodes", chromr.P{"nodeId": n.NodeId}, nil)
}

func (doc *Document) Evaluate(expr string) *RemoteObject {
	var ret struct {
		Result    *RemoteObject
		WasThrown bool
	}
	doc.Tab.Command("Runtime.evaluate", chromr.P{"expression": expr}, &ret)
	if ret.WasThrown {
		panic(ret.Result.Description)
	}
	return ret.Result
}

func (d *Document) WaitForNode(filter func(*Node) bool) *Node {
	result := d.Root.FindNode(filter)
	if result != nil {
		fmt.Println("found immediately")
		return result
	}

	listener := func(changedNode *Node) {
		if filter(changedNode) {
			fmt.Println("found later")
			result = changedNode
		}
	}
	d.NodeListeners = append(d.NodeListeners, listener)
	for result == nil {
		d.ProcessNotification()
	}
	d.NodeListeners = nil
	return result
}

func (n *Node) FindNode(filter func(*Node) bool) *Node {
	if filter(n) {
		return n
	}
	for _, c := range n.Children {
		result := c.FindNode(filter)
		if result != nil {
			return result
		}
	}
	return nil
}

func (n *Node) SetAttribute(name string, value interface{}) {
	n.doc.Tab.Command("DOM.setAttributeValue", chromr.P{"nodeId": n.NodeId, "name": name, "value": value}, nil)
}

func (n *Node) GetObject() *RemoteObject {
	if n.obj == nil {
		realId := n.attrMap["id"]
		n.SetAttribute("id", "chromrLookup")
		n.obj = n.doc.Evaluate("document.getElementById('chromrLookup')")
		n.SetAttribute("id", realId)
	}
	return n.obj
}

func (n *Node) Call(function string, arguments ...interface{}) {
	callArgs := make([]CallArgument, len(arguments))
	for i, a := range arguments {
		switch arg := a.(type) {
		case *RemoteObject:
			callArgs[i] = CallArgument{ObjectId: arg.ObjectId}
		default:
			callArgs[i] = CallArgument{Value: arg}
		}
	}
	n.doc.Tab.Command("Runtime.callFunctionOn", chromr.P{
		"objectId":            n.GetObject().ObjectId,
		"functionDeclaration": function,
		"arguments":           callArgs,
	}, nil)
}

func (n *Node) SetProperty(name string, value interface{}) {
	n.Call("function(name, value) { this[name] = value }", name, value)
}

func (n *Node) Click() {
	event := n.doc.Evaluate("var e = document.createEvent('HTMLEvents'); e.initEvent('click', true, true); e")
	n.Call("Element.prototype.dispatchEvent", event)
}
