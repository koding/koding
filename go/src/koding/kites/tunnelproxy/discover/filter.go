package discover

type FilterFunc func(*Endpoint) bool

func And(fn ...FilterFunc) FilterFunc {
	return func(e *Endpoint) bool {
		for _, fn := range fn {
			if !fn(e) {
				return false
			}
		}

		return true
	}
}

func Or(fn ...FilterFunc) FilterFunc {
	return func(e *Endpoint) bool {
		for _, fn := range fn {
			if fn(e) {
				return true
			}
		}

		return false
	}
}

func Not(fn FilterFunc) FilterFunc {
	return func(e *Endpoint) bool {
		return !fn(e)
	}
}

func ByAddr(addr string) FilterFunc {
	return func(e *Endpoint) bool {
		return e.Addr == addr
	}
}

func ByProtocol(proto string) FilterFunc {
	return func(e *Endpoint) bool {
		return e.Protocol == proto
	}
}

func ByLocal(local bool) FilterFunc {
	return func(e *Endpoint) bool {
		return e.Local == local
	}
}
