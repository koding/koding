$ = require 'jquery'
assert = require 'assert'

#! e849b38d-26de-482f-bb58-a3e1bfe211b4
# title: collaboration_delete_file
# start_uri: /
# tags: automated
#

describe "collaboration_delete_file.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the warning and click  down arrow icon at the right of /home/rainforestqa99 label in the center part of the page, click 'New file' in the menu (like on screenshot http://snag.gy/nJ2Dd.jpg ) and enter 'file{{random.number}}.txt' file name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see file 'file{{random.number}}.txt' with green icon in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of 'file{{random.number}}.txt' file in the file tree and click 'Delete' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' text and red 'Delete' button above the file name??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'DELETE' button""", ->
    before -> 
      # implement before hook 

    it """Is 'file{{random.number}}.txt' file deleted from file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed""", ->
    before -> 
      # implement before hook 

    it """Do you see the uploaded file under the filetree?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'file{{random.number}}.txt' file removed from file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


