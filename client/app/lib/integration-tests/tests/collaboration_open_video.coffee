$ = require 'jquery'
assert = require 'assert'

#! 16f35b73-ace6-4567-a934-4256b725092f
# title: collaboration_open_video
# start_uri: /
# tags: automated
#

describe "collaboration_open_video.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the other browser window where you are logged in as 'rainforestqa99' and Click on 'camera' icon at the left of 'END COLLABORATION'""", ->
    before -> 
      # implement before hook 

    it """Is new tab opened with 'https://appear.in/koding_' url in the address bar above?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see both users on the screen?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'LEAVE' button top of the video??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see both users on the screen?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'LEAVE' button top of the video??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'LEAVE' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Thank you for using appear.in' text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the tab""", ->
    before -> 
      # implement before hook 

    it """Do you see opened id?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'LEAVE SESSION' on status bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window where you are logged in as 'rainforestqa99' and Click on 'LEAVE' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Thank you for using appear.in' text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the tab""", ->
    before -> 
      # implement before hook 

    it """Do you see opened id?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'END COLLABORATION' on status bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 


