class IntroductionChildItem extends IntroductionItem

  constructor: (options = {}, data) ->

    options.cssClass = "admin-introduction-child-item"

    super options, data

  remove: ->
    @getDelegate().getData().deleteChild @getData().introId, =>
      @destroy()

  update: ->
    introductionItem      = @getDelegate()
    introductionAdmin     = introductionItem.getDelegate()
    data                  = @getData()
    data.introductionItem = introductionItem
    introductionAdmin.showForm "Item", data, "Update"

  pistachio: ->
    data = @getData()
    """
      <div class="introItemText"><b>Intro Id</b>: #{data.introId} <b>for</b>: #{data.introTitle}</div>
      <div class="introduction-actions cell">
        {{> @updateLink}}{{> @deleteLink}}
      </div>
    """

