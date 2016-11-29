$ = require 'jquery'
assert = require 'assert'

#! 2ffd6341-1ab2-441d-b33e-f259f47a5f73
# title: turnVmOnAndOff
# start_uri: /
# tags: automated
#

describe "turnVmOnAndOff.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

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

    it """Do you see '# Here is your stack preview' in the first line of main content?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PREVIEW', 'LOGS', 'DELETE THIS STACK TEMPLATE' buttons on the bottom and 'SAVE' button on top right??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')""", ->
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


  describe """Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' and BUILD STACK buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green progress bar below 'aws-instance' label on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few minutes for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Success! Your stack has been built.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see START CODING button on the bottom??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on START CODING, then move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it""", ->
    before -> 
      # implement before hook 

    it """Has a pop-up appeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-inst_' under 'Virtual Machines' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the toggle button that's in 'ON' state, next to 'VM Power' and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Is the label updated as 'OFF'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it turned to gray?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Has a red progress bar appeared below 'aws-inst_' label and then disappeared after the process is completed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the same toggle button again (next to 'VM Power')""", ->
    before -> 
      # implement before hook 

    it """Is the label updated as 'ON'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it turned to green?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Has a green progress bar appeared below 'aws-inst_' label??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the pop-up by clicking on (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Boot Virtual Machine' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Spinning up aws-instance' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a blue progress bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few minutes for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your VM has finished Booting' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'START USING MY VM' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'START USING MY VM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it again""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-inst_' under 'Virtual Machines' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the toggle button that's in 'ON' state, next to 'VM Power' and then close the modal by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Turn Off VM' titled pop-up in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-instance is Being Turned Off' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stopping VM...' text in a red progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(if the process is already completed it's OK that you don't see the previous items and 'Boot Virtual Machine' titled pop-up instead)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Boot Virtual Machine' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Let's Boot up aws-instance' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'TURN VM ON' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'TURN VM ON' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Boot Virtual Machine' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Spinning up aws-instance' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a blue progress bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few minutes for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your VM has finished Booting' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'START USING MY VM' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


