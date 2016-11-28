$ = require 'jquery'
assert = require 'assert'

#! 5e284d48-6055-49c0-91ea-c73681036aca
# title: create_team_with_existing_user_stack_related
# start_uri: /
# tags: embedded
#

describe "create_team_with_existing_user_stack_related.rfml", ->
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


  describe """Click on 'Create a Stack for Your Team' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Select a Provider' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'amazon web services', 'VAGRANT', 'Google Cloud Platform', 'DigitalOcean', 'Azure' and 'Softlayer'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'CREATE STACK' buttons below??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'amazon web services' and then click on 'CREATE STACK' button""", ->
    before -> 
      # implement before hook 

    it """Has that pop-up disappeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stack Template', 'Custom Variables', 'Readme' tabs?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Credentials' text having a red (!) next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see (# Here is your stack preview) in the first line of main content?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PREVIEW', 'LOGS' buttons and 'DELETE THIS STACK TEMPLATE' link on the bottom and 'SAVE' button on top right??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' tab and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Verifying Credentials...' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to 'Stack Template' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Share Your Stack_' title on a pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'SHARE WITH THE TEAM' button and then click on the 'YES' button and wait for a while for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button and then click on the BUILD STACK button and wait for a few minutes for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Success! Your stack has been built.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'View The Logs', 'Connect Your Local Machine' and 'Invite to Collaborate' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a red button at the bottom right corner??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to red button at the bottom right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-out_' file on top and 'Terminal' tab on the bottom pane??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


