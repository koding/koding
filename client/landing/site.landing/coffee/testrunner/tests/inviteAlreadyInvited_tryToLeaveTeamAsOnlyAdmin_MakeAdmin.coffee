$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'inviteAlreadyInvited_tryToLeaveTeamAsOnlyAdmin_MakeAdmin', ->
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

    describe "Enter 'rainforestqa22@koding.com' in 'Email' field again and then click on 'SEND INVITES' below ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Resend Invitation' titled pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa22@koding.com has already been invited.' text and 'CANCEL' and 'RESEND' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'RESEND' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is resent to rainforestqa22@koding.com' message displayed??", (done) -> 
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

    describe "Return to the first browser, scroll up to 'Team Settings' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'LEAVE TEAM' link on the bottom of that section??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'LEAVE TEAM'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a pop-up displayed with 'Please verify your current password' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a text field with 'Current Password' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'FORGOT PASSWORD?' and 'CONFIRM' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa99' in the text field and click on 'CONFIRM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'As owner of this group, you must first transfer ownership to someone else!' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Scroll down to 'Teammates' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Member' label and a little down arrow next to 'rainforestqa22'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Member' and select 'Make admin'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'Member' label is updated as 'Admin'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that a yellow star icon is added next to 'rainforestqa22'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your team role has been changed!' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '@rainforestqa99 made you an admin,_' text  and 'RELOAD PAGE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'RELOAD PAGE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections on the pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that modal by clicking (x) from top right corner and click on 'STACKS' title from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Create New Stack Template' text and 'NEW STACK' button next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Billing' item in the left vertical menu under 'Dashboard' title??", (done) -> 
        assert(false, 'Not Implemented')
        done()

