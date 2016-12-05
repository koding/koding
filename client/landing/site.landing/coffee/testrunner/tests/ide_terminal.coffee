$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_terminal', ->
    describe "Click down arrow icon at the right of '/home/Rainforestqa99' label at the top of file tree to open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New folder' in the menu?", ->
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


      it "Do you see a folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click to folder '{{random.address_state}}{{random.number}}' and then click to down arrow icon at the right hand of the folder. Click 'Terminal from here' in the menu opened ( http://snag.gy/a8gQD.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new terminal opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see ' ~/{{random.address_state}}{{random.number}}_' in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon in the terminal header and click 'Rename' in the menu ( http://snag.gy/KlOHf.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an edit mode for terminal tab title is displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'Terminal {{random.number}}' as a title and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is terminal tab renamed to  'Terminal {{random.number}}' ??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'sudo' in terminal and press Enter, type 'la' in terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see results of the commands in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon in the terminal header and click 'Suspend' in the menu ( http://snag.gy/KlOHf.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is terminal closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the terminal and mouse over 'New Terminal' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see menu with one or more 'Session (...)' items?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see at least one 'Session (...)' item that not-grayed (like on screenshot http://snag.gy/UUVSo.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over some not-grayed 'Session (...)' item in the menu and click 'Open' for this item?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal tab opened (restored)??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the terminal and mouse over 'New Terminal' section, mouse over some grayed 'Session (...)' item and click 'Terminate'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is one of the active terminals closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the terminal and mouse over 'New Terminal' section and click 'Terminate all' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are all terminal tabs closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Click 'No' on the 'Would you like us to remove the pane when there are no tabs left?' modal if it's displayed ( http://snag.gy/WynLF.jpg )?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Click '+' icon in the header where terminals were opened and click 'New Drawing Board' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see a new tab with drawing board opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Try to draw something using a mouse on the drawing board area?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Are you able to draw??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Refresh the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see all opened terminals, drawing boards are remembered??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the file name in the editor header and click 'Enter Fullscreen' ( http://snag.gy/rb5Po.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor displayed in fullscreen mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of the file name in the editor header and click 'Exit Fullscreen'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor displayed in normal mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Fullscreen' icon in the top right corner of the editor header ( http://snag.gy/YMM7u.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor displayed in fullscreen mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click again 'Fullscreen' icon in the top right corner of the editor header ( http://snag.gy/YMM7u.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor displayed in normal mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

