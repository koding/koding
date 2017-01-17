$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'disableUser_removePermanently', ->
    describe "Click on 'Invite Your Team' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you directed to 'Send Invites' section of 'My Team' tab?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Email' field of the first row is highlighted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22@koding.com' in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged in?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'You are almost there, rainforestqa22!' title on a pop-up in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Team Stack is Pending' text in that pop-up??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, scroll down to 'Teammates' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Member' label and a little down arrow next to 'rainforestqa22'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Member' and select 'Disable user'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Member' label next to it updated as 'Disabled'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it moved to the bottom of the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that you're logged out automatically?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If not, do you see 'Your access is revoked!' text?)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'You are not allowed to access this team' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, click on 'Disabled' label and select 'Enable user'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Disabled' label next to it updated as 'Member' again??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged in??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, click on 'Member' and select 'Disable user'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Member' label next to it updated as 'Disabled'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it moved to the bottom of the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Disabled' label and select 'Remove Permanently'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'rainforestqa22' removed from the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that you're logged out automatically?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If not, do you see 'Your access is revoked!' text?)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'You are not allowed to access this team' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

