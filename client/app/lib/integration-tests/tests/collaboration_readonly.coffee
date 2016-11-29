$ = require 'jquery'
assert = require 'assert'

#! 4082ac87-57fb-467d-ab3f-74257131af94
# title: collaboration_readonly
# start_uri: /
# tags: automated
#

describe "collaboration_readonly.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Click Terminal tab and try to enter any command in the terminal""", ->
    before -> 
      # implement before hook 

    it """Are you unable to enter commands in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Try click '+' icon at the right of terminal and select New Terminal -> New Session ( http://snag.gy/UnOoo.jpg )""", ->
    before -> 
      # implement before hook 

    it """Are you unable to click this button or button is unavailable??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over 'aws-instance' item below the 'SHARED VMS' label and click '...' icon displayed (like on screenshot http://snag.gy/RhBjF.jpg)""", ->
    before -> 
      # implement before hook 

    it """Do you see popup with red 'LEAVE SESSION' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


