kd = require 'kd'
KDButtonView = kd.ButtonView
KDModalView = kd.ModalView
showError = require 'app/util/showError'
objectToString = require 'app/util/objectToString'
applyMarkdown = require 'app/util/applyMarkdown'

module.exports = class MetaInfoButtonView extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'troll-button', options.cssClass
    options.title    = "Info"
    options.callback = ->

      data.fetchMetaInformation (err, info)->

        return if showError err

        info = objectToString info,
          separator : "  "
          maxDepth  : 100

        colorized = applyMarkdown "```json \n#{info}\n```"

        new KDModalView
          cssClass : 'meta-info-modal has-markdown'
          title    : "Information of #{data.profile.nickname}"
          content  : colorized

    super options
