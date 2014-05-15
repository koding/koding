class ActivityLikeSummaryView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "like-summary hidden", options.cssClass

    super options, data

    @placeholder0 = new KDCustomHTMLView tagName : 'span'
    @placeholder1 = new KDCustomHTMLView tagName : 'span'
    @placeholder2 = new KDCustomHTMLView tagName : 'span'

    @showMoreLink = new KDCustomHTMLView
      tagName     : "strong"
      partial     : data.interactions.like.actorsCount - 3
      click       : @bound "showLikers"


  showLikers: ->

    {id} = @getData()

    KD.singleton("socialapi").message.listLikers {id}, (err, ids) ->

      return KD.showError err  if err
      return  if ids.length is 0

      batch = ids.map do (constructorName = "JAccount") ->
        (id) -> {constructorName, id}

      KD.remote.cacheable batch, (err, accounts) ->

        return KD.showError err  if err
        new ShowMoreDataModalView null, accounts


  updateActors: ->

    @fetchPreviewAccounts (err, accounts) =>

      return KD.showError err  if err

      for i in [0..accounts.length]
        account = accounts[i]
        continue  unless view = this["placeholder#{i}"]
        view.destroySubViews()
        view.addSubView new ProfileLinkView null, account
        view = null

      @setTemplate @pistachio()
      @render()

      {actorsCount} = @getData().interactions.like

      @showMoreLink.updatePartial Math.max actorsCount - 3, 0

      if accounts.length is 0
      then @hide()
      else @show()


  fetchPreviewAccounts: (callback) ->

    constructorName = "JAccount"
    origins = @getData().interactions.like.actorsPreview.map (id) -> {id, constructorName}

    KD.remote.cacheable origins, callback


  viewAppended: ->

    super



  pistachio: ->

    {actorsCount, actorsPreview} = @getData().interactions.like

    body = ""

    return body  unless actorsPreview.length

    linkCount = Math.min actorsPreview.length, 3

    for i in [0..linkCount - 1]
      body += "{{> this.placeholder#{i}}}"

      if (linkCount - i) is (if actorsCount - linkCount then 1 else 2)
        body += " and "
      else if i < (linkCount - 1)
        body += ", "

    if (diff = actorsCount - linkCount) > 0
      body += "{{> this.showMoreLink}} other#{if diff > 1 then 's' else ''}"

    body += " liked this."
