class MetaInfoButtonView extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'troll-button', options.cssClass
    options.title    = "Info"
    options.callback = ->

      data.fetchMetaInformation (err, info)->

        return if KD.showError err

        info = KD.utils.objectToString info,
          separator : "  "
          maxDepth  : 100

        colorized = KD.utils.applyMarkdown "```json \n#{info}\n```"

        new KDModalView
          cssClass : 'meta-info-modal has-markdown'
          title    : "Information of #{data.profile.nickname}"
          content  : colorized

    super options
