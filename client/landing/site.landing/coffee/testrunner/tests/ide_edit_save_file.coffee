$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_edit_save_file', ->
    describe "Click to arrow next to /home/rainforestqa99 in the middle section and then click to 'New File' in menu displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file 'NewFile.txt' added to the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'file{{random.number}}.txt' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'file{{random.number}}.txt' with green icon in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the 'file{{random.number}}.txt' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' text in the editor?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see text you have entered as it is??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file 'file{{random.number}}.txt'  is opened and click down arrow icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see Menu with 'Save', 'Save As...' and other items (like on screenshot http://snag.gy/7yOOm.jpg)??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Save' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you not see any error??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Make some changes in the editor, Mouse over the editor header where the file 'file{{random.number}}.txt' is opened, click down arrow icon and Click 'Save As...' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the form with 'Filename', 'Select a folder' field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'newfile{{random.number}}.txt' file name, select '.config' in 'Select a folder' field and click 'SAVE'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for 'newfile{{random.number}}.txt' file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '.config' in file tree list on the left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the 'newfile{{random.number}}.txt' file under '.config' folder??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file 'newfile{{random.number}}.txt' is opened and click 'x' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor tab closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a pop-up with 'Do you want to save your changes?' title??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'DON'T SAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the editor tab closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the 'file{{random.number}}.txt' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the same file content you entered before for the original file ('Lorem ipsum...')??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click second row in the editor, type some random text, press Enter and type some random text againg?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is entered text displayed correctly in the editor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Do you want to save your changes?' modal displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Don't save' and 'Save and Close' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click to 'Save and close' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is overlay closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is editor tab with 'file{{random.number}}.txt' file also closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the 'file{{random.number}}.txt' file in the filetree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the same file content you entered before closing??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Make some changes in the editor, mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon and click 'Don't save' button on the modal?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is overlay closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is editor tab with 'file{{random.number}}.txt' file also closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the 'file{{random.number}}.txt' file in the filetree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file without the changes from previous step??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Make some changes in the editor and click 'Ctrl+Option+W (Ctrl+Alt+W)' shortcut?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see 'Do you want to save your changes?' modal displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Cancel', 'Don't save' and 'Save and close' buttons on the modal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

