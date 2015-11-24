package amazon_test

import (
	"koding/kites/kloud/api/amazon"
	"net/url"
	"reflect"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

func TestTagMatch(t *testing.T) {
	tags := []*ec2.Tag{
		{Key: aws.String("key1"), Value: aws.String("value1")},
		{Key: aws.String("key2"), Value: aws.String("value2")},
		{Key: aws.String("key3"), Value: aws.String("value3")},
	}
	cases := []struct {
		m  map[string]string
		ok bool
	}{{
		map[string]string{"key2": "value2", "key3": "value3"},
		true,
	}, {
		map[string]string{"key4": "value4"},
		false,
	}, {
		map[string]string{"key3": "value3", "key2": "different"},
		false,
	}}
	for i, cas := range cases {
		ok := amazon.TagsMatch(tags, cas.m)
		if ok != cas.ok {
			t.Errorf("%d: want ok=%v; got %v", i, cas.ok, ok)
		}
	}
}

func TestNewFilters(t *testing.T) {
	filters := []*ec2.Filter{{
		Name: aws.String("filter 1"),
		Values: []*string{
			aws.String("value 11"),
		},
	}, {
		Name: aws.String("filter 2"),
		Values: []*string{
			aws.String("value 21"),
			aws.String("value 22"),
		},
	}}
	cases := []url.Values{{
		"filter 1": {"value 11"},
		"filter 2": {"value 21", "value 22"},
	}, {
		"filter 1": {"", "value 11", ""},
		"filter 2": {"", "value 21", "", "value 22"},
	}, {
		"filter 1": {"value 11"},
		"filter 2": {"value 21", "value 22"},
		"empty 3":  {""},
		"empty 4":  {"", "", ""},
	}}
	for i, cas := range cases {
		f := amazon.NewFilters(cas)
		if !reflect.DeepEqual(filters, f) {
			t.Errorf("%d: want f=%#v; got %#v", i, filters, f)
		}
	}
}
