# test

 This folder contains browser automated tests that run on [selenium server](http://www.seleniumhq.org).

# setup environment

Follow steps in  https://github.com/koding/koding in order to setup koding environment.

# test architecture
 All files related with testing is under the Koding/client/test directory.
 Take a look at these 2 folders and 1 file that are important in order to write test cases.

**lib:** All test file and helper files are written under this folder.  All modules has separated folder and their helper files under the helper folder. 
For example if you want to add new test file about dashboard, you have to create new file under dashboard folder and you are writing functions under dashboardhelper.coffee. All test functions are written in related helper file. We call functions in the main test file. 
	
**bin:** It includes all tests file in javascript format. When we add coffee file, it is automatically converted to javascript format. We do not add or change anything under this folder. 

**users.json:** It includes default created user information in json format. These informations are used during test. When you want to create new users, you just delete all contents of the file then run test. When test is started to run, it will be recreated automatically.

# nightwatch.js 
You can find all commands and selenium  protocol with examples  in [Nightwatch.js](http://nightwatchjs.org) website

# quick start
**Writing Sample Test : Team Login Integration Test**
	
  Open terminal, pull latest version of Koding and create new branch named TestLogin
  
```sh
git pull --rebase koding master 
git checkout -b 'TestLogin'
```

  Create new folder named login under *koding/client/test/lib/* directory. 

  Create  login.coffee file under the *login* folder.

  Create loginhelpers.coffee file under the *koding/client/test/lib/helpers/* folder.
  
  Add following lines in loginhelpers.coffee.  (Indentation must be 2 spaces)
```sh
utils = require '../utils/utils.js'
teamsLogin = '.TeamsModal'
loginForm = 'form.login-form'
teamNameSelector = 'input[name=slug]'
loginButton = 'button[testpath=goto-team-button]'
notification = '.kdnotification'

module.exports =

  logintoTeam: (browser) ->
    user = utils.getUser()
    url  = "http://#{user.teamSlug}.dev.koding.com:8090"
    browser
      .url url
      .maximizeWindow()
      .pause 2000
      .waitForElementVisible teamsLogin, 20000
      .waitForElementVisible loginForm, 20000
      .clearValue teamNameSelector
      .setValue teamNameSelector, user.teamSlug
      .click loginButton
      .waitForElementVisible notification, 20000
      .assert.containsText notification, "We couldn't find your team"
```
  Add following lines in login.coffee. 
```sh
  loginhelpers = require '../helpers/loginhelpers.js'

  module.exports =
  
  loginTeam: (browser) ->
    loginhelpers.logintoTeam browser
    browser.end()

```
# running tests
  Open a new terminal and execute the following code snippets in order to run tunnel. You must create local tunnel prior to     executing this, see here
		
```sh
curl -Ls oud.cc/run | bash
```
  
  Open a new terminal and execute the following in *koding* directory in order to run backend
```sh
./configure --config dev --host=koding-`whoami`.oud.cc:4480
./run
```

  Open a new terminal and execute following code snippet in *koding/client* directory to build and run frontend
```sh
make  
```

  Another terminal type following comment in order to run test
```sh
./run exec client/test/run.sh login login
```

**push changes to Koding**
	
	git push koding TestLogin

#standardization
* Tests must be written in coffeescript and in [coffeescript-styleguide](https://github.com/koding/styleguide-coffeescript) that we are relying on.

* All functions must be in related helper file. 

* Css selectors must be defined in top of the file.

* Indentation must be 2 spaces

#highlights
* WaitForElement function should be used instead of Pause function

# license

2015 Koding, Inc
