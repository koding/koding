$ = require 'jquery'
assert = require 'assert'
create_team_with_a_new_user = require './create_team_with_a_new_user'

module.exports = ->

  create_team_with_a_new_user()

  describe 'koding_utilities', ->
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

    describe "Enter 'rainforestqa22@koding.com' in the 'Email' field and uncheck admin column then click to 'SEND INVITES'?", ->
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

      it "Do you see 'You are almost there, rainforestqa22!' titled pop-up??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that pop-up by clicking (x) icon from top right and click on the team name '{{ random.last_name }}{{ random.number }}' label on top left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Dashboard', 'Support', 'Support',  'Change Team' and 'Logout'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Dashboard'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Koding Utilities'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'KD CLI', 'Koding OS X App'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and click on 'Koding Utilities'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'KD CLI', 'Koding OS X App'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the KD command line which starts with 'curl -sL ...'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you see 'Copied to clipboard!' notification??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Click on 'VIEW GUIDE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Is new tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Use your own IDE', 'Introduction', 'Step 1: Get the kd install command' in new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Close the newly opened tab, go to 'Koding OS X App' section and click on 'DOWNLOAD' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Go to 'Koding OS X App' section and click on 'DOWNLOAD' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Koding Desktop App' in new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the tab, go to 'Koding Button' section and enable 'Try On Koding' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see code block which start with '<a href='https:// ...'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on code block?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you see 'Copied to clipboard!' notification??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the incognito window and go to 'Koding Button' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Try On Koding' button not visible?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see code block which start with '<a href='https:// ...'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the first browser and disable 'Try On Koding' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Try on Koding' button removed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is code block removed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see only 'VIEW GUIDE'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Try on Koding Button', 'What is Koding and why use Try on Koding button?' in new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the tab, go to 'API Access' section, enable 'Enable API Access'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'No tokens have been created yet. When you create, they will be listed here.'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'VIEW GUIDE', 'ADD NEW API TOKEN'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'ADD NEW API TOKEN'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see token list with 'COPY', 'DELETE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Delete' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' overlay??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it removed from token list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'No tokens have been created yet. When you create, they will be listed here.'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'API Tokens', 'Coming soon:' in new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close tab and return same section, disable 'Enable API Access'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'ADD NEW API TOKEN' button disabled??", (done) -> 
        assert(false, 'Not Implemented')
        done()

