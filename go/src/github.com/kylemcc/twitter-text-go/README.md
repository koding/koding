# twitter-text-go #
Twitter-text-go is a [Go](http://golang.org/) port of the various twitter-text handling libraries. 

## Installation ##

Currently, only extraction and validation have been implemented. Install those packages using the "go get" command:

	go get github.com/kylemcc/twitter-text-go/{validate,extract}

## Documentation ##

[API Documentation](http://godoc.org/github.com/kylemcc/twitter-text-go) (powered by [godoc.org](http://godoc.org))

## Todo ##

Implement the rest of the twitter-text APIs: Auto-linking and Hit Highlighting

## Contributing ##
Pull requests welcome.

## Testing ##
The unit tests rely on the [twitter-text-conformance](https://github.com/twitter/twitter-text-conformance) project. To add this project as a submodule, run the following from the root of the project:

	git submodule add git@github.com:twitter/twitter-text-conformance.git
	git submodule init
	git submodule update

## License ##

See here: [License](https://github.com/kylemcc/twitter-text-go/blob/master/LICENSE)
