$ = require 'jquery'
assert = require 'assert'

#! 1edbcec4-0f80-4a21-a278-951dce8bf458
# title: myaccount
# start_uri: /
# tags: automated
#

describe "myaccount.rfml", ->
  before -> 
    require './create_team_with_a_new_user.coffee'

  describe """Click on 'Dashboard' """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'My Account'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'First Name', 'Last Name', 'Email Address' and 'UserName' field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter {{ random.first_name }} in 'First Name' field and enter {{ random.last_name }} in 'Last Name' field then click on 'Save Changes'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your account information is updated.' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please verify your current password'  modal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '11001100' password in current password field then click on 'Confirm'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Current password cannot be confirmed' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter new {{ random.first_name }}@koding.com in the 'Email address' then click on 'Save Changes'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please verify your current password' modal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter current password "{{ random.password }}" in current password field then click on 'Confirm'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please provide the code that we've emailed' modal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '0000' in pin code field then click on 'UPDATE E-MAIL'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'PIN is not confirmed' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Save image from here: {{ random.image }} to your desktop, click on 'CHANGE AVATAR' and choose the picture by double clicking it""", ->
    before -> 
      # implement before hook 

    it """# Do you see the uploaded avatar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Scroll down then enter new password in 'New Password' field, enter different password in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Passwords did not match!' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '1234' in 'New Password' field, enter '1234' in 'Repeat New Password' field and enter current password {{ random.number }} in 'Your Current Password' field then click 'UPDATE PASSWORD'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Passwords should be at least 8 characters!' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter invalid current password in 'Your Current Password' field then click 'UPDATE PASSWORD'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Old password did not match our records!' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '12345678' in 'New Password' field, enter '12345678' in 'Repeat New Password' field and enter {{ random.password }} in 'Your Current Password' field then click 'UPDATE PASSWORD'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Password successfully changed!' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Scroll down to the bottom of the page""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Sessions' list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'TERMINATE' next to active session""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Do you really want to remove this session?' modal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES'""", ->
    before -> 
      # implement before hook 

    it """Are you logged out?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text in a sign in page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


