$ = require 'jquery'
assert = require 'assert'

#! 9566a91a-902c-4ebe-b81f-a4d4f56e00ef
# title: collaboration_permission_revoke_grant
# start_uri: /
# tags: automated
#

describe "collaboration_permission_revoke_grant.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch back to main window. Move mouse over to user icon at the left of 'END COLLABORATION' button""", ->
    before -> 
      # implement before hook 

    it """Do you see a popup menu with 'Revoke Permission' item??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Revoke Permission'""", ->
    before -> 
      # implement before hook 

    it """Is popup removed from the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see red warning 'ACCESS REVOKED: Host revoked your access to control their session!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click close icon on the red warning""", ->
    before -> 
      # implement before hook 

    it """Is warning removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Try to click 'Untitled.txt' file at the editor area and enter any text in the editor area""", ->
    before -> 
      # implement before hook 

    it """Do you see the orange warning 'WARNING: You don't have permission to make changes. Ask for permission.'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Ask for permissions' link""", ->
    before -> 
      # implement before hook 

    it """Is warning removed from the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the other browser window where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see an user icon at the left of 'END COLLABORATION' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'is asking for permission to make changes' popup with DENY and GRANT PERMISSIONS actions' (like http://snag.gy/591AD.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'GRANT PERMISSIONS '""", ->
    before -> 
      # implement before hook 

    it """Is popup removed from the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!' at the top of the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


