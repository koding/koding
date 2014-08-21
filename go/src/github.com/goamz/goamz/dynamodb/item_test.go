package dynamodb_test

import (
	"github.com/goamz/goamz/dynamodb"
	"github.com/motain/gocheck"
)

type ItemSuite struct {
	TableDescriptionT dynamodb.TableDescriptionT
	DynamoDBTest
	WithRange bool
}

func (s *ItemSuite) SetUpSuite(c *gocheck.C) {
	setUpAuth(c)
	s.DynamoDBTest.TableDescriptionT = s.TableDescriptionT
	s.server = &dynamodb.Server{dynamodb_auth, dynamodb_region}
	pk, err := s.TableDescriptionT.BuildPrimaryKey()
	if err != nil {
		c.Skip(err.Error())
	}
	s.table = s.server.NewTable(s.TableDescriptionT.TableName, pk)

	// Cleanup
	s.TearDownSuite(c)
	_, err = s.server.CreateTable(s.TableDescriptionT)
	if err != nil {
		c.Fatal(err)
	}
	s.WaitUntilStatus(c, "ACTIVE")
}

var item_suite = &ItemSuite{
	TableDescriptionT: dynamodb.TableDescriptionT{
		TableName: "DynamoDBTestMyTable",
		AttributeDefinitions: []dynamodb.AttributeDefinitionT{
			dynamodb.AttributeDefinitionT{"TestHashKey", "S"},
			dynamodb.AttributeDefinitionT{"TestRangeKey", "N"},
		},
		KeySchema: []dynamodb.KeySchemaT{
			dynamodb.KeySchemaT{"TestHashKey", "HASH"},
			dynamodb.KeySchemaT{"TestRangeKey", "RANGE"},
		},
		ProvisionedThroughput: dynamodb.ProvisionedThroughputT{
			ReadCapacityUnits:  1,
			WriteCapacityUnits: 1,
		},
	},
	WithRange: true,
}

var item_without_range_suite = &ItemSuite{
	TableDescriptionT: dynamodb.TableDescriptionT{
		TableName: "DynamoDBTestMyTable",
		AttributeDefinitions: []dynamodb.AttributeDefinitionT{
			dynamodb.AttributeDefinitionT{"TestHashKey", "S"},
		},
		KeySchema: []dynamodb.KeySchemaT{
			dynamodb.KeySchemaT{"TestHashKey", "HASH"},
		},
		ProvisionedThroughput: dynamodb.ProvisionedThroughputT{
			ReadCapacityUnits:  1,
			WriteCapacityUnits: 1,
		},
	},
	WithRange: false,
}

var _ = gocheck.Suite(item_suite)
var _ = gocheck.Suite(item_without_range_suite)

func (s *ItemSuite) TestConditionalPutUpdateDeleteItem(c *gocheck.C) {
	if s.WithRange {
		// No rangekey test required
		return
	}

	attrs := []dynamodb.Attribute{
		*dynamodb.NewStringAttribute("Attr1", "Attr1Val"),
	}
	pk := &dynamodb.Key{HashKey: "NewHashKeyVal"}

	// Put
	if ok, err := s.table.PutItem("NewHashKeyVal", "", attrs); !ok {
		c.Fatal(err)
	}

	{
		// Put with condition failed
		expected := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "expectedAttr1Val").SetExists(true),
			*dynamodb.NewStringAttribute("AttrNotExists", "").SetExists(false),
		}
		if ok, err := s.table.ConditionalPutItem("NewHashKeyVal", "", attrs, expected); ok {
			c.Errorf("Expect condition does not meet.")
		} else {
			c.Check(err.Error(), gocheck.Matches, "ConditionalCheckFailedException.*")
		}

		// Add attributes with condition failed
		if ok, err := s.table.ConditionalAddAttributes(pk, attrs, expected); ok {
			c.Errorf("Expect condition does not meet.")
		} else {
			c.Check(err.Error(), gocheck.Matches, "ConditionalCheckFailedException.*")
		}

		// Update attributes with condition failed
		if ok, err := s.table.ConditionalUpdateAttributes(pk, attrs, expected); ok {
			c.Errorf("Expect condition does not meet.")
		} else {
			c.Check(err.Error(), gocheck.Matches, "ConditionalCheckFailedException.*")
		}

		// Delete attributes with condition failed
		if ok, err := s.table.ConditionalDeleteAttributes(pk, attrs, expected); ok {
			c.Errorf("Expect condition does not meet.")
		} else {
			c.Check(err.Error(), gocheck.Matches, "ConditionalCheckFailedException.*")
		}
	}

	{
		expected := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "Attr1Val").SetExists(true),
		}

		// Add attributes with condition met
		addNewAttrs := []dynamodb.Attribute{
			*dynamodb.NewNumericAttribute("AddNewAttr1", "10"),
			*dynamodb.NewNumericAttribute("AddNewAttr2", "20"),
		}
		if ok, err := s.table.ConditionalAddAttributes(pk, addNewAttrs, nil); !ok {
			c.Errorf("Expect condition met. %s", err)
		}

		// Update attributes with condition met
		updateAttrs := []dynamodb.Attribute{
			*dynamodb.NewNumericAttribute("AddNewAttr1", "100"),
		}
		if ok, err := s.table.ConditionalUpdateAttributes(pk, updateAttrs, expected); !ok {
			c.Errorf("Expect condition met. %s", err)
		}

		// Delete attributes with condition met
		deleteAttrs := []dynamodb.Attribute{
			*dynamodb.NewNumericAttribute("AddNewAttr2", ""),
		}
		if ok, err := s.table.ConditionalDeleteAttributes(pk, deleteAttrs, expected); !ok {
			c.Errorf("Expect condition met. %s", err)
		}

		// Get to verify operations that condition are met
		item, err := s.table.GetItem(pk)
		if err != nil {
			c.Fatal(err)
		}

		if val, ok := item["AddNewAttr1"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewNumericAttribute("AddNewAttr1", "100"))
		} else {
			c.Error("Expect AddNewAttr1 attribute to be added and updated")
		}

		if _, ok := item["AddNewAttr2"]; ok {
			c.Error("Expect AddNewAttr2 attribute to be deleted")
		}
	}

	{
		// Put with condition met
		expected := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "Attr1Val").SetExists(true),
		}
		newattrs := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "Attr2Val"),
		}
		if ok, err := s.table.ConditionalPutItem("NewHashKeyVal", "", newattrs, expected); !ok {
			c.Errorf("Expect condition met. %s", err)
		}

		// Get to verify Put operation that condition are met
		item, err := s.table.GetItem(pk)
		if err != nil {
			c.Fatal(err)
		}

		if val, ok := item["Attr1"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewStringAttribute("Attr1", "Attr2Val"))
		} else {
			c.Error("Expect Attr1 attribute to be updated")
		}
	}

	{
		// Delete with condition failed
		expected := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "expectedAttr1Val").SetExists(true),
		}
		if ok, err := s.table.ConditionalDeleteItem(pk, expected); ok {
			c.Errorf("Expect condition does not meet.")
		} else {
			c.Check(err.Error(), gocheck.Matches, "ConditionalCheckFailedException.*")
		}
	}

	{
		// Delete with condition met
		expected := []dynamodb.Attribute{
			*dynamodb.NewStringAttribute("Attr1", "Attr2Val").SetExists(true),
		}
		if ok, _ := s.table.ConditionalDeleteItem(pk, expected); !ok {
			c.Errorf("Expect condition met.")
		}

		// Get to verify Delete operation
		_, err := s.table.GetItem(pk)
		c.Check(err.Error(), gocheck.Matches, "Item not found")
	}
}

func (s *ItemSuite) TestPutGetDeleteItem(c *gocheck.C) {
	attrs := []dynamodb.Attribute{
		*dynamodb.NewStringAttribute("Attr1", "Attr1Val"),
	}

	var rk string
	if s.WithRange {
		rk = "1"
	}

	// Put
	if ok, err := s.table.PutItem("NewHashKeyVal", rk, attrs); !ok {
		c.Fatal(err)
	}

	// Get to verify Put operation
	pk := &dynamodb.Key{HashKey: "NewHashKeyVal", RangeKey: rk}
	item, err := s.table.GetItem(pk)
	if err != nil {
		c.Fatal(err)
	}

	if val, ok := item["TestHashKey"]; ok {
		c.Check(val, gocheck.DeepEquals, dynamodb.NewStringAttribute("TestHashKey", "NewHashKeyVal"))
	} else {
		c.Error("Expect TestHashKey to be found")
	}

	if s.WithRange {
		if val, ok := item["TestRangeKey"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewNumericAttribute("TestRangeKey", "1"))
		} else {
			c.Error("Expect TestRangeKey to be found")
		}
	}

	// Delete
	if ok, _ := s.table.DeleteItem(pk); !ok {
		c.Fatal(err)
	}

	// Get to verify Delete operation
	_, err = s.table.GetItem(pk)
	c.Check(err.Error(), gocheck.Matches, "Item not found")
}

func (s *ItemSuite) TestUpdateItem(c *gocheck.C) {
	attrs := []dynamodb.Attribute{
		*dynamodb.NewNumericAttribute("count", "0"),
	}

	var rk string
	if s.WithRange {
		rk = "1"
	}

	if ok, err := s.table.PutItem("NewHashKeyVal", rk, attrs); !ok {
		c.Fatal(err)
	}

	// UpdateItem with Add
	attrs = []dynamodb.Attribute{
		*dynamodb.NewNumericAttribute("count", "10"),
	}
	pk := &dynamodb.Key{HashKey: "NewHashKeyVal", RangeKey: rk}
	if ok, err := s.table.AddAttributes(pk, attrs); !ok {
		c.Error(err)
	}

	// Get to verify Add operation
	if item, err := s.table.GetItemConsistent(pk, true); err != nil {
		c.Error(err)
	} else {
		if val, ok := item["count"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewNumericAttribute("count", "10"))
		} else {
			c.Error("Expect count to be found")
		}
	}

	// UpdateItem with Put
	attrs = []dynamodb.Attribute{
		*dynamodb.NewNumericAttribute("count", "100"),
	}
	if ok, err := s.table.UpdateAttributes(pk, attrs); !ok {
		c.Error(err)
	}

	// Get to verify Put operation
	if item, err := s.table.GetItem(pk); err != nil {
		c.Fatal(err)
	} else {
		if val, ok := item["count"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewNumericAttribute("count", "100"))
		} else {
			c.Error("Expect count to be found")
		}
	}

	// UpdateItem with Delete
	attrs = []dynamodb.Attribute{
		*dynamodb.NewNumericAttribute("count", ""),
	}
	if ok, err := s.table.DeleteAttributes(pk, attrs); !ok {
		c.Error(err)
	}

	// Get to verify Delete operation
	if item, err := s.table.GetItem(pk); err != nil {
		c.Error(err)
	} else {
		if _, ok := item["count"]; ok {
			c.Error("Expect count not to be found")
		}
	}
}

func (s *ItemSuite) TestUpdateItemWithSet(c *gocheck.C) {
	attrs := []dynamodb.Attribute{
		*dynamodb.NewStringSetAttribute("list", []string{"A", "B"}),
	}

	var rk string
	if s.WithRange {
		rk = "1"
	}

	if ok, err := s.table.PutItem("NewHashKeyVal", rk, attrs); !ok {
		c.Error(err)
	}

	// UpdateItem with Add
	attrs = []dynamodb.Attribute{
		*dynamodb.NewStringSetAttribute("list", []string{"C"}),
	}
	pk := &dynamodb.Key{HashKey: "NewHashKeyVal", RangeKey: rk}
	if ok, err := s.table.AddAttributes(pk, attrs); !ok {
		c.Error(err)
	}

	// Get to verify Add operation
	if item, err := s.table.GetItem(pk); err != nil {
		c.Error(err)
	} else {
		if val, ok := item["list"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewStringSetAttribute("list", []string{"A", "B", "C"}))
		} else {
			c.Error("Expect count to be found")
		}
	}

	// UpdateItem with Delete
	attrs = []dynamodb.Attribute{
		*dynamodb.NewStringSetAttribute("list", []string{"A"}),
	}
	if ok, err := s.table.DeleteAttributes(pk, attrs); !ok {
		c.Error(err)
	}

	// Get to verify Delete operation
	if item, err := s.table.GetItem(pk); err != nil {
		c.Error(err)
	} else {
		if val, ok := item["list"]; ok {
			c.Check(val, gocheck.DeepEquals, dynamodb.NewStringSetAttribute("list", []string{"B", "C"}))
		} else {
			c.Error("Expect list to be remained")
		}
	}
}
