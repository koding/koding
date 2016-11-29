$ = require 'jquery'
assert = require 'assert'

#! 6316a6f6-dd17-4574-aace-f1a95228e641
# title: collaboration_run_terminal
# start_uri: /
# tags: automated
#

describe "collaboration_run_terminal.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """You can close the warning message by clicking to (x) at right end.?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)""", ->
    before -> 
      # implement before hook 

    it """Do you see new terminal tab opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type 'sudo' in terminal and press Enter, type 'la' in terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see results of the commands in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed""", ->
    before -> 
      # implement before hook 

    it """Do you see new terminal with commands 'sudo' and 'la' performed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


