debug = (require 'debug') 'nse:documentationview'
kd = require 'kd'

Events = require '../events'

KodingListController = require 'app/kodinglist/kodinglistcontroller'

applyMarkdown = require 'app/util/applyMarkdown'
makeHttpClient = require 'app/util/makeHttpClient'

DocsClient = makeHttpClient { baseURL: '/-/terraform/' }


class DocumentationItem extends kd.ListItemView

  viewAppended: kd.View::viewAppended

  pistachio: -> '{h3{#(title)}}{{#(description)}}'

  mouseDown: ->
    @parent.emit 'SelectItem', this
    return yes


module.exports = class DocumentationView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'docs-view', options.cssClass

    super options, data

    cached = []
    lastSearch = null

    @listController = new KodingListController
      limit               : 40
      lazyLoadThreshold   : 40
      useCustomScrollView : yes
      noItemFoundText     : 'Nothing found, try something like: azure, aws, google...'
      itemClass           : DocumentationItem
      fetcherMethod       : (query, options, callback) =>
        return callback null, []  unless query.search

        { skip = 0, limit } = options
        if cached and lastSearch is query.search
          return callback null, cached[skip...limit + skip]

        debug 'get from docs, query is', query.search

        @emit Events.LazyLoadStarted

        DocsClient
          .post 'document-search', { query: query.search }
          .then ({ data }) =>
            lastSearch = query.search
            cached = data
            @emit Events.LazyLoadFinished
            callback null, data[skip...limit + skip]
          .catch callback


    @listController.on [
      'ItemActivated', 'ItemSelectionPerformed'
    ], @bound 'handleItemActivated'


  handleItemActivated: ->

    [ item ] = @listController.selectedItems
    debug 'item activated', item

    DocsClient
      .post 'document-content', { query: item.getData().title }
      .then ({ data }) =>
        @docView.updatePartial applyMarkdown data
        @emit Events.ExpandSideView
      .catch kd.noop


  viewAppended: ->

    super

    @addSubView @docView = new kd.View
      cssClass: 'docs-content has-markdown'
    @addSubView @listController.getView()
