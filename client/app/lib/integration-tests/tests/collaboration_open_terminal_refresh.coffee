$ = require 'jquery'
assert = require 'assert'

#! e0360357-8e1e-46b2-9f60-3a9ec5157cfa
# title: collaboration_open_terminal_refresh
# start_uri: /
# tags: automated
#

describe "collaboration_open_terminal_refresh.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click + icon in the editor area and click 'New Session' in the 'New Terminal' section of the menu (like on screenshot http://snag.gy/jJiod.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see a new terminal tab opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Remember the list of editors and terminals opened and return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed""", ->
    before -> 
      # implement before hook 

    it """Do you see a new terminal tab opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click refresh icon in the browser""", ->
    before -> 
      # implement before hook 

    it """Do you see the same list of editors and terminals after refreshing??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Minimize the window of the browser and return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see the same list of editors and terminals??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


