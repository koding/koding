# EC2Dynamicdata [![GoDoc](http://img.shields.io/badge/go-documentation-blue.svg?style=flat-square)](http://godoc.org/github.com/koding/ec2dynamicdata)

ec2dynamicdata is an handy package to retrieve the ec2 dynamic data and meta
data information via simple API. The API can change in the future, please
vendor it in your code base.


## Install

```bash
go get github.com/koding/ec2dynamicdata
```

## Usage

There are two main functions, one for `dynamicdata` and one for `metadata`.
Below is an example code usage:

```go
data, _ := ec2dynamicdata.Get()
/* data output:
{
  "accountId" : "123456789",
  "instanceId" : "i-abc123",
  "billingProducts" : null,
  "instanceType" : "t2.micro",
  "imageId" : "ami-9871234",
  "kernelId" : null,
  "ramdiskId" : null,
  "architecture" : "x86_64",
  "pendingTime" : "2015-07-21T09:10:42Z",
  "region" : "eu-west-1",
  "version" : "2010-08-31",
  "availabilityZone" : "eu-west-1b",
  "devpayProductCodes" : null,
  "privateIp" : "10.0.123.456"
}
*/

fmt.Println(data.ImageID)  // ami-9871234
fmt.Println(data.AccountID // 123456789

amiID, _ := ec2dynamicdata.GetMetadata(ec2dynamicdata.AmiId)
instanceID, _ := ec2dynamicdata.GetMetadata(ec2dynamicdata.InstanceId)
// and so on ...
```

## License

The MIT License (MIT) - see [`LICENSE.md`](https://github.com/koding/ec2dynamicdata/blob/master/LICENSE.md) for more details

