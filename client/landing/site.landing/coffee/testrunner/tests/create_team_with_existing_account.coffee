$ = require 'jquery'
assert = require 'assert'
module.exports = ->

  describe 'create_team_with_existing_account', ->
    describe "Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa99@koding.com' in the 'Email Address' and '{{ random.last_name }}{{ random.number }}' in the 'Team Name' fields and click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your team URL' form with 'Your Team URL' field prefilled??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Hey rainforestqa99,' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Password' input field?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CREATE YOUR TEAM' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa99' in the password field and click on 'CREATE YOUR TEAM' button,(if you see 'Your login access is blocked for 1 minute' message, check that you entered 'rainforestqa99' and try again after waiting 1 minute)  then if you see 'Authentication Required' form enter 'koding' in the 'User Name:' and '1q2w3e4r' in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'You are almost there, rainforestqa99!' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??", (done) -> 
        assert(false, 'Not Implemented')
        done()

