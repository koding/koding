$ = require 'jquery'
assert = require 'assert'

#! 1ae7b10f-f120-47de-bc67-eae94efbd491
# title: create_team_with_existing_account
# start_uri: /
# tags: embedded
#

describe "create_team_with_existing_account.rfml", ->
  describe """Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa99@koding.com" in the 'Email Address' and "{{ random.last_name }}{{ random.number }}" in the 'Team Name' fields and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team URL' form with 'Your Team URL' field prefilled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Hey rainforestqa99,' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Password' input field?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE YOUR TEAM' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa99" in the password field and click on 'CREATE YOUR TEAM' button,(if you see 'Your login access is blocked for 1 minute' message, check that you entered "rainforestqa99" and try again after waiting 1 minute)  then if you see 'Authentication Required' form enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are almost there, rainforestqa99!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


