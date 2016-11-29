$ = require 'jquery'
assert = require 'assert'

#! 346f3aea-31bd-4dbf-bbc0-74e6931ffe0a
# title: collaboration_watchfile_kick_invite_user
# start_uri: /
# tags: automated
#

describe "collaboration_watchfile_kick_invite_user.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the other browser window where you are logged in as 'rainforestqa99', click 'Untitled.txt' file at the editor area and type '{{random.address_city}}' in the first row, Mouse over 'Untitled.txt', click down arrow icon displayed and click Save in menu (like on screenshot http://snag.gy/zNMRr.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see a new modal with 'Filename', 'Select a folder' fields and 'Save' and 'Cancel' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'file1.txt' in the 'Filename' field and click 'Save'""", ->
    before -> 
      # implement before hook 

    it """Is modal closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the 'file1.txt' title of the opened file instead of 'Untitled.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the file 'file1.txt' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see the 'file1.txt' file in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch back to the first window and move your mouse over default avatar icon next to 'END COLLABORATION' button (like on the screenshot http://snag.gy/UWgYw.jpg ),click on 'Kick' in the menu. Wait for a couple of seconds and then click on 'END COLLABORATION' button""", ->
    before -> 
      # implement before hook 

    it """Is user icon removed from the bottom navigation bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Has 'Session End' dialog not displayed (it shouldn't be displayed)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'LEAVE SESSION' button not visible anymore?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your session has been closed' titled pop-up??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window, click  'START COLLABORATION' button in the bottom right corner and click on the shortened URL in the bottom status bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Copied to clipboard!' popup message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window and paste copied URL in the browser address bar and press enter""", ->
    before -> 
      # implement before hook 

    it """Do you see 'SHARED VMS' label in the left module on the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-instance_' item below the 'SHARED VMS' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see white popup with 'Reject' and 'Accept' buttons??""", -> 
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


