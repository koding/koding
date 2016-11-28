$ = require 'jquery'
assert = require 'assert'

#! 3893fd34-0891-4675-af63-929766998e36
# title: collaboration_create_newfile_from_IDE
# start_uri: /
# tags: automated
#

describe "collaboration_create_newfile_from_IDE.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the warning and click  down arrow icon at the right of /home/{{random.first_name}}{{random.number}} label in the center part of the page and click 'New file' in the menu (like on screenshot http://snag.gy/nJ2Dd.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see new file 'NewFile.txt' added to the file tree?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is file name displayed in edit mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'file2.txt' file name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see file 'file2.txt' with green icon in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the 'file2.txt' file""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


