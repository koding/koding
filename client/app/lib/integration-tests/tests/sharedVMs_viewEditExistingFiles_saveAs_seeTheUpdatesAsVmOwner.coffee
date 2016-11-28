$ = require 'jquery'
assert = require 'assert'

#! 7d07d76f-0932-4feb-94e4-48a94781098d
# title: sharedVMs_viewEditExistingFiles_saveAs_seeTheUpdatesAsVmOwner
# start_uri: /
# tags: automated
#

describe "sharedVMs_viewEditExistingFiles_saveAs_seeTheUpdatesAsVmOwner.rfml", ->
  before -> 
    require './enable_VM_sharing_invite_Member.coffee'

  describe """Type '{{random.first_name}}' and hit ENTER and then double click to it""", ->
    before -> 
      # implement before hook 

    it """Do you see '{{random.first_name}}.txt' added to the file list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window, click on 'ACCEPT' button on the pop-up appeared""", ->
    before -> 
      # implement before hook 

    it """Do you see '/home/rainforestqa99' label on top of a file list next to left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.first_name }}.txt' in the file list under '/home/rainforestqa99' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Terminal' tab on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa99@rainforestqa99:~$' in that 'Terminal' tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the area under 'Untitled.txt' on top, then double click on the '{{ random.first_name }}.txt' file""", ->
    before -> 
      # implement before hook 

    it """Do you see that it's empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type "{{ random.full_name }}" in it, click on the little down arrow next to '{{ random.first_name }}.txt' label above and then select 'Save'""", ->
    before -> 
      # implement before hook 

    it """Have you seen that the green dot next to '{{ random.first_name }}.txt' disappeared??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type "{{ random.number }}" next to '{{ random.full_name }}' in the file, click on the little down arrow next to '{{ random.first_name }}.txt' label above and then select 'Save As...'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Filename:' title and a text field with '{{ random.first_name }}.txt' in it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Select a folder:' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SAVE' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Clear text in filename input then type "{{ random.last_name }}.txt" and then click to 'SAVE' button""", ->
    before -> 
      # implement before hook 

    it """Is '{{ random.last_name }}.txt' added to the pane next to '{{ random.first_name }}.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it also added to the end of file list under '/home/rainforestqa99'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch back to first browser window which you are logged in as user rainforestqa99""", ->
    before -> 
      # implement before hook 

    it """Do you see that '{{ random.last_name }}.txt' is added to the end of file list under '/home/rainforestqa99'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'This file has changed on disk. Do you want to reload it?' text under '{{ random.first_name }}.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you also see 'NO' and 'YES' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES' button""", ->
    before -> 
      # implement before hook 

    it """Do you see '{{ random.full_name }}' in the file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on '{{ random.last_name }}.txt' from the file list""", ->
    before -> 
      # implement before hook 

    it """Is it opened next to '{{ random.first_name }}.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.full_name }}{{ random.number }}' in it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


