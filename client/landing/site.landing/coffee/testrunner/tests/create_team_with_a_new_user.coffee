$ = require 'jquery'
assert = require 'assert'
module.exports = ->

  describe 'create_team_with_a_new_user', ->
    describe "Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.email }}' in the 'Email Address' and '{{ random.last_name }}{{ random.number }}' in 'Team Name' fields and click on 'NEXT' button?", ->
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

