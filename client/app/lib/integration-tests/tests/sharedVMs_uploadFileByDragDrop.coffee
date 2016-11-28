$ = require 'jquery'
assert = require 'assert'

#! f251e371-d969-4ea3-9be7-810963cf15f1
# title: sharedVMs_uploadFileByDragDrop
# start_uri: /
# tags: automated
#

describe "sharedVMs_uploadFileByDragDrop.rfml", ->
  before -> 
    require './enable_VM_sharing_invite_Member.coffee'

  describe """Save image from here: {{ random.image }} to your desktop, return to the incognito window and drag and drop image to the file list under '/home/rainforestqa99' label (like in the screencast: http://recordit.co/KRArrgJ8Gs)""", ->
    before -> 
      # implement before hook 

    it """Is it added to the end of file list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the area under 'Untitled.txt' on top, then double click on the '.profile' file from file list under '/home/rainforestqa99' label and reload the page""", ->
    before -> 
      # implement before hook 

    it """Do you see still see '.profile' on top and 'Terminal' on the bottom??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and close the modal by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see that the image you newly added (by drag&drop) is listed under the file list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


