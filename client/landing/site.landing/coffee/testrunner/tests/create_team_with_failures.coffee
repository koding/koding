$ = require 'jquery'
assert = require 'assert'
module.exports = ->

  describe 'create_team_with_failures', ->
    describe "Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Please type a valid email address.' warning?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Please enter a team name.' warning??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.email }}' in the 'Email Address' and enter 'test' in 'Team Name' fields and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your team URL' form with 'Your Team URL' field prefilled??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Delete the prefilled URL and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Domain name should be longer than 2 characters!' warning?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the red border around the text field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'sandbox' and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invalid domain!' warning?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the red border around the text field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'koding' and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Domain is taken!' warning?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the red border around the text field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.last_name }}{{ random.number }}' as converted to uppercase and click on 'NEXT' button ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your account' form with 'Email address' field prefilled??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Leave 'Your Username' and 'Your Password' fields empty and click on 'CREATE YOUR TEAM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'For username only lowercase letters and numbers are allowed!' and 'Passwords should be at least 8 characters.' warnings?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the red border around the text fields??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'aaa' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Username should be between 4 and 25 characters!' warning?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the red border around the text field for username??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'koding' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Sorry, 'koding' is already taken!' warning??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.first_name }}{{ random.number }}' as converted to uppercase in the username field and click on 'CREATE YOUR TEAM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Authentication Required' form?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "If not do you see 'You are almost there,_' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??", (done) -> 
        assert(false, 'Not Implemented')
        done()

