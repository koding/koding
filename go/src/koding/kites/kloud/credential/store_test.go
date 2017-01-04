package credential_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/credential"
)

func TestFallbackFetcher(t *testing.T) {
	s1 := Creds{
		"cred1": "data1",
		"cred2": "data2",
	}

	s2 := Creds{
		"cred3": "data3",
		"cred4": "data4",
	}

	s := credential.NewFallbackFetcher(s1, s2)

	got := map[string]interface{}{
		"cred1": nil,
		"cred2": nil,
		"cred3": nil,
		"cred4": nil,
	}

	want := map[string]interface{}{
		"cred1": "data1",
		"cred2": "data2",
		"cred3": "data3",
		"cred4": "data4",
	}

	if err := s.Fetch("", got); err != nil {
		t.Fatalf("Fetch()=%s", err)
	}

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v; want %+v", got, want)
	}

	notfound := map[string]interface{}{
		"credX": nil,
	}

	err, ok := s.Fetch("", notfound).(*credential.NotFoundError)
	if !ok {
		t.Fatalf("expected err to be NotFoundError, was %T", err)
	}

	if len(err.Identifiers) != 1 || err.Identifiers[0] != "credX" {
		t.Fatalf(`expected err.Identifiers=["credX"]; got %v`, err.Identifiers)
	}
}

func TestTeeFetcher(t *testing.T) {
	f := Creds{
		"cred1": "data1",
		"cred2": "data2",
		"cred3": "data3",
	}

	p := Creds{}

	s := credential.TeeFetcher{
		Fetcher: f,
		Putter:  p,
	}

	got := map[string]interface{}{
		"cred1": nil,
		"cred2": nil,
		"cred3": nil,
	}

	if err := s.Fetch("", got); err != nil {
		t.Fatalf("Fetch()=%s", err)
	}

	if !reflect.DeepEqual(Creds(got), f) {
		t.Fatalf("got %+v; want %+v", got, f)
	}

	if !reflect.DeepEqual(p, f) {
		t.Fatalf("got %+v; want %+v", p, f)
	}
}

func TestMultiPutter(t *testing.T) {
	s1, s2 := Creds{}, Creds{}

	s := credential.NewMultiPutter(s1, s2)

	want := map[string]interface{}{
		"cred1": "data1",
		"cred2": "data2",
		"cred3": "data3",
	}

	if err := s.Put("", want); err != nil {
		t.Fatalf("Fetch()=%s", err)
	}

	if !reflect.DeepEqual(s1, Creds(want)) {
		t.Fatalf("got %+v; want %+v", s1, want)
	}

	if !reflect.DeepEqual(s2, Creds(want)) {
		t.Fatalf("got %+v; want %+v", s2, want)
	}
}

func TestMigratingStore(t *testing.T) {
	src := Creds{
		"cred1": "dataX",
		"cred2": "data2",
	}

	dst := Creds{
		"cred1": "data1",
		"cred3": "data3",
		"cred4": "data4",
	}

	s := credential.MigratingStore(src, dst)

	got := map[string]interface{}{
		"cred1": nil,
		"cred2": nil,
		"cred3": nil,
		"cred4": nil,
		"credX": nil,
	}

	want := map[string]interface{}{
		"cred1": "data1",
		"cred2": "data2",
		"cred3": "data3",
		"cred4": "data4",
		"credX": nil,
	}

	wantDst := Creds{
		"cred1": "data1",
		"cred2": "data2",
		"cred3": "data3",
		"cred4": "data4",
	}

	err, ok := s.Fetch("", got).(*credential.NotFoundError)
	if !ok {
		t.Fatalf("expected err to be NotFoundError, was %T", err)
	}

	if len(err.Identifiers) != 1 || err.Identifiers[0] != "credX" {
		t.Fatalf(`expected err.Identifiers=["credX"]; got %v`, err.Identifiers)
	}

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v; want %+v", got, want)
	}

	if !reflect.DeepEqual(dst, wantDst) {
		t.Fatalf("got %+v; want %+v", dst, wantDst)
	}
}

type Creds map[string]interface{}

var _ credential.Store = Creds(nil)

func (c Creds) Fetch(_ string, creds map[string]interface{}) error {
	var missing []string

	for ident := range creds {
		v, ok := c[ident]
		if !ok {
			missing = append(missing, ident)
			continue
		}

		creds[ident] = v
	}

	if len(missing) != 0 {
		return &credential.NotFoundError{
			Identifiers: missing,
		}
	}

	return nil
}

func (c Creds) Put(_ string, creds map[string]interface{}) error {
	for ident, data := range creds {
		c[ident] = data
	}

	return nil
}
