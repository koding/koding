class FatihContentSearchPlugin extends FatihPluginAbstract

  constructor: (options = {}, data) ->

    options.name          = "Content Search"
    options.keyword       = "search"
    options.notFoundText  = "Not found in any files!"


    super options, data

    @on "ListItemClicked", -> @fatihView.destroy()

  action: (keyword) ->
    {nickname} = KD.whoami().profile
    FSHelper.grepInDirectory keyword, "/Users/#{nickname}/Applications", (result) =>
      @fatihView.emit "PluginViewReadyToShow", new FatihContentSearchView {}, result


class FatihContentSearchView extends JView

  constructor: (options = {}, data) ->

    super options, data

    result = @getData()

    files = []
    files.push { path } for own path of result

    @fileList = new KDListViewController
      wrapper     : no
      scrollView  : no
      keyNav      : yes
      view        : new KDListView
        delegate  : @
        tagName   : "ul"
        cssClass  : "fatih-search-results"
        itemClass : FatihContentSearchListItem
    , items       : files

    @notFound = new KDView
      partial       : "Oops! Not found in any files!"
      cssClass      : "not-found"

    @notFound.hide() unless files.length is 0

    @on "ListItemClicked", (item, data) =>
      item.addSubView new FatihContentSearchSummary {}, @getData()[data.path]

  pistachio: ->
    """
      <div class="fatih-content-search">
        {{> @notFound}}
        {{> @fileList.getView()}}
      </div>
    """

class FatihContentSearchListItem extends FatihFileListItem

  constructor: (options = {}, data) ->

    super options, data

  click: ->
    listView          = @getDelegate()
    contentSearchView = listView.getDelegate()

    contentSearchView.emit "ListItemClicked", @, @getData()


class FatihContentSearchSummary extends JView

  constructor: (options = {}, data) ->

    super options, data

  pistachio: ->
    data   = @getData()
    markup = ""

    for own lineNumber of data
      {line, isMatchedLine} = data[lineNumber]
      className             = if isMatchedLine then "matched" else ""

      markup += """
        <div class="code-line">
          <div class="line">#{lineNumber}</div>
          <div class="content #{className}">#{line}</div>
        </div>
      """

    markup