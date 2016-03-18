ProfileLinkView = require './profilelinkview'


module.exports = class ProfileTextView extends ProfileLinkView

  constructor: (options, data) ->

    options.tagName or= 'span'

    super

  click: -> yes
