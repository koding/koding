$ = require 'jquery'
assert = require 'assert'

#! 6d1a91ab-c03b-4f21-b783-e078b9d94577
# title: joinByInvitation_logout_tryToLoginWith_NotAllowedEmail_InvalidPassword
# start_uri: /
# tags: automated
#

describe "joinByInvitation_logout_tryToLoginWith_NotAllowedEmail_InvalidPassword.rfml", ->
  describe """Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforest+{{ random.email }}" in the 'Email Address' and "{{ random.last_name }}{{ random.number }}" in 'Team Name' fields and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team URL' form with 'Your Team URL' field pre-filled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your account' form with 'Email address' field pre-filled?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Username' and 'Your Password' text fields??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.first_name }}{{ random.number }}" in the 'Your Username' and "{{ random.password }}" in the 'Your Password' field and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Authentication Required' form?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If not it's OK, then are you signed up successfully?)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """If you see 'Authentication Required' form, enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In', if not do nothing and check the items below""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are almost there, {{ random.first_name }}{{ random.number }}!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Invite Your Team' section""", ->
    before -> 
      # implement before hook 

    it """Are you directed to 'Send Invites' section of 'My Team' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Email' field of the first row is highlighted??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.email }}" in the 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is sent to {{ random.email }}' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ random.inbox }}' by pasting the url (using ctrl-v) in the address bar, wait ~1min and refresh the page""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are invited to join a team on Koding' email in inbox that received a few minutes ago (and, probably, several older emails)??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Open Email' for that 'You are invited to join a team on Koding' email""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Hi there, You received this email because {{ random.first_name }}{{ random.number }} would like you to join {{ random.last_name }}{{ random.number }}'s Team on Koding.com' text in the email?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'ACCEPT INVITE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'ACCEPT INVITE' button, then if you see 'Authentication Required' form opened in the new tab, enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below) """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Join the {{ random.last_name }}{{ random.number }} team' title on a form?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Email address' field is pre-filled with '{{ random.email }}'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Username' and 'Your Password' text fields?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'SIGN UP & JOIN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.first_name }}{{ random.password }}" in the 'Your Username' and "{{ random.password }}" in the 'Your Password' field and click on 'SIGN UP & JOIN' button""", ->
    before -> 
      # implement before hook 

    it """Are you signed up successfully?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You are almost there, {{ random.first_name }}{{ random.password }}!' title on a pop-up displayed in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.last_name }}{{ random.number }}' label on top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a little down arrow next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the pop-up by clicking (x) from top right corner and click on the little down arrow next to '{{ random.last_name }}{{ random.number }}'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Dashboard', 'Support', 'Change Team' and 'Logout' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Logout'""", ->
    before -> 
      # implement before hook 

    it """Are you logged out successfully?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Username or Email' and 'Your Password' text fields?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_SIGN IN' button below these fields??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'You are not allowed to access this team' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.email }}" in 'Username or Email' and "{{ random.number }}" in 'Password' field and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Access denied!' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

  describe """""", ->
    before -> 
      # implement before hook 

  describe """""", ->
    before -> 
      # implement before hook 

  describe """""", ->
    before -> 
      # implement before hook 


