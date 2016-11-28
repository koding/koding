$ = require 'jquery'
assert = require 'assert'

#! c1037c00-d213-4fda-ab35-e2d6adae95ad
# title: sharedVMs_accept_remove_inviteAgain
# start_uri: /
# tags: automated
#

describe "sharedVMs_accept_remove_inviteAgain.rfml", ->
  before -> 
    require './enable_VM_sharing_invite_Member.coffee'

  describe """Click on 'STACKS' title from left sidebar and switch to 'Virtual Machines' tab on top of the pop-up displayed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'test' under 'Shared Machines' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'SHARED MACHINE' label next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that pop-up by clicking (x) from top right corner, return to the first browser and move your mouse over 'rainforestqa22'""", ->
    before -> 
      # implement before hook 

    it """Do you see a red (x) appeared next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on (x) that has appeared""", ->
    before -> 
      # implement before hook 

    it """Is 'rainforestqa22' removed from the list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'This VM has not yet been shared with anyone.' text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see a pop-up with 'Machine access revoked' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your access to this machine has been removed by its owner.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'OK' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'OK'""", ->
    before -> 
      # implement before hook 

    it """Are you swithced to '_Aws Stack'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'test' is removed from left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that '/home/rainforestqa99' label and 'Terminal' tab are not displayed anymore??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, enter 'rainforestqa22' in the text box, hit enter and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Is 'rainforestqa22' added below 'Type a username' text box?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'This VM has not yet been shared with anyone.' text removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'test(@rainforestqa99)' below 'SHARED VMS' title on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a pop-up appeared next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'wants to share their VM with you.' text in that pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you also see 'REJECT' and 'ACCEPT' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


