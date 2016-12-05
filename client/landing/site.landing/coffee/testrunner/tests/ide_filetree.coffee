$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_filetree', ->
    describe "Click down arrow icon at the right of '/home/Rainforestqa99' label at the top of file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see menu expanded like on screenshot http://snag.gy/Rmoax.jpg (it's Filetree menu)??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Collapse' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file tree collapsed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "You should see an empty file tree.?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open filetree menu again and click 'Expand'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file tree expanded?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "You should see all files and folders.?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open filetree menu again, mouse over 'Change top folder' and click '/home'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is top folder in the file tree changed to '/home' ?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'ubuntu' and 'Rainforestqa99' folders in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the  'Rainforestqa99' folder and click 'Make this the top folder' ( http://snag.gy/vhS2b.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is top folder in the file tree changed to '/home/Rainforestqa99'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

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

    describe "Click  file '{{random.address_city}}{{random.number}}.txt' in the file tree and then drag&drop it to the '{{random.address_state}}{{random.number}}' folder?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file moved to the '{{random.address_state}}{{random.number}}' folder??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open the filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'Toggle invisible files ' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are system files and folders hidden in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open the filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'Toggle invisible files ' in the menu again?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are system files and folders displayed in the filetree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the file tree header and click collapse icon ( http://snag.gy/VO3k2.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file tree collapsed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click folder icon in the file tree header?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file tree displayed again??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click '.profile' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with this file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Drag&drop the '.profile' to other pane?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file moved to the other pane??", (done) -> 
        assert(false, 'Not Implemented')
        done()

