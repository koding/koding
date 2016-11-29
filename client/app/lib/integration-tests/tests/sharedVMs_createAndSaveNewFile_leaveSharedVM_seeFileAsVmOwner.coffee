$ = require 'jquery'
assert = require 'assert'

#! 4527133c-24bf-497d-ad28-e29c895d11da
# title: sharedVMs_createAndSaveNewFile_leaveSharedVM_seeFileAsVmOwner
# start_uri: /
# tags: automated
#

describe "sharedVMs_createAndSaveNewFile_leaveSharedVM_seeFileAsVmOwner.rfml", ->
  before -> 
    require './enable_VM_sharing_invite_Member.coffee'

  describe """Click on the '+' next to 'Terminal' tab and select 'New File'""", ->
    before -> 
      # implement before hook 

    it """Is 'Untitled.txt' added to that pane??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type "{{ random.full_name }}" in it, click on the little down arrow next to 'Untitled.txt' and select 'Save'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Filename:' title and a text field with 'Untitled.txt' in it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Select a folder:' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SAVE' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type "{{ random.first_name }}" instead of 'Untitled' and click on 'SAVE' button""", ->
    before -> 
      # implement before hook 

    it """Is '{{ random.first_name }}.txt' added to the pane instead of 'Untitled.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it also added to the end of file list under '/home/rainforestqa99'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'test(@rainforestqa99)' label on left sidebar under 'SHARED VMS' and click on the button appeared next to it""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Shared with you by' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '@rainforestqa99'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'LEAVE SHARED VM' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'LEAVE SHARED VM' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'This will remove the shared VM from your sidebar.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'YES' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES'""", ->
    before -> 
      # implement before hook 

    it """Are 'SHARED VMS' and 'test(@rainforestqa99)' removed from left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to '_Aws Stack?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that '/home/rainforestqa99' label and 'Terminal' tab are not displayed anymore??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and close that modal by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see '{{ random.first_name }}.txt' at the end of file list under '/home/rainforestqa99' next to left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the '{{ random.first_name }}.txt' file""", ->
    before -> 
      # implement before hook 

    it """Do you see it opened as a new tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.full_name }}' in it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


