ModalItem = require './modalitem'

module.exports = class ModalWorkspaceItem extends ModalItem

  constructor: (options = {}, data) ->

    super
      type  : 'workspace'
      href  : "/IDE/#{data.machineLabel}/#{data.slug}"
      title : data.name
    , data
