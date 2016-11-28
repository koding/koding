$ = require 'jquery'
assert = require 'assert'

#! 7c4ba86a-3df9-49fc-9460-b5e10685ae26
# title: sharedVMs_reject_inviteAgain_accept_checkTerminalActions
# start_uri: /
# tags: automated
#

describe "sharedVMs_reject_inviteAgain_accept_checkTerminalActions.rfml", ->
  before -> 
    require './enable_VM_sharing_invite_Member.coffee'

  describe """Switch back to first window and move your mouse over 'test' label on left sidebar and click on the circle button appeared next to it. Scroll down until you see 'VM Sharing'. Click on the toggle button next to 'VM Sharing'""", ->
    before -> 
      # implement before hook 

    it """Is the label updated as 'OFF'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it turned to gray??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to toggle button next to 'VM Sharing' and then enter 'rainforestqa22' in the text box again, hit enter and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Is 'rainforestqa22' added below 'Type a username' text box?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'This VM has not yet been shared with anyone.' text removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window and click on 'ACCEPT' button this time""", ->
    before -> 
      # implement before hook 

    it """Do you see '/home/rainforestqa99' label on top of a file list next to left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Terminal' tab on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa99@rainforestqa99:~$' in that 'Terminal' tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the tab where it says 'Terminal', type "expr 5 + 5" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Do you see '10' as a result??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the '+' next to 'Terminal' tab""", ->
    before -> 
      # implement before hook 

    it """Do you see 'New File', 'New Terminal', 'New Drawing Board', 'Split Vertically', 'Split Horizontally' and 'Enter Fullscreen' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'New Terminal' and select 'New Session'""", ->
    before -> 
      # implement before hook 

    it """Is a new 'Terminal' tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa99@rainforestqa99:~$' in it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type "expr 5 + 5" and hit enter""", ->
    before -> 
      # implement before hook 

    it """Do you see '10' as a result??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


