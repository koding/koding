package plans

type Instance struct {
	CPU int
	Mem int
}

type InstanceType int

const (
	T2Micro InstanceType = iota + 1
	T2Small
	T2Medium
)

var Instances = map[string]InstanceType{
	"t2.micro":  T2Micro,
	"t2.small":  T2Small,
	"t2.medium": T2Medium,
}

func (i InstanceType) String() string {
	switch i {
	case T2Micro:
		return "t2.micro"
	case T2Small:
		return "t2.small"
	case T2Medium:
		return "t2.medium"
	default:
		return "UnknownInstance"
	}
}

// http://aws.amazon.com/ec2/instance-types/
// Model		vCPU	Mem (GiB)
// t2.micro		1		1
// t2.small		1		2
// t2.medium	2		4
func (i InstanceType) Instance() Instance {
	switch i {
	case T2Micro:
		return Instance{CPU: 1, Mem: 1}
	case T2Small:
		return Instance{CPU: 1, Mem: 2}
	case T2Medium:
		return Instance{CPU: 2, Mem: 4}
	}

	return Instance{}
}
