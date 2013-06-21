package responder

import (
	"koding/dns/types"
	"koding/tools/db"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"fmt"
)

// Compile-time options
const includesPort = false // If false, sends only the address for TXT queries.
// If true, includes the UDP or TCP port.
// TODO: allow to secify the Qname it must respond to

func addressSection(qname string, client net.IP) (result types.RR) {
	result.Name = qname
	result.Type = types.A
	result.Class = types.IN
	result.TTL = 0
	result.Data = client
	return
}

func Respond(query types.DNSquery, config map[string]interface{}) types.DNSresponse {
	var (
		result types.DNSresponse
	)
	result.Ansection = nil
	tcpAddr, _ := net.ResolveTCPAddr("tcp", query.Client.String())
	ipaddressV4 := tcpAddr.IP.To4()
	fmt.Println(query.Qname)
	switch {
	case query.Qtype == types.A:
		result.Responsecode = types.NOERROR
		if ipaddressV4 != nil {
			ancount := 1
			result.Ansection = make([]types.RR, ancount)
			var vm virt.VM
			if err := db.VMs.Find(bson.M{"hostnameAlias": query.Qname}).One(&vm); err != nil {
				result.Ansection[0] = addressSection(query.Qname, ipaddressV4)
				fmt.Println(err)
			}
			if vm.IP != nil {
				result.Ansection[0] = addressSection(query.Qname, vm.IP.To4())
				fmt.Println(vm.IP)
			}
		} else {
			// ancount := 0
		}
	default:
		result.Responsecode = types.NOERROR
	}
	return result
}

func Init(firstoption int) {
}
