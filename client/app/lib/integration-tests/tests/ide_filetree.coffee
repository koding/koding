$ = require 'jquery'
assert = require 'assert'

#! 3f91dd92-2a3c-4d2b-9afb-e9a8566c178d
# title: ide_filetree
# start_uri: /
# tags: automated
#

describe "ide_filetree.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Click 'Collapse' in the menu""", ->
    before -> 
      # implement before hook 

    it """Is file tree collapsed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """You should see an empty file tree.?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open filetree menu again and click 'Expand'""", ->
    before -> 
      # implement before hook 

    it """Is file tree expanded?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """You should see all files and folders.?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open filetree menu again, mouse over 'Change top folder' and click '/home'""", ->
    before -> 
      # implement before hook 

    it """Is top folder in the file tree changed to '/home' ?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'ubuntu' and 'Rainforestqa99' folders in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open menu for the  'Rainforestqa99' folder and click 'Make this the top folder' ( http://snag.gy/vhS2b.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is top folder in the file tree changed to '/home/Rainforestqa99'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New folder' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see new folder 'NewFolder' added to the file tree?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is folder name displayed in edit mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '{{random.address_state}}{{random.number}}' folder name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open filetree menu and click 'New file'""", ->
    before -> 
      # implement before hook 

    it """Do you see new file 'NewFile.txt' added to the file tree?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is file name displayed in edit mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '{{random.address_city}}{{random.number}}.txt' file name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see file '{{random.address_city}}{{random.number}}.txt' with green icon in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click  file '{{random.address_city}}{{random.number}}.txt' in the file tree and then drag&drop it to the '{{random.address_state}}{{random.number}}' folder""", ->
    before -> 
      # implement before hook 

    it """Is file moved to the '{{random.address_state}}{{random.number}}' folder??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open the filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'Toggle invisible files ' in the menu""", ->
    before -> 
      # implement before hook 

    it """Are system files and folders hidden in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open the filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'Toggle invisible files ' in the menu again""", ->
    before -> 
      # implement before hook 

    it """Are system files and folders displayed in the filetree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the file tree header and click collapse icon ( http://snag.gy/VO3k2.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is file tree collapsed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click folder icon in the file tree header""", ->
    before -> 
      # implement before hook 

    it """Is file tree displayed again??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click '.profile' file in the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see new editor tab opened with this file content??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Drag&drop the '.profile' to other pane""", ->
    before -> 
      # implement before hook 

    it """Is file moved to the other pane??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

