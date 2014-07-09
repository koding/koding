package koding

// Limiter checks the limits via the Check() method. It should simply return an
// error if the limitations are exceed.
type Limiter interface {
	Check() error
}

type multiLimiter []Limiter

func (m multiLimiter) Check() error {
	for _, limiter := range m {
		if err := limiter.Check(); err != nil {
			return err
		}
	}

	return nil
}

func newMultiLimiter(limiter ...Limiter) Limiter {
	return multiLimiter(limiter)
}
