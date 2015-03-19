ModalItem = require './modalitem'

module.exports = class ModalMachineItem extends ModalItem

  constructor: (options = {}, data) ->

    super
      type  : 'machine'
      href  : "/IDE/#{data.slug}"
      title : data.label
    , data
