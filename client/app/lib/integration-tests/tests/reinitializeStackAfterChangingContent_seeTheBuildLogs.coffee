$ = require 'jquery'
assert = require 'assert'

#! 67cab4a5-5132-46a5-afa0-8f10dd8fe2c0
# title: reinitializeStackAfterChangingContent_seeTheBuildLogs
# start_uri: /
# tags: automated
#

describe "reinitializeStackAfterChangingContent_seeTheBuildLogs.rfml", ->
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


  describe """Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a while for process to be completed""", ->
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


  describe """Click on the 'NEXT' button and then click on the 'BUILD STACK'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green progress bar also below 'aws-instance' label on left sidebar??""", -> 
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

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the tab where it says 'Terminal', type "ls /" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Do you see the green colored 'helloworld.txt' file in the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the little down arrow next to '/home/rainforestqa99' label on top of file list next to left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Refresh', 'Collapse', 'Change top folder', 'New file', 'New folder' and 'Toggle invisible files' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'New file'""", ->
    before -> 
      # implement before hook 

    it """Is 'NewFile.txt' added to the end of the file list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Delete 'NewFile', enter "{{ random.first_name }}" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Is the new file saved as '{{ random.first_name }}.txt'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the tab where it says 'Terminal' again, then type "ls" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Do you see the green colored '{{ random.first_name }}.txt' file only??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '_Aws Stack' from left sidebar, then click on 'Reinitialize' and 'PROCEED' respectively""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title on the modal in the center of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button and then click on the 'BUILD STACK'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green progress bar also below 'aws-instance' label on left sidebar??""", -> 
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


  describe """Click on 'View the Logs' button""", ->
    before -> 
      # implement before hook 

    it """Is that success modal closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see something like in this image: http://take.ms/S2PPR?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that '{{ random.first_name }}.txt' is not listed in the file list anymore??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the tab where it says 'Terminal', type "ls" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Do you see that nothing is returned as a result and just 'rainforestqa99@rainforestqa99:~$_' is displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


