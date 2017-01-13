package algoliasearch

import "fmt"

type CreateObjectRes struct {
	CreatedAt string `json:"createdAt"`
	ObjectID  string `json:"objectID"`
	TaskID    int    `json:"taskID"`
}

type UpdateObjectRes struct {
	ObjectID  string `json:"objectID"`
	TaskID    int    `json:"taskID"`
	UpdatedAt string `json:"updatedAt"`
}

type objects struct {
	Results []Object `json:"results"`
}

type Object Map

func (o Object) ObjectID() (objectID string, err error) {
	i, ok := o["objectID"]
	if !ok {
		err = fmt.Errorf("Cannot extract `objectID` field from Object")
		return
	}

	if objectID, ok = i.(string); !ok {
		err = fmt.Errorf("Cannot cast `objectID` field to string type")
	}

	return
}
