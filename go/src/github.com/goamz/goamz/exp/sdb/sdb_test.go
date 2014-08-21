package sdb_test

import (
	"github.com/goamz/goamz/aws"
	"github.com/goamz/goamz/exp/sdb"
	"github.com/goamz/goamz/testutil"
	"github.com/motain/gocheck"
	"testing"
)

func Test(t *testing.T) {
	gocheck.TestingT(t)
}

var _ = gocheck.Suite(&S{})

type S struct {
	sdb *sdb.SDB
}

var testServer = testutil.NewHTTPServer()

func (s *S) SetUpSuite(c *gocheck.C) {
	testServer.Start()
	auth := aws.Auth{AccessKey: "abc", SecretKey: "123"}
	s.sdb = sdb.New(auth, aws.Region{SDBEndpoint: testServer.URL})
}

func (s *S) TearDownTest(c *gocheck.C) {
	testServer.Flush()
}

func (s *S) TestCreateDomainOK(c *gocheck.C) {
	testServer.Response(200, nil, TestCreateDomainXmlOK)

	domain := s.sdb.Domain("domain")
	resp, err := domain.CreateDomain()
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "63264005-7a5f-e01a-a224-395c63b89f6d")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0055590279)

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestListDomainsOK(c *gocheck.C) {
	testServer.Response(200, nil, TestListDomainsXmlOK)

	resp, err := s.sdb.ListDomains()
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "15fcaf55-9914-63c2-21f3-951e31193790")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000071759)
	c.Assert(resp.Domains, gocheck.DeepEquals, []string{"Account", "Domain", "Record"})

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestListDomainsWithNextTokenXmlOK(c *gocheck.C) {
	testServer.Response(200, nil, TestListDomainsWithNextTokenXmlOK)

	resp, err := s.sdb.ListDomains()
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "eb13162f-1b95-4511-8b12-489b86acfd28")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000219907)
	c.Assert(resp.Domains, gocheck.DeepEquals, []string{"Domain1-200706011651", "Domain2-200706011652"})
	c.Assert(resp.NextToken, gocheck.Equals, "TWV0ZXJpbmdUZXN0RG9tYWluMS0yMDA3MDYwMTE2NTY=")

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestDeleteDomainOK(c *gocheck.C) {
	testServer.Response(200, nil, TestDeleteDomainXmlOK)

	domain := s.sdb.Domain("domain")
	resp, err := domain.DeleteDomain()
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "039e1e25-9a64-2a74-93da-2fda36122a97")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0055590278)

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestPutAttrsOK(c *gocheck.C) {
	testServer.Response(200, nil, TestPutAttrsXmlOK)

	domain := s.sdb.Domain("MyDomain")
	item := domain.Item("Item123")

	putAttrs := new(sdb.PutAttrs)
	putAttrs.Add("FirstName", "john")
	putAttrs.Add("LastName", "smith")
	putAttrs.Replace("MiddleName", "jacob")

	putAttrs.IfValue("FirstName", "john")
	putAttrs.IfMissing("FirstName")

	resp, err := item.PutAttrs(putAttrs)
	req := testServer.WaitRequest()
	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"PutAttributes"})
	c.Assert(req.Form["ItemName"], gocheck.DeepEquals, []string{"Item123"})
	c.Assert(req.Form["DomainName"], gocheck.DeepEquals, []string{"MyDomain"})
	c.Assert(req.Form["Attribute.1.Name"], gocheck.DeepEquals, []string{"FirstName"})
	c.Assert(req.Form["Attribute.1.Value"], gocheck.DeepEquals, []string{"john"})
	c.Assert(req.Form["Attribute.2.Name"], gocheck.DeepEquals, []string{"LastName"})
	c.Assert(req.Form["Attribute.2.Value"], gocheck.DeepEquals, []string{"smith"})
	c.Assert(req.Form["Attribute.3.Name"], gocheck.DeepEquals, []string{"MiddleName"})
	c.Assert(req.Form["Attribute.3.Value"], gocheck.DeepEquals, []string{"jacob"})
	c.Assert(req.Form["Attribute.3.Replace"], gocheck.DeepEquals, []string{"true"})

	c.Assert(req.Form["Expected.1.Name"], gocheck.DeepEquals, []string{"FirstName"})
	c.Assert(req.Form["Expected.1.Value"], gocheck.DeepEquals, []string{"john"})
	c.Assert(req.Form["Expected.1.Exists"], gocheck.DeepEquals, []string{"false"})

	c.Assert(err, gocheck.IsNil)
	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "490206ce-8292-456c-a00f-61b335eb202b")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000219907)

}

func (s *S) TestAttrsOK(c *gocheck.C) {
	testServer.Response(200, nil, TestAttrsXmlOK)

	domain := s.sdb.Domain("MyDomain")
	item := domain.Item("Item123")

	resp, err := item.Attrs(nil, true)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"GetAttributes"})
	c.Assert(req.Form["ItemName"], gocheck.DeepEquals, []string{"Item123"})
	c.Assert(req.Form["DomainName"], gocheck.DeepEquals, []string{"MyDomain"})
	c.Assert(req.Form["ConsistentRead"], gocheck.DeepEquals, []string{"true"})

	c.Assert(resp.Attrs[0].Name, gocheck.Equals, "Color")
	c.Assert(resp.Attrs[0].Value, gocheck.Equals, "Blue")
	c.Assert(resp.Attrs[1].Name, gocheck.Equals, "Size")
	c.Assert(resp.Attrs[1].Value, gocheck.Equals, "Med")
	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "b1e8f1f7-42e9-494c-ad09-2674e557526d")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000219942)

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestAttrsSelectOK(c *gocheck.C) {
	testServer.Response(200, nil, TestAttrsXmlOK)

	domain := s.sdb.Domain("MyDomain")
	item := domain.Item("Item123")

	resp, err := item.Attrs([]string{"Color", "Size"}, true)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"GetAttributes"})
	c.Assert(req.Form["ItemName"], gocheck.DeepEquals, []string{"Item123"})
	c.Assert(req.Form["DomainName"], gocheck.DeepEquals, []string{"MyDomain"})
	c.Assert(req.Form["ConsistentRead"], gocheck.DeepEquals, []string{"true"})
	c.Assert(req.Form["AttributeName.1"], gocheck.DeepEquals, []string{"Color"})
	c.Assert(req.Form["AttributeName.2"], gocheck.DeepEquals, []string{"Size"})

	c.Assert(resp.Attrs[0].Name, gocheck.Equals, "Color")
	c.Assert(resp.Attrs[0].Value, gocheck.Equals, "Blue")
	c.Assert(resp.Attrs[1].Name, gocheck.Equals, "Size")
	c.Assert(resp.Attrs[1].Value, gocheck.Equals, "Med")
	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "b1e8f1f7-42e9-494c-ad09-2674e557526d")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000219942)

	c.Assert(err, gocheck.IsNil)
}

func (s *S) TestSelectOK(c *gocheck.C) {
	testServer.Response(200, nil, TestSelectXmlOK)

	resp, err := s.sdb.Select("select Color from MyDomain where Color like 'Blue%'", true)
	req := testServer.WaitRequest()

	c.Assert(req.Method, gocheck.Equals, "GET")
	c.Assert(req.URL.Path, gocheck.Equals, "/")
	c.Assert(req.Header["Date"], gocheck.Not(gocheck.Equals), "")
	c.Assert(req.Form["Action"], gocheck.DeepEquals, []string{"Select"})
	c.Assert(req.Form["ConsistentRead"], gocheck.DeepEquals, []string{"true"})

	c.Assert(resp.ResponseMetadata.RequestId, gocheck.Equals, "b1e8f1f7-42e9-494c-ad09-2674e557526d")
	c.Assert(resp.ResponseMetadata.BoxUsage, gocheck.Equals, 0.0000219907)
	c.Assert(len(resp.Items), gocheck.Equals, 2)
	c.Assert(resp.Items[0].Name, gocheck.Equals, "Item_03")
	c.Assert(resp.Items[1].Name, gocheck.Equals, "Item_06")
	c.Assert(resp.Items[0].Attrs[0].Name, gocheck.Equals, "Category")
	c.Assert(resp.Items[0].Attrs[0].Value, gocheck.Equals, "Clothes")

	c.Assert(err, gocheck.IsNil)
}
