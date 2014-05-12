class ActivityLikeSummaryView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "like-summary", options.cssClass

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

    KD.singleton("socialapi").message.listLikers {id}, (err, accounts) ->

      return KD.showError err  if err
      return  if accounts.length is 0

      new ShowMoreDataModalView null, accounts


  fetchPreviewAccounts: (callback) ->

    constructorName = "JAccount"
    origins = @getData().interactions.like.actorsPreview.map (id) -> {id, constructorName}

    KD.remote.cacheable origins, callback


  viewAppended: ->

    super

    if @getData().interactions.like.actorsCount is 0
    then @setClass 'hidden'

    names  = []
    strong = (x) -> "<strong>#{x}</strong>"

    @fetchPreviewAccounts (err, accounts) =>

      return KD.showError err  if err
      return  if accounts.length is 0

      for i in [0..2]
        account = accounts[i]
        return  unless view = this["placeholder#{i}"]
        view.addSubView new ProfileLinkView null, account


  pistachio: ->

    {actorsCount} = @getData().interactions.like

    body = switch
      when actorsCount is 0 then ""
      when actorsCount is 1 then "{{> @placeholder0}}"
      when actorsCount is 2 then "{{> @placeholder0}} and {{> @placeholder1}}"
      when actorsCount is 3 then "{{> @placeholder0}}, {{> @placeholder1}} and {{> @placeholder2}}"
      when actorsCount > 3
        othersCount = actorsCount - 3
        "{{> @placeholder0}}, {{> @placeholder1}}, {{> @placeholder2}} and \
         {{> @showMoreLink}} other#{if othersCount > 1 then 's' else ''}"

    body += " liked this."  if actorsCount > 0
