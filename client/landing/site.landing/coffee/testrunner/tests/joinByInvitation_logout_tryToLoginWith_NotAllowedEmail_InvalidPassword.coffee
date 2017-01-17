$ = require 'jquery'
assert = require 'assert'
module.exports = ->

  describe 'joinByInvitation_logout_tryToLoginWith_NotAllowedEmail_InvalidPassword', ->
    describe "Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforest+{{ random.email }}' in the 'Email Address' and '{{ random.last_name }}{{ random.number }}' in 'Team Name' fields and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your team URL' form with 'Your Team URL' field pre-filled??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your account' form with 'Email address' field pre-filled?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Username' and 'Your Password' text fields??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.first_name }}{{ random.number }}' in the 'Your Username' and '{{ random.password }}' in the 'Your Password' field and click on 'CREATE YOUR TEAM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Authentication Required' form?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If not it's OK, then are you signed up successfully?)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "If you see 'Authentication Required' form, enter 'koding' in the 'User Name:' and '1q2w3e4r' in the 'Password:' fields and click on 'Log In', if not do nothing and check the items below?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You are almost there, {{ random.first_name }}{{ random.number }}!' title?", (done) -> 
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

      it "Do you see that 'Email' field of the first row is highlighted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.email }}' in the 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is sent to {{ random.email }}' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ random.inbox }}' by pasting the url (using ctrl-v) in the address bar, wait ~1min and refresh the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You are invited to join a team on Koding' email in inbox that received a few minutes ago (and, probably, several older emails)??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Open Email' for that 'You are invited to join a team on Koding' email?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Hi there, You received this email because {{ random.first_name }}{{ random.number }} would like you to join {{ random.last_name }}{{ random.number }}'s Team on Koding.com' text in the email?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'ACCEPT INVITE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'ACCEPT INVITE' button, then if you see 'Authentication Required' form opened in the new tab, enter 'koding' in the 'User Name:' and '1q2w3e4r' in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below) ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Join the {{ random.last_name }}{{ random.number }} team' title on a form?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Email address' field is pre-filled with '{{ random.email }}'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Username' and 'Your Password' text fields?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'SIGN UP & JOIN' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.first_name }}{{ random.password }}' in the 'Your Username' and '{{ random.password }}' in the 'Your Password' field and click on 'SIGN UP & JOIN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you signed up successfully?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'You are almost there, {{ random.first_name }}{{ random.password }}!' title on a pop-up displayed in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.last_name }}{{ random.number }}' label on top left corner?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a little down arrow next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the pop-up by clicking (x) from top right corner and click on the little down arrow next to '{{ random.last_name }}{{ random.number }}'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Dashboard', 'Support', 'Change Team' and 'Logout' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Logout'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you logged out successfully?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Username or Email' and 'Your Password' text fields?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_SIGN IN' button below these fields??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'You are not allowed to access this team' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.email }}' in 'Username or Email' and '{{ random.number }}' in 'Password' field and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Access denied!' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "?", (done) -> 
        assert(false, 'Not Implemented')
        done()

