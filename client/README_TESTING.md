# Unit Testing in Client


### Tools we are using

- [Mocha](https://mochajs.org) as our testing suite.
- [expect](https://github.com/mjackson/expect) as assertion library.


### Folder structure

```
├── activity
├── admin
├── app
├── finder
├── ide
  ├── lib
  │  ├── routes.coffee
  │  └── views
  │    └── tabview
  │      └── ideview.coffee
  └── test
     ├── index.coffee
     ├── routes.test.coffee
     └── views
       └── tabview
         └── ideview.test.coffee

```

- Test folders should be at the root of the app folder. See `ide/test`. In a test folder there should be a file named `index.coffee` which we will use this file to require our test files. [See this](https://github.com/koding/koding/blob/master/client/app/test/index.coffee)

- Test files should be in `filename.test.coffee`. See `routes.test.coffee`

- `test` folder should match the folder structure of the `lib` folder.
  -  `lib/routes.coffee` -> `test/routes.test.coffee`
  -  `lib/views/tabview/index.coffee` -> `test/views/tabview/ideview.test.coffee`



### Basic structure of a test file

- Test file should start with a meaningful `describe` block. Preferably class name, or singleton name. See the examples below
  - `describe 'kd.singletons.appManager', ->`
  - `describe 'IDE.routes, ->`
  - `describe 'IDEView`

- Each test must have an `afterEach` block to restore spy functions. We will talk about spies later.
  - `afterEach -> expect.restoreSpies()`

- Each prototype method should have its own `describe` and named as follows. Note the `::`.
  - `describe '::createTerminal', ->`

- Each test should be in a `describe` block and tests should start with `it` as required by `mocha` and test name should start with `should` for sake of readability. See the following examples.
  - `it 'should create a terminal pane and append it', ->`
  - `it 'should create a change object and emit it', ->`

- And of course, make sure that your tests have expections :)


# All about Mocks

### Adding spy to a method

Spy allows you to override the original function and verify that whether it's called or not. `expect` has such a great built-in spy mechanism. To add a spy all you need to do

```coffee
expect.spyOn ideView, 'createEditor
```

At this point when you call `ideView.createEditor` the original `ideView.createEditor` will never be called instead the spy function will be executed. By using this spy mechanism you can bypass unnecessary functions in your tests.


### Verifiying spy methods

When you add a spy to method, usually you need to verify whether it's called or not. To do so, `expect` has `toHaveBeenCalled` and `tohaveBeenCalledWith` functions.

If you don't care about the parameters passed to your spy function, you can use `toHaveBeenCalled`

```coffee
expect.spyOn ideView, 'createEditor'

ideView.openFile file # assuming that openFile method will call createEditor

expect(ideView.createEditor).toHaveBeenCalled()
```

If you also want to verify that your spy function called with desired parameters, you can use `toHaveBeenCalledWith`


```coffee
expect.spyOn ideView.editor, 'scrollToRow'
expect.spyOn ideView.editor, 'scrollToColumn'

# assuming that goToLine will call scrollToRow
# and scrollToColumn of editor
ideView.goToLine 5, 3 # row: 5, column: 3

expect(ideView.editor.scrollToRow).toHaveBeenCalledWith 3
expect(ideView.editor.scrollToColumn).toHaveBeenCalledWith 5
```

However `toHaveBeenCalledWith` make equality check. If you don't have the reference of an object you cannot use `toHaveBeenCalledWith`. Better to describe with a snippet.

```coffee
expect.spyOn ideView, 'showPaneInTabView'

# assuming openFile will check whether the file is
# opened or not. if it's opened then it will call
# show the file in the tabView.
ideView.openFile fileInstance

tabView = { some: 'tabview', i: 'just created' }
expect(ideView.showPaneInTabView).toHaveBeenCalledWith tabView, fileInstance
```

This will fail because you didn't pass the same instance/reference of tabView to the `toHaveBeenCalledWith`. Instead you passed a mock Object with the same keys in it.

To make it work there is another approach. Getting calls of the spy function and checking it's arguments list. Let's see with some code.

```coffee
spy = expect.spyOn ideView, 'showPaneInTabView'

ideView.openFile fileInstance


[ tabView, fileInstance ] = spy.calls[0].arguments

# now you can check that tabView is the droid you are looking for
expect(tabView.someProperty).toBe yes
expect(tabView.anotherPropery).toEqual { foo: 1, bar: 2 }

# also you can check that whether the file instance is your fileInstance.
expect(fileInstance).toBe fileInstance
```


### Spying a method but still calling the original method

In somecases will need to spy a method to assert. But when you spy a method it won't be called anymore. But what if it has to be invoked. To achieve that you can do

```coffee
expect.spyOn(ideView, 'openFile').andCallThrough()
```

By doing this, you can verify `openFile` arguments without breaking the code flow.


### Return desired value when your spy method is called

When you need to mock return data of some spied method, `andReturn` will help you.

```coffee
myFileInstance = { path: 'foo/bar' }

expect.spyOn(ideView, 'getFile').andReturn myFileInstance
```

At this point whenever `ideView.getFile` called it will return `myFileInstance`


### Mock callback functions when your spy method is called

This is one of the most used tricks in [Mockingjay](https://github.com/koding/koding/blob/master/client/mocks/mockingjay.coffee). To better understanding just search `andCall` in Mockingjay.


When you pass a callback to a spied method and if you want that callback is called with some desired parameters, here is `andCall` for you. Code.

```coffee
expect.spyOn(remote.api.JAccount, 'some').andCall (query, options, callback) ->
  callback null, [ account ]
```

In this example, we mocked `remote.api.JAccount.some` and when it's called it will call the given callback with `null, [ account ]` parameters.

Let's say you want to test an error check of `remote.api.JAccount.some`. Easy.

```coffee
expect.spyOn(remote.api.JAccount, 'some').andCall (query, options, callback) ->
  callback { some: 'error' }
```

### Mocking single file helpers like `nick`, `isKoding` etc.

The only disadvantage of the `expect` I see was, it's unable to mock functions which it doesn't belong to an object. Consider the following code.

```coffee
obj   =
  foo : ->
```

We can mock `obj.foo` by doing `expext.spyOn obj, 'foo'` that's simple but you can't do the following due to limitations of the `expect` library.

```coffee
foo = ->
```

You cannot say `expect.spyOn foo` because it's not working in this way. Also you cannot say the following. It won't work because called functions wont' be the same.

```coffee
foo = -> return 'foo'
module.exports = foo
```

```coffee

foo = require 'foo'
tempObj: { foo }

expect.spyOn tempObj, 'foo'

i.call.a.function.which.will.call.foo.in.it()

expect(tempObj.foo).toHaveBeenCalled() # this will fail.
```

To find a workaround to this problem, we, acet and usirin, ended up a solution based on `rewireify`. Basically while building the client code it rewires the methods to be the same. To do so, you can do it like this,

```coffee
showErrorNotificationSpy    = expect.createSpy()
revertShowErrorNotification = IDEView.__set__ 'showErrorNotification', showErrorNotificationSpy
```

By doing this, we create a spy and we rewire the `showErrorNotification` util function in `IDEView`. Whenever when we calle `showErrorNotification` it will call the spy we created here.

There is an important thing to remember here which is we have to revert `showErrorNotification` back to it's original state. `rewireify`'s `__set__` returns a function to revert it to original state, all we need to do is calling that revert function when we are done in our test.


# All about Mockingjay

[Mockingjay](https://github.com/koding/koding/blob/master/client/mocks/mockingjay.coffee) is a utility file which we use for mocking common APIs we use everyday. Mockingjay is placed in `mocks` folder. In that folder you can also find hardcoded mock files like `mock.jmachine` and `mock.jaccount`. If you need a mock data it would be better to check `mocks` folder and we don't have add it you can add there and we will have a growning mock data collection.

Mockingjay is useful for by-pass `remote.api` calls or fake return value of some methods. For example, you wrote your code to handle error response of `fsFile.fetchPermission` and to test it `fsFile.fetchPermission` must return an error. It's already written in Mockingjay however here is how you can do it.


```coffee
it 'should showErrorNotification if file.fetchPermissions returns error', ->

  err = message: 'Everything is something happened.'
  mock.fsFile.fetchPermissions.toReturnError err

  ideView.createEditor createFile()

  expect(errorHandler).toHaveBeenCalledWith err
```

In Mockingjay, `mock.fsFile.fetchPermission.toReturnError` and `mock.fsFile.fetchPermissions.toReturnInfo` should be written like below

```
  mock =
    fsFile:
      fetchPermissons:
        toReturnError: (error = { some: 'error' }) ->

          expect.spyOn(FSFile.prototype, 'fetchPermissions').andCall (callback) ->
            callback error

        toReturnInfo: (readable = yes, writable = yes) ->

          expect.spyOn(FSFile.prototype, 'fetchPermissions').andCall (callback) ->
            callback null, { readable, writable }
```

Mockingjay, has a special naming for methods. You can use it like how you use other API methods with a `mock.` prefix. I did it in purpose of readability and ease to remember. Here is what I mean.

```coffee
  mock.envDataProvider.fetchMachine.toReturnNull();
  mock.envDataProvider.fetchMachine.toReturnMachine()

  mock.ideRoutes.getLatestWorkspace.toReturnNull()
  mock.ideRoutes.getLatestWorkspace.toReturnWorkspace()
  mock.ideRoutes.getLatestWorkspace.toReturnWorkspaceWithChannelId()

  mock.remote.api.JAccount.some.toReturnError()
  mock.remote.api.JAccount.some.toReturnAccounts()
```


## Tips and Tricks

- Use [Mockingjay](https://github.com/koding/koding/blob/master/client/mocks/mockingjay.coffee)
- Look `mocks` folder if you need mock data of something.
- If your test is async, make sure that you are using `done`.
- Restore spies after each test. `afterEach -> expect.restoreSpies()`
- For Objects, use `toBe` if you have the same reference to that Object. Otherwise use `toEqual`.
  - `expect({}).toBe({})` will fail but `expect({}).toEqual({})` will pass.
- Use `.toHaveBeenCalled` and `.toHaveBeenCalledWith` if you want to assert whether your spied function is called or not.
- Need to deal with `Promise`. Better check `remote.api.JAccount.one` in [Mockingjay](https://github.com/koding/koding/blob/master/client/mocks/mockingjay.coffee)
