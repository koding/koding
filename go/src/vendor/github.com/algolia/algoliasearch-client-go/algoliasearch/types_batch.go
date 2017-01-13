package algoliasearch

import "errors"

type BatchOperation struct {
	Action string      `json:"action"`
	Body   interface{} `json:"body,omitempty"`
}

type BatchOperationIndexed struct {
	BatchOperation
	IndexName string `json:"indexName"`
}

type BatchRes struct {
	ObjectIDs []string `json:"objectIDs"`
	TaskID    int      `json:"taskID"`
}

type MultipleBatchRes struct {
	ObjectIDs []string       `json:"objectIDs"`
	TaskID    map[string]int `json:"taskID"`
}

func newBatchOperations(objects []Object, action string) (operations []BatchOperation, err error) {
	operations = make([]BatchOperation, len(objects))

	for i, o := range objects {
		// In the case of something else than `addObject` and `clear` operations,
		// the `objectID` field is required and has to be escaped.
		if action != "addObject" && action != "clear" {
			if objectID, err := o.ObjectID(); err == nil {
				o["objectID"] = objectID
			} else {
				err = errors.New("Cannot generate []BatchOperation: `objectID` field is missing")
				break
			}
		}

		operations[i].Action = action
		operations[i].Body = o
	}

	return
}
