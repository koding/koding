$ = require 'jquery'
assert = require 'assert'

#! e70f834c-0ad9-44ed-9d72-c09f3d57b6fd
# title: createTeam_usingAlreadyRegisteredEmail_afterClickingFreshAccount
# start_uri: /
# tags: automated
#

describe "createTeam_usingAlreadyRegisteredEmail_afterClickingFreshAccount.rfml", ->
  describe """Click on the 'create a new team' link below the form where it says 'Welcome! Enter your team's Koding domain.'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Let's sign you up!' form with 'Email Address' and 'Team Name' text fields and a 'NEXT' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in the 'Email Address' and "{{ random.last_name }}{{ random.number }}" in the 'Team Name' fields and click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team URL' form with 'Your Team URL' field prefilled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Hey rainforestqa22,' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Password' input field?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Not you?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Create with a fresh account!' text below that field?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE YOUR TEAM' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'fresh account!' link""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your account' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the first text box is prefilled with 'rainforestqa22@koding.com'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Username' and 'Your Password' fields?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Already have an account?' link below the text fields??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Already have an account?' link""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please enter your sandbox.koding.com username & password.' texts?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Username or Email' and 'Your Password' text fields?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Are you_rainforestqa22?' text below the text fields??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.first_name }}{{ random.number }}" in the 'Username or Email' and "{{ random.password }}" in the 'Your Password' field and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen '_Unknown user name_' warning message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.email }}" in the 'Username or Email' and "{{ random.password }}" in the 'Your Password' field and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Unrecognized email' warning message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in the 'Username or Email' and "{{ random.password }}" in the 'Your Password' field and click on 'CREATE YOUR TEAM' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Access denied!' warning message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" in the 'Your Password' field and click on 'CREATE YOUR TEAM' button, then if you see 'Authentication Required' form enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are almost there, rainforestqa22!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


