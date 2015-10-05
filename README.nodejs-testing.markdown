# Testing Node.js Code

This document aims to explain everything about running and writing tests for node.js code.

## Infrastructure of Node.js testing

[Mocha.js](http://mochajs.org/) is being used as the test framework. The assertion library that we use in our tests is [Chai.js](http://chaijs.com/).

## Installation

No need to install anything to run tests within Koding repository.
You should be ready for testing when you clone Koding repository.

## Running tests in local

Running tests in local is as easy as executing `./run $TEST_COMMAND`.
`$TEST_COMMAND` can be `socialworkertests`, `nodeservertests`, and `nodetestfiles`.
These commands picks up the files with the extension `.test.coffee` and ignores the rest.
So be sure that your test files end with `.test.coffee`

`socialworkertests` and `nodeservertests` are for the files in socialworker and servers directories.
On the other hand `nodetestfiles` can be used to run a single test file or all the files in directory.
For example `./run nodetestfiles pathToSingleFile.x.test.coffee` or `./run nodetestfiles aFolder`

## Writing tests

For writing tests we have some rules to be followed:
* [BDD api](http://chaijs.com/api/bdd/) with `expect` style of Chai.js should be used in tests.
* [Coffee style guide](https://github.com/koding/styleguide-coffeescript) of Koding should be applied to test code.
* Test files should be added to the same folder with the file being tested.
* Adding separate test suites for main scenarios is strongly advised.
```coffeescript
describe 'servers.handlers.verifyslug', ->

  describe 'when domain is available', ->
  
    it 'should send HTTP 200 if domain is valid', (done) ->
      ...
      
  describe 'when domain is not available', ->
  
    it 'should send HTTP 400', (done) ->
      ...
```
* Variables should be declared in test suite/case scope, global variables should be avoided.
```coffeescript
#NO
verifySlugRequestParams = generateVerifySlugRequestParams
      body   :
        name : ''
        
describe 'servers.handlers.verifyslug', ->
  
  it 'should send HTTP 400 if team domain is not set', (done) ->
    
    request.post verifySlugRequestParams ...


#YES
describe 'servers.handlers.verifyslug', ->
  
  it 'should send HTTP 400 if team domain is not set', (done) ->

    verifySlugRequestParams = generateVerifySlugRequestParams
      body   :
        name : ''
        
    request.post verifySlugRequestParams ...
```

## Testing process in wercker

Wercker connects to a test instance via ssh and calls
`./run socialworkertests` and `./run nodeservertests` on the test instance.
