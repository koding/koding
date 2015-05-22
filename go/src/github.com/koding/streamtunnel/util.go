package streamtunnel

// async is a helper function to convert a blocking function to a function
// returning a signal. Useful for plugging function closures into select and co
func async(fn func()) <-chan struct{} {
	done := make(chan struct{}, 0)
	go func() {
		fn()
		close(done)
	}()

	return done
}
