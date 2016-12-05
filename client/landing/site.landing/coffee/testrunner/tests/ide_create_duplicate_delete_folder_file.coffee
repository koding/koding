$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_create_duplicate_delete_folder_file', ->
    describe "Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New folder' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new folder 'NewFolder' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is folder name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{random.address_state}}{{random.number}}' folder name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Duplicate' in the menu ( http://snag.gy/a8gQD.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new folder '{{random.address_state}}{{random.number}}_1' created??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open filetree menu and click 'New file'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file 'NewFile.txt' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is file name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{random.address_city}}{{random.number}}.txt' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file '{{random.address_city}}{{random.number}}.txt' with green icon in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Watch file' ( http://snag.gy/R0uxS.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab with file content opened and green message 'This is a file watcher, which allows you to ...' displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Try to enter some text in the editor?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to enter any text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file '{{random.address_city}}{{random.number}}.txt' is opened and click 'x' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor tab closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the '{{random.address_city}}{{random.number}}.txt' file in file tree and click 'Duplicate'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file '{{random.address_city}}{{random.number}}_1.txt' displayed in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the '{{random.address_city}}{{random.number}}_1.txt' file in file tree and click 'Rename'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file name displayed in edit mode in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{random.address_city}}{{random.number}}_renamed.txt' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file name changed to '{{random.address_city}}{{random.number}}_renamed.txt' and file is displayed in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click any file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon in the header where new files were opened and click 'New File'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened and file name is 'untitled.txt'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of  '{{random.address_city}}{{random.number}}.txt' file in the file tree and click 'Delete' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' text and red 'Delete' button above the file name??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Delete' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file deleted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree and click 'Delete' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' text and red 'Delete' button above the folder name??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Delete' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is folder deleted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

