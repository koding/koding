$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'send_resend_revoke_openRevoked_invitation', ->
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

    describe "Enter 'rainforest+{{ random.first_name }}' email and click on 'SEND INVITES' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'That doesn't seem like a valid email address.' warning??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Delete the text from email field and enter '{{ random.email }}' in the 'Email', '{{ random.first_name }}{{ random.number }}' in the 'First Name' fields and enter 'rainforestqa22@koding.com' email in the second row and click on 'SEND INVITES' button?", ->
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

    describe "Scroll down to the bottom of the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'rainforestqa99' and 'Owner' label next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.email }}' and 'rainforestqa22@koding.com' listed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Invitation Sent' text next to them?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a little down arrow next to 'Invitation Sent' labels??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '{{ random.email }}'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Resend Invitation' and 'Revoke Invitation' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Resend Invitation'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is resent.' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '{{ random.email }}' again and then click on 'Revoke Invitation'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is '{{ random.email }}' removed from the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ random.inbox }}' by pasting the url (using ctrl-v) in the address bar, wait ~1min and refresh the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see two 'You are invited to join a team on Koding' emails in inbox that received a few minutes ago?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(Ignore older emails)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Open Email' for the last one of 'You are invited to join a team on Koding' emails?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Hi there, You received this email because rainforestqa99 would like you to join {{ random.last_name }}{{ random.number }}'s Team on Koding.com' text in the email?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'ACCEPT INVITE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'ACCEPT INVITE' button, then if you see 'Authentication Required' form opened in the new tab, enter 'koding' in the 'User Name:' and '1q2w3e4r' in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below) ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'invitation not found' message that disappears after a second?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text and 'SIGN IN' button??", (done) -> 
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

      it "Do you see 'You are almost there, rainforestqa22!' title in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Team Stack is Pending' and 'PENDING' text next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser (you can close the incognito window)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Member' text next to 'rainforestqa22'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

