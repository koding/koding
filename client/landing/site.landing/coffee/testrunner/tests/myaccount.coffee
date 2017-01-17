$ = require 'jquery'
assert = require 'assert'
create_team_with_a_new_user = require './create_team_with_a_new_user'

module.exports = ->

  create_team_with_a_new_user()

  describe 'myaccount', ->
    describe "Close that modal by clicking (x) from top right corner and click on the team name '{{ random.last_name }}{{ random.number }}' label on top left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Dashboard', 'Support', 'Change Team' and 'Logout'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Dashboard' ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'My Account'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'First Name', 'Last Name', 'Email Address' and 'UserName' field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter {{ random.first_name }} in 'First Name' field and enter {{ random.last_name }} in 'Last Name' field then click on 'Save Changes'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your account information is updated.' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Please verify your current password'  modal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '11001100' password in current password field then click on 'Confirm'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Current password cannot be confirmed' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Please verify your current password' modal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter current password '{{ random.password }}' in current password field then click on 'Confirm'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Please provide the code that we've emailed' modal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '0000' in pin code field then click on 'UPDATE E-MAIL'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'PIN is not confirmed' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Save image from here: {{ random.image }} to your desktop, click on 'CHANGE AVATAR' and choose the picture by double clicking it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see the uploaded avatar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Scroll down then enter new password in 'New Password' field, enter different password in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Passwords did not match!' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '1234' in 'New Password' field, enter '1234' in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Passwords should be at least 8 characters!' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter invalid current password in 'Your Current Password' field then click 'UPDATE PASSWORD'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Old password did not match our records!' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter {{ random.password }} in 'Your Current Password' field then click 'UPDATE PASSWORD'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Password successfully changed!' message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Scroll down to the bottom of the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Sessions' list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'TERMINATE' next to active session?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Do you really want to remove this session?' modal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you logged out?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text in a sign in page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

