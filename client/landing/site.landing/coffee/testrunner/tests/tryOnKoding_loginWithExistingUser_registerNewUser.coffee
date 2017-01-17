$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'tryOnKoding_loginWithExistingUser_registerNewUser', ->
    describe "Click on 'Install KD' section and scroll down to 'Koding Button' section on the pop-up appeared?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Enable “Try On Koding” Button' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a toggle button that's in 'OFF' state next to that text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the toggle button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it turned into green?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'OFF' updated as 'ON'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a text field appeared starting with '<a href='https://_' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Try on Koding' button appeared below that text field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'If you don't have a Koding account sign up here so you can join {{ random.last_name }}{{ random.number }}!' text below that form??", (done) -> 
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

      it "Do you see 'You are almost there, rainforestqa22!' title on a pop-up displayed in the center of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that modal by clicking (x) from top right corner, click on '{{ random.last_name }}{{ random.number }}' from top left corner and select 'Logout'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged out?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'If you don't have a Koding account sign up here so you can join {{ random.last_name }}{{ random.number }}!' text below that form??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'sign up here' link??", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Join the {{ random.last_name }}{{ random.number }} team' title on a form?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'This is a public team, you can use any email address to join!' texts below the title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Email address', 'Your Username' and 'Your Password' text fields?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'SIGN UP & JOIN' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.email }}' in the 'Email address', '{{ random.first_name }}{{ random.number }}' in the 'Your Username' and '{{ random.password }}' in the 'Your Password' field and click on 'SIGN UP & JOIN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You are almost there, {{ random.first_name }}{{ random.number }}!' title on a pop-up displayed in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.last_name }}{{ random.number }}' label on top left corner??", (done) -> 
        assert(false, 'Not Implemented')
        done()

