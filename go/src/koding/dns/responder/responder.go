package responder

import (
	"koding/db/mongodb/modelhelper"
	"koding/dns/types"
	"net"
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
		// Lookup the hostnameAlias for the given domain
		domain, err := modelhelper.GetDomain(query.Qname)
		if err != nil {
			result.Responsecode = types.SERVFAIL
			return result
		}

		// Lookup the IP for the given Hostname
		vm, err := modelhelper.GetVM(domain.HostnameAlias[0])
		if err != nil {
			result.Responsecode = types.SERVFAIL
			return result
		}

		if vm.IP == nil {
			result.Responsecode = types.SERVFAIL
			return result
		}

		// VM IP Jackpot.
		ancount := 1
		result.Ansection = make([]types.RR, ancount)
		result.Ansection[0] = addressSection(query.Qname, vm.IP.To4())
		result.Responsecode = types.NOERROR

	default:
		result.Responsecode = types.SERVFAIL
	}

	return result
}

func Init(firstoption int) {
}
