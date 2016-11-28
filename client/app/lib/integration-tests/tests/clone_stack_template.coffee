$ = require 'jquery'
assert = require 'assert'

#! 2fa800c1-be4c-4834-9343-736a2889a77a
# title: clone_stack_template
# start_uri: /
# tags: automated
#

describe "clone_stack_template.rfml", ->
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

    it """Do you see 'Share Your Stack' title on a pop-up displayed?""", -> 
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

    it """Do you see 'Read Me' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '_Aws Stack' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Edit', 'Clone', 'Reinitialize', 'VMs', 'Destroy VMs' and 'Make Team Default' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Clone'""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Cloning Stack Template' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is a new item added to left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack - clone' title and 'Clone Of _Aws Stack' text on top??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '_Aws Stack' link next to 'Clone Of' text""", ->
    before -> 
      # implement before hook 

    it """Are you directed to '_Aws Stack'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'Clone Of _Aws Stack' removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the second '_Aws Stack_' from left sidebar and select 'Edit'""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack - clone' title and 'Clone Of _Aws Stack' text on top?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'SAVE' button on top right??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Share Your Stack' title on a pop-up displayed?""", -> 
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

    it """Do you see '_Aws Stack - clone' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack_' and 'aws-instance-1' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' and BUILD STACK buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar??""", -> 
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


  describe """Click on START CODING button""", ->
    before -> 
      # implement before hook 

    it """Do you see a green square next to 'aws-instance-1' label on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


