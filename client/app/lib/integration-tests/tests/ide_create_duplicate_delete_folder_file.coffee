$ = require 'jquery'
assert = require 'assert'

#! 5b895b3b-d10f-4a16-88ba-0b2126d4475a
# title: ide_create_duplicate_delete_folder_file
# start_uri: /
# tags: automated
#

describe "ide_create_duplicate_delete_folder_file.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Enter '{{random.address_state}}{{random.number}}' folder name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Duplicate' in the menu ( http://snag.gy/a8gQD.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see a new folder '{{random.address_state}}{{random.number}}_1' created??""", -> 
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


  describe """Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Watch file' ( http://snag.gy/R0uxS.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see new editor tab with file content opened and green message 'This is a file watcher, which allows you to ...' displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Try to enter some text in the editor""", ->
    before -> 
      # implement before hook 

    it """Are you unable to enter any text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file '{{random.address_city}}{{random.number}}.txt' is opened and click 'x' icon""", ->
    before -> 
      # implement before hook 

    it """Is editor tab closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Duplicate'""", ->
    before -> 
      # implement before hook 

    it """Do you see new file '{{random.address_city}}{{random.number}}_1.txt' displayed in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open menu for the '{{random.address_city}}{{random.number}}_1.txt' file in file tree and click 'Rename'""", ->
    before -> 
      # implement before hook 

    it """Is file name displayed in edit mode in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '{{random.address_city}}{{random.number}}_renamed.txt' file name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Is file name changed to '{{random.address_city}}{{random.number}}_renamed.txt' and file is displayed in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click any file in the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon in the header where new files were opened and click 'New File'""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened and file name is 'untitled.txt'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of  '{{random.address_city}}{{random.number}}.txt' file in the file tree and click 'Delete' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' text and red 'Delete' button above the file name??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Delete' button""", ->
    before -> 
      # implement before hook 

    it """Is file deleted??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Delete' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' text and red 'Delete' button above the folder name??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Delete' button""", ->
    before -> 
      # implement before hook 

    it """Is folder deleted??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


