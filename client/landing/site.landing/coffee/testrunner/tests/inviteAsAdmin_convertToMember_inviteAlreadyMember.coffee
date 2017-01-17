$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'inviteAsAdmin_convertToMember_inviteAlreadyMember', ->
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

    describe "Enter 'rainforestqa22@koding.com' in the 'Email' field of the first row, '{{ random.email }}' in the second row and 'rainforest+{{ random.email }}' in the third row?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 4th row is autoadded to the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SEND INVITES' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You're adding an admin' pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'THAT'S FINE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'THAT'S FINE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'All invitations are sent.' message displayed??", (done) -> 
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

      it "Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Invite Your Team' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you directed to 'Send Invites' section of 'My Team' tab?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Admin' checkbox field at the end of the row?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Billing' item under 'Dashboard' from left vertical menu??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and scroll down to the bottom of the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Admin' label next to 'rainforestqa22'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a yellow star icon next to rainforestqa22's avatar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Scroll up to 'Send Invites' section again, enter 'rainforestqa22@koding.com' in the first row and click on 'SEND INVITES' and then click on 'THAT'S FINE' button (be sure that admin checkbox is checked)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Invites Already Sent' title on a pop-up appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa22@koding.com is already a member of your team.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'OK' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'OK' button and scroll down to the bottom of the page again and click on the little down arrow next to 'Admin' label?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Make owner', 'Make member' and 'Disable user' options?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the same little down arrow next to 'Owner' label??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Select 'Make member'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Admin' label next to 'rainforestqa22' updated as 'Member'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is the little down arrow next to 'Owner' label above is disappeared??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your team role has been changed!' title on a pop-up appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '@rainforestqa99 made you a member, please refresh your browser for changes to take effect.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'RELOAD PAGE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'RELOAD PAGE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Team Billing' item removed from left vertical menu?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'Admin' checkbox removed from 'Send Invites' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are the little down arrows next to 'Owner', 'Invitation Sent' and 'Member' removed and no longer available (in Teammates section on the bottom of the page)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Member' label next to 'rainforestqa22'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

