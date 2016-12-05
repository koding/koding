$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_split_merge_panes', ->
    describe "Click on the (+) button next to the tabs on that pane and select 'Split Horizontally' option?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the view splitted to two pieces as top and bottom panes??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the close button (x) on the pane that you want to close?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the tabs merged ??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the (+) button from top left corner of the bottom pane and select 'Split Vertically' option?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is that pane splitted to the right and left sections??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the close button (x) on the pane that you want to close?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the tabs merged ??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click '.profile' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with this file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click and hold the file tab titled '.profile' and drag it to bottom half of editor area and hold it for a couple of seconds and release?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you see the 'Drop to move source pane to this split' message in green backfround?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Did pane split in half after you released??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the (x) icon appearing when you mouse over the top right corner or the 'bottom' pane until there's nothing left on the bottom pane?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is bottom pane removed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is there only one pane left??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the top right corner of the remaining pane?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is (x) icon not visible there?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(It shouldn't be visible when there's only one pane left)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click settings icon at the top of the filetree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Editor Settings' instead of filetree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click file tree icon next to settings icon at the top of the filetree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file tree again??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Save image from here: {{ random.image }} to your desktop, return to the first browser and drag and drop image to the Filetree under '/home/rainforestqa99' label (like in the screencast: http://recordit.co/KRArrgJ8Gs)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it added to the end of Filetree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click '.profile' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with this file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'se' in the last row in '.profile' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are suggestions for autocomplete displayed as a dropdown??", (done) -> 
        assert(false, 'Not Implemented')
        done()

