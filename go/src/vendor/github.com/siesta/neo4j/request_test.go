// +build graphity

package neo4j

import "testing"

func TestCreateAndDeleteEvents(t *testing.T) {
	sourceID, eventID := createNodes("source", "event", t)

	req := &ManuelRequest{
		Method: "POST",
		To:     "http://localhost:7474/graphity/events",
		Body: map[string]string{
			"source": sourceId,
			"event":  eventId,
		},
	}

	err := req.Post()
	if err != nil {
		t.Error(err)
	}

	req = &ManuelRequest{
		Method: "DELETE",
		To:     "http://localhost:7474/graphity/events",
		Body: map[string]string{
			"source": sourceId,
			"event":  eventId,
		},
	}

	err = req.Post()
	if err != nil {
		t.Error(err)
	}
}

func TestCreateAndDeleteSubscriptions(t *testing.T) {
	streamID, sourceID := createNodes("stream", "source", t)

	req := &ManuelRequest{
		Method: "POST",
		To:     "http://localhost:7474/graphity/subscriptions",
		Body: map[string]string{
			"stream": streamID,
			"source": sourceID,
		},
	}

	err := req.Post()
	if err != nil {
		t.Error(err)
	}

	req = &ManuelRequest{
		Method: "DELETE",
		To:     "http://localhost:7474/graphity/subscriptions",
		Body: map[string]string{
			"stream": streamID,
			"source": sourceID,
		},
	}

	err = req.Post()
	if err != nil {
		t.Error(err)
	}
}

func TestGetEvents(t *testing.T) {
	streamID, sourceID := createNodes("stream", "source", t)

	req := &ManuelRequest{
		Method: "POST",
		To:     "http://localhost:7474/graphity/subscriptions",
		Body: map[string]string{
			"stream": streamID,
			"source": sourceID,
		},
	}

	err := req.Post()
	if err != nil {
		t.Error(err)
	}

	_, eventID := createNodes("_", "event", t)

	req = &ManuelRequest{
		Method: "POST",
		To:     "http://localhost:7474/graphity/events",
		Body: map[string]string{
			"source":    sourceID,
			"event":     eventID,
			"timestamp": "1",
		},
	}

	err = req.Post()
	if err != nil {
		t.Error(err)
	}

	_, eventId = createNodes("_", "event", t)

	req = &ManuelRequest{
		Method: "POST",
		To:     "http://localhost:7474/graphity/events",
		Body: map[string]string{
			"source":    sourceID,
			"event":     eventID,
			"timestamp": "2",
		},
	}

	err = req.Post()
	if err != nil {
		t.Error(err)
	}

	req = &ManuelRequest{
		Method: "GET",
		To:     "http://localhost:7474/graphity/events",
		Params: map[string]string{
			"stream": streamId,
			"count":  "10",
		},
	}

	nodeIds, err := req.Get()
	if err != nil {
		t.Error(err)
	}

	if len(nodeIds) < 2 {
		t.Error("not enough results")
	}
}

func createNodes(nodeOneName, nodeTwoName string, t *testing.T) (nodeOneID, nodeTwoID string) {
	nodeOne := &Node{
		Data: map[string]interface{}{"name": nodeOneName},
	}

	nodeTwo := &Node{
		Data: map[string]interface{}{"name": nodeTwoName},
	}

	batch := Connect("").NewBatch()
	_, err := batch.Create(nodeOne).
		Create(nodeTwo).
		Execute()

	if err != nil {
		t.Error(err)
	}

	return nodeOne.Payload.Self, nodeTwo.Payload.Self
}
