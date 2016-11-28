$ = require 'jquery'
assert = require 'assert'

#! ee23bc2e-ae8b-4543-b277-0abbb483b65f
# title: collaboration_permission_deny
# start_uri: /
# tags: automated
#

describe "collaboration_permission_deny.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

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


  describe """Click 'DENY'""", ->
    before -> 
      # implement before hook 

    it """Is popup removed from the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see red warning 'REQUEST DENIED: Host has denied your request to make changes!' at the top of the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the other browser window where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see the 'END COLLABORATION' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over user icon at the left of 'END COLLABORATION' button""", ->
    before -> 
      # implement before hook 

    it """Do you see a popup menu with 'Make Presenter' item ( http://snag.gy/0Ml1X.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Make Presenter'""", ->
    before -> 
      # implement before hook 

    it """Is popup removed from the screen??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return the browser where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see an user icon at the left of 'END COLLABORATION' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

