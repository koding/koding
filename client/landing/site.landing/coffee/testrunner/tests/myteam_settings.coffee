$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'myteam_settings', ->
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

    describe "Enter 'rainforestqa22@koding.com' in the 'Email' field of the second row (not the first row) and click on 'SEND INVITES' button?", ->
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

      it "Do you see 'You are almost there, rainforestqa22!' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Team Stack is Pending' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'PENDING' text next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click team name on the left side bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Member' in the opening menu??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and scroll up to the top of the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the team name field has correct value '{{ random.last_name }}{{ random.number }}' and url includes correct team name '{{ random.last_name }}{{ random.number }}' ??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter new random team name in 'Team Name' field and click on 'CHANGE TEAM NAME' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team settings has been successfully updated.' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window then click on team name on the top left, click on 'Dashboard' in the opening menu and then click on 'My Team'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Team Name' not editable ?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'CHANGE TEAM NAME' button not visible??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to first browser save image from here: {{ random.image }} to your desktop, click on 'UPLOAD LOGO' and choose the picture?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Team settings has been successfully updated' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the uploaded logo??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'REMOVE LOGO'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Team settings has been successfully updated' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is logo removed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window then click on 'LEAVE TEAM'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Please verify your current password', 'FORGOT PASSWORD', 'CONFIRM' buttons ??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' then click on 'CONFIRM'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you logged out?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see random team name that you assigned on the login form??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You are not allowed to access this team' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

