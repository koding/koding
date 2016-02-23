kd                = require 'kd'
ShareModalContent = require './sharemodalcontentview'


module.exports = class CollaborationShareModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.overlay = yes

    super options, data

    @addSubView new ShareModalContent {url: @options.url}


