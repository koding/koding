MachineItemView = require './machineitemview'


class FinderItem extends NFinderItem

  getChildConstructor: (type) ->
    switch type
      when 'machine'    then MachineItemView
      when 'folder'     then NFolderItemView
      when 'section'    then NSectionItemView
      when 'mount'      then NMountItemView
      when 'brokenLink' then NBrokenLinkItemView
      else NFileItemView


module.exports = FinderItem


window.IDE or= {}
window.IDE.FinderItem or= module.exports

