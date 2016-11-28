$ = require 'jquery'
assert = require 'assert'

#! 986368ca-bef2-4ee3-9b97-717d068f6ee3
# title: create_team_with_failures
# start_uri: /
# tags: automated
#

describe "create_team_with_failures.rfml", ->
  describe """Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please type a valid email address.' warning?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Please enter a team name.' warning??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.email }}" in the 'Email Address' and enter "test" in 'Team Name' fields and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team URL' form with 'Your Team URL' field prefilled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Delete the prefilled URL and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Domain name should be longer than 2 characters!' warning?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the red border around the text field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'sandbox' and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invalid domain!' warning?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the red border around the text field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'koding' and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Domain is taken!' warning?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the red border around the text field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '{{ random.last_name }}{{ random.number }}' as converted to uppercase and click on 'NEXT' button """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Your account' form with 'Email address' field prefilled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Leave 'Your Username' and 'Your Password' fields empty and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'For username only lowercase letters and numbers are allowed!' and 'Passwords should be at least 8 characters.' warnings?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the red border around the text fields??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'aaa' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Username should be between 4 and 25 characters!' warning?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the red border around the text field for username??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'koding' in the username, and '{{ random.password }}' in the password fields and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Sorry, "koding" is already taken!' warning??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '{{ random.first_name }}{{ random.number }}' as converted to uppercase in the username field and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Authentication Required' form?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """If not do you see 'You are almost there,_' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


