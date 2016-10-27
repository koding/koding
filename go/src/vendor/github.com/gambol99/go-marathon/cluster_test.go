/*
Copyright 2014 Rohith All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package marathon

import (
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestUrl(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURL)
	assert.Equal(t, cluster.URL(), fakeMarathonURL)
}

func TestSize(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURL)
	assert.Equal(t, cluster.Size(), 3)
}

func TestActive(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURL)
	assert.Equal(t, len(cluster.Active()), 3)
}

func TestNonActive(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURL)
	assert.Equal(t, len(cluster.NonActive()), 0)
}

func TestGetMember(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURL)
	member, err := cluster.GetMember()
	assert.NoError(t, err)
	assert.Equal(t, member, "http://127.0.0.1:3000")
}

func TestGetMemberWithPath(t *testing.T) {
	cluster, _ := newCluster(http.DefaultClient, fakeMarathonURLWithPath)
	member, err := cluster.GetMember()
	assert.NoError(t, err)
	assert.Equal(t, member, "http://127.0.0.1:3000/path")
}

func TestMarkDown(t *testing.T) {
	endpoint := newFakeMarathonEndpoint(t, nil)
	defer endpoint.Close()

	cluster, _ := newCluster(http.DefaultClient, endpoint.URL)
	assert.Equal(t, len(cluster.Active()), 3)
	cluster.MarkDown()
	cluster.MarkDown()
	assert.Equal(t, len(cluster.Active()), 1)
	time.Sleep(10 * time.Millisecond)
	assert.Equal(t, len(cluster.Active()), 3)
}

func TestInvalidHosts(t *testing.T) {
	for _, invalidHost := range []string{
		"",
		"://",
		"http://",
		"http://,,",
		"http://,127.0.0.1:3000,127.0.0.1:3000",
		"http://127.0.0.1:3000,,127.0.0.1:3000",
		"http://127.0.0.1:3000,127.0.0.1:3000,",
		"foo://127.0.0.1:3000",
	} {
		_, err := newCluster(http.DefaultClient, invalidHost)
		assert.Equal(t, err, ErrInvalidEndpoint, "undetected invalid host: %s", invalidHost)
	}
}
