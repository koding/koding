package plans

type InstanceType int

const (
	T2Micro InstanceType = iota + 1
	T2Small
	T2Medium
	T2Nano
)

var Instances = map[string]InstanceType{
	"t2.nano":   T2Nano,
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
	case T2Nano:
		return "t2.nano"
	default:
		return "UnknownInstance"
	}
}
