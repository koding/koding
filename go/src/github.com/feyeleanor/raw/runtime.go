package raw

func Throw() {
	panic(nil)
}

func Catch(f func()) {
	defer func() {
		if x := recover(); x != nil {
			panic(x)
		}
	}()
	f()
}

func CatchAll(f func()) {
	defer func() {
		recover()
	}()
	f()
}