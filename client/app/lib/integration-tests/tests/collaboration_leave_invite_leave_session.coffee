$ = require 'jquery'
assert = require 'assert'

#! 376852f2-de90-4149-b518-6010dbf536ab
# title: collaboration_leave_invite_leave_session
# start_uri: /
# tags: automated
#

describe "collaboration_leave_invite_leave_session.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Click on 'YES'""", ->
    before -> 
      # implement before hook 

    it """Are 'aws-instance' item removed from the left module and all panes from that VM closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the other browser window where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see the only 'camera' icon at the left of 'END COLLABORATION' button without any other icons/avatars??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click shortened URL in the bottom status bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Copied to clipboard!' popup message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the incognito window and paste copied URL in the browser address bar and press enter""", ->
    before -> 
      # implement before hook 

    it """Wait until you see 'SHARED VMS' label in the left module?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-instance_' item below the 'SHARED VMS' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a white popup and two buttons named 'Reject' and 'Accept'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Accept' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Joining to collaboration session' progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the same panes (terminal, untitled.txt) like on the browser where you are logged in as 'rainforestqa99'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'LEAVE SESSION' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' dialog??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES'""", ->
    before -> 
      # implement before hook 

    it """Is 'aws-instance_' under 'Shared VM's section removed from the left module and all panes from that VM closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the other browser window where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see the only 'camera' icon at the left of 'END COLLABORATION' button without any other icons/avatars??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'END COLLABORATION' button and click 'Yes' on the 'Are you sure?' dialog""", ->
    before -> 
      # implement before hook 

    it """Is 'END COLLABORATION' button changed to 'START COLLABORATION'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'Camera' icon removed from the bottom status bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


