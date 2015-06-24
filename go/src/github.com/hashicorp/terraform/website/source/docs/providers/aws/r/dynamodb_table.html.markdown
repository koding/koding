---
layout: "aws"
page_title: "AWS: dynamodb_table"
sidebar_current: "docs-aws-resource-dynamodb-table"
description: |-
  Provides a DynamoDB table resource
---

# aws\_dynamodb\_table

Provides a DynamoDB table resource

## Example Usage

The following dynamodb table description models the table and GSI shown
in the [AWS SDK example documentation](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html)

```
resource "aws_dynamodb_table" "basic-dynamodb-table" {
    name = "GameScores"
    read_capacity = 20
    write_capacity = 20
    hash_key = "UserId"
    range_key = "GameTitle"
    attribute {
      name = "Username"
      type = "S"
    }
    attribute {
      name = "GameTitle"
      type = "S"
    }
    attribute {
      name = "TopScore"
      type = "N"
    }
    attribute {
      name = "TopScoreDateTime"
      type = "S"
    }
    attribute {
      name = "Wins"
      type = "N"
    } 
    attribute {
      name = "Losses"
      type = "N"
    }
    global_secondary_index {
      name = "GameTitleIndex"
      hash_key = "GameTitle"
      range_key = "TopScore"
      write_capacity = 10
      read_capacity = 10
      projection_type = "INCLUDE"
      non_key_attributes = [ "UserId" ]
    }
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) The name of the table, this needs to be unique
  within a region.
* `read_capacity` - (Required) The number of read units for this table
* `write_capacity` - (Required) The number of write units for this table
* `hash_key` - (Required) The attribute to use as the hash key (the
  attribute must also be defined as an attribute record
* `range_key` - (Optional) The attribute to use as the range key (must
  also be defined)
* `attribute` - Define an attribute, has two properties:
  * `name` - The name of the attribute
  * `type` - One of: S, N, or B for (S)tring, (N)umber or (B)inary data
* `local_secondary_index` - (Optional) Describe an LSI on the table;
  these can only be allocated *at creation* so you cannot change this
definition after you have created the resource. 
* `global_secondary_index` - (Optional) Describe a GSO for the table;
  subject to the normal limits on the number of GSIs, projected
attributes, etc.  

For both `local_secondary_index` and `global_secondary_index` objects,
the following properties are supported:

* `name` - (Required) The name of the LSI or GSI
* `hash_key` - (Required) The name of the hash key in the index; must be
  defined as an attribute in the resource
* `range_key` - (Required) The name of the range key; must be defined
* `projection_type` - (Required) One of "ALL", "INCLUDE" or "KEYS_ONLY"
   where *ALL* projects every attribute into the index, *KEYS_ONLY*
    projects just the hash and range key into the index, and *INCLUDE*
    projects only the keys specified in the _non_key_attributes_
parameter. 
* `non_key_attributes` - (Optional) Only required with *INCLUDE* as a
  projection type; a list of attributes to project into the index. For
each attribute listed, you need to make sure that it has been defined in
the table object. 

For `global_secondary_index` objects only, you need to specify
`write_capacity` and `read_capacity` in the same way you would for the
table as they have separate I/O capacity.

## Attributes Reference

The following attributes are exported:

* `id` - The name of the table

