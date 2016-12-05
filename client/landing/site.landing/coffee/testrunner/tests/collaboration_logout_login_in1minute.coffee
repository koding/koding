$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_logout_login_in1minute', ->
    describe "Click on team name on the top left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see with opening menu with 'Logout' item??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Logout'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you logout??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button (You have to login again less than 1 minute)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged in??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click to 'aws-instance_' under 'Shared VMs' section in sidebar on the left side and wait until it loads?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'LEAVE SESSION' at the bottom right corner of the window??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99', click on team name on the top left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see with opening menu with 'Logout' item??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Logout'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you logout??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa99' both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button (You have to login less than 1 minute)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged in??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click to 'aws-instance' in 'Stacks' section and wait for it to load?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "If you see a modal then close it by clicking (x) at top right corner and wait for loading. Do you see 'END COLLABORATION' button at the bottom right corner??", (done) -> 
        assert(false, 'Not Implemented')
        done()

