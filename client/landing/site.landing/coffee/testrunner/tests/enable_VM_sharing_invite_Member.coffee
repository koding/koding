$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'enable_VM_sharing_invite_Member', ->
    describe "Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has a pop-up appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-inst_' text under 'Virtual Machines' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Edit Name' link next to 'Edit VM Name' section, delete 'aws-instance', type 'test' instead and hit ENTER key (like in screencast here: http://recordit.co/8HU8DZyTtX)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that it's updated??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'My Team' from left vertical menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Please scroll down to see 'Send Invites' section if it doesn't visible initially?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22@koding.com' in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
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

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, click on 'Stacks' from left vertical menu and click on the toggle button next to 'VM Sharing'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the label updated as 'ON'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it turned to green?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Has a text-box with 'Type a username' label appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'This VM has not yet been shared with anyone.' text below that text box??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' in the text box, hit enter and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'rainforestqa22' added below 'Type a username' text box?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'This VM has not yet been shared with anyone.' text removed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the modal by clicking close button on top right corner then switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'test(@rainforestqa99)' below 'SHARED VMS' title on left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a pop-up appeared next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'wants to share their VM with you.' text in that pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you also see 'REJECT' and 'ACCEPT' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

