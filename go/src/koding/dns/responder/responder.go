package responder

import (
	"koding/dns/types"
	"koding/tools/db"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"fmt"
)


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
	switch {
	case query.Qtype == types.A:
			ancount := 1
			var vm virt.VM
			// Lookup the IP for the given Hostname
			if err := db.VMs.Find(bson.M{"hostnameAlias": query.Qname}).One(&vm); err != nil {
				// Lookup failed, return SERVFAIL
				result.Responsecode = types.SERVFAIL
				fmt.Println(err)
			}
			if vm.IP != nil {
				result.Ansection = make([]types.RR, ancount)
				result.Ansection[0] = addressSection(query.Qname, vm.IP.To4())
				result.Responsecode = types.NOERROR
			} else {
				// VM Has no IP, return SERVFAIL
				result.Responsecode = types.SERVFAIL
			}

	default:
		result.Responsecode = types.SERVFAIL
	}
	return result
}

func Init(firstoption int) {
}
