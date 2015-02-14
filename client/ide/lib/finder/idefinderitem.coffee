IDEMachineItemView = require './idemachineitemview'
NBrokenLinkItemView = require 'finder/filetree/itemviews/nbrokenlinkitemview'
NFileItemView = require 'finder/filetree/itemviews/nfileitemview'
NFinderItem = require 'finder/filetree/itemviews/nfinderitem'
NFolderItemView = require 'finder/filetree/itemviews/nfolderitemview'
NMountItemView = require 'finder/filetree/itemviews/nmountitemview'
NSectionItemView = require 'finder/filetree/itemviews/nsectionitemview'
module.exports = class IDEFinderItem extends NFinderItem

  getChildConstructor: (type) ->
    switch type
      when 'machine'    then IDEMachineItemView
      when 'folder'     then NFolderItemView
      when 'section'    then NSectionItemView
      when 'mount'      then NMountItemView
      when 'brokenLink' then NBrokenLinkItemView
      else NFileItemView
