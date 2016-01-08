package sl_test

import (
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	"koding/kites/kloud/api/sl"
)

func TestKeys(t *testing.T) {
	pem := os.Getenv("KLOUD_USER_PRIVATEKEY")
	if pem == "" {
		t.Skip("skipping, KLOUD_USER_PRIVATEKEY is empty")
	}
	c := sl.NewSoftlayerWithOptions(opts)
	key, err := sl.ParseKey(pem)
	if err != nil {
		t.Fatalf("NewKey(%q)=%s", pem, err)
	}
	key.Label = fmt.Sprintf("test-%s-%d", key.Label, time.Now().UnixNano())
	newKey, err := c.CreateKey(key)
	if err != nil {
		t.Fatalf("CreateKey(%+v)=%s", key, err)
	}
	defer func() {
		if err := c.DeleteKey(newKey.ID); err != nil {
			t.Error(err)
		}
	}()
	if newKey.ID == 0 {
		t.Error("want key.ID != 0")
	}
	if newKey.Fingerprint != key.Fingerprint {
		t.Errorf("want fingerprint=%q; got %q", key.Fingerprint, newKey.Fingerprint)
	}
	if newKey.CreateDate.IsZero() {
		t.Errorf("want %v to be actual date", newKey.CreateDate)
	}
	f := &sl.Filter{
		Label: key.Label,
	}
	d := time.Now()
	keys, err := c.KeysByFilter(f)
	if err != nil {
		t.Fatal(err)
	}
	reqDur := time.Now().Sub(d)
	d = time.Now()
	xkeys, err := c.XKeysByFilter(f)
	if err != nil {
		t.Fatal(err)
	}
	xreqDur := time.Now().Sub(d)
	t.Logf("[TEST] filtering took: client-side=%s, server-side=%s", reqDur, xreqDur)
	if len(keys) != 1 {
		t.Errorf("want len(keys)=1; got %d", len(keys))
	}
	if len(xkeys) != 1 {
		t.Errorf("want len(xkeys)=1; got %d", len(keys))
	}
	if !reflect.DeepEqual(keys[0], newKey) {
		t.Errorf("want key=%+v; got %+v", newKey, keys[0])
	}
	if !reflect.DeepEqual(xkeys[0], newKey) {
		t.Errorf("want key=%+v; got %+v", newKey, xkeys[0])
	}
}
