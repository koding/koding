$ = require 'jquery'
assert = require 'assert'

#! ad4bd321-2d54-40a5-b8c6-f0abada10506
# title: collaboration_endcollaboration
# start_uri: /
# tags: automated
#

describe "collaboration_endcollaboration.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Click on 'END COLLABORATION' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'YES' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES' and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Has 'END COLLABORATION' button on the bottom changed to 'START COLLABORATION'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'Camera' icon removed from the bottom status bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Session ended' title pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'LEAVE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'LEAVE' button""", ->
    before -> 
      # implement before hook 

    it """Is 'aws-instance' item removed from the left module and all panes from that VM closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


