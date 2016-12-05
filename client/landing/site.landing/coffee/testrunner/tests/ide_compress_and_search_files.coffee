$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_compress_and_search_files', ->
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

    describe "Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'zip command not found' modal window ( http://snag.gy/HnDfH.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Install package' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a terminal window with commands performing??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait when the process is finished, click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file '{{random.address_city}}{{random.number}}.txt.zip' in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .zip' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file '{{random.address_state}}{{random.number}}.zip' in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file '{{random.address_city}}{{random.number}}.txt.tar.gz' in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file '{{random.address_state}}{{random.number}}.tar.gz' in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click '.profile' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with this file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on down arrow on the rigth-side of '.profile' tab that you just opened and select 'Search in All Files'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a pop-up with 'Find', 'Where', 'Case Sensitive', 'Whole Word', 'Use regexp' texts??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'if' in 'Find' field, check all of the three checkboxes next to 'Case Sensitive', 'Whole Word' and 'Use regexp' fields and click on 'SEARCH'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is search result opened in a new tab?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is search term 'if' highlighted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on one of the highlighted search term?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is a file opened on a new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

