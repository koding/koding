$ = require 'jquery'
assert = require 'assert'

#! acdea8d7-8ef5-434a-850b-fc0cda42a2c0
# title: ide_compress_and_search_files.rfml
# start_uri: /
# tags: automated
#

describe "ide_compress_and_search_files.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

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


  describe """Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'zip command not found' modal window ( http://snag.gy/HnDfH.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Install package' button""", ->
    before -> 
      # implement before hook 

    it """Do you see a terminal window with commands performing??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait when the process is finished, click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .zip' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see a new file '{{random.address_city}}{{random.number}}.txt.zip' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .zip' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see a new file '{{random.address_state}}{{random.number}}.zip' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of '{{random.address_city}}{{random.number}}.txt' file in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see a new file '{{random.address_city}}{{random.number}}.txt.tar.gz' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon at the right of '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Compress' and click 'as .tar.gz' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see a new file '{{random.address_state}}{{random.number}}.tar.gz' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click '.profile' file in the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see new editor tab opened with this file content??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on down arrow on the rigth-side of '.profile' tab that you just opened and select 'Search in All Files'""", ->
    before -> 
      # implement before hook 

    it """Do you see a pop-up with 'Find', 'Where', 'Case Sensitive', 'Whole Word', 'Use regexp' texts??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type 'if' in 'Find' field, check all of the three checkboxes next to 'Case Sensitive', 'Whole Word' and 'Use regexp' fields and click on 'SEARCH'""", ->
    before -> 
      # implement before hook 

    it """Is search result opened in a new tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is search term 'if' highlighted??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on one of the highlighted search term""", ->
    before -> 
      # implement before hook 

    it """Is a file opened on a new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

