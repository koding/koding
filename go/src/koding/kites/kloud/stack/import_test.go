package stack_test

import (
	"strings"
	"testing"

	"koding/api/apitest"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/stacktest"
	"koding/remoteapi/models"
)

func TestImport(t *testing.T) {
	remoteapi := &apitest.StubHandler{
		map[string]*models.JStackTemplate{"data": {ID: "mocked-template-id"}},
		nil,
		map[string]map[string]*models.JComputeStack{"data": {"stack": {ID: "mocked-stack-id"}}},
	}

	s := apitest.Serve(remoteapi)
	defer s.Close()

	fk := stacktest.NewFakeKloud(s.URL)

	req := &stack.ImportRequest{
		Credentials: map[string][]string{"test": {"mocked-identifier"}},
		Template:    []byte(`{"provider":{"test":{}}}`),
		Team:        "test-team",
	}

	resp, err := fk.Import(stacktest.NewRequest("import", "test-user", req))
	if err != nil {
		t.Fatalf("Import()=%s", err)
	}

	got, ok := resp.(*stack.ImportResponse)
	if !ok {
		t.Fatalf("got %T, want %T", resp, (*stack.ImportResponse)(nil))
	}

	if !strings.HasSuffix(got.Title, "TEST Stack") {
		t.Fatalf("got %q, want suffix %q", got.Title, "TEST Stack")
	}

	got.Title = ""

	want := &stack.ImportResponse{
		TemplateID: "mocked-template-id",
		StackID:    "mocked-stack-id",
		EventID:    "mocked-event-id",
	}

	if *got != *want {
		t.Fatalf("got %#v, want %#v", got, want)
	}
}
