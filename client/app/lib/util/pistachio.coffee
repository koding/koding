module.exports = class Pistachio

  @createId = do ->
    counter = 0
    (prefix)-> "#{prefix}el-#{counter++}"

  @getAt =(ref, path)->
    if 'function' is typeof path.split # ^1
      path = path.split '.'
    else
      path = path.slice()
    while ref? and prop = path.shift()
     ref = ref[prop]
    ref

  ###
  example pistachios:

  header:
  {h3{#(title)}}

  date:
  {time.timeago{#(meta.createdAt)}}

  id:
  {h1#siteTitle{#(title)}}

  subview / partial:
  {{> @subView }}

  wrapped subview / partial:
  {div.fixed.widget{> @clock }}

  attribute:
  {a[href="#profile"]{ '@'+#(profile.nickname) }}

  kitchen sink:
  {div#id.class1.class2[title="Example Attribute"]{> @subView }}

  it's important to note that there is a priority.  That is to make the symbol easier for the CPU to parse.

  1 tagName
  2 id, #-prefixed (hash prefixed)
  3 classNames, .-prefixed (dot prefixed)
  4 custom attributes, bracketed squarely, each ([key=val]) # weird stuff is OK for "val"

  #sth is short for [id=sth]
  .sth is short for [class=sth]
  .sth.els is short for [class="sth els"]

  we optimize both.
  ###

  pistachios =
    ///
    \{                  # first { (begins symbol)
      ([\w|-]*)?        # optional custom html tag name
      (\#[\w|-]*)?      # optional id - #-prefixed
      ((?:\.[\w|-]*)*)  # optional class names - .-prefixed
      (\[               # optional [ begins the attributes
        (?:\b[\w|-]*\b) # the name of the attribute
        (?:\=           # optional assignment operator =
                        # TODO: this will tolerate fuzzy quotes for now. "e.g.'
          [\"|\']?      # optional quotes
          .*            # optional value
          [\"|\']?      # optional quotes
        )
      \])*              # optional ] closes the attribute tag(s). there can be many attributes.
      \{                # second { (begins expression)
        ([^{}]*)        # practically anything can go between the braces, except {}
      \}\s*             # closing } (ends expression)
    \}                  # closing } (ends symbol)
    ///g

  constructor:(@view, @template, @options={})->
    {@prefix, @params}   = @options
    @params            or= {}
    @symbols             = {}
    @symbolsByDataPath   = {}
    @symbolsBySubViewName= {}
    @dataPaths           = {}
    @subViewNames        = {}
    @prefix            or= ''
    @html                = @init()

  createId: @createId

  toString:-> @template

  init: do ->

    dataGetter = (prop)->
      data = @getData?()
      return data.getAt?(prop) or Pistachio.getAt data, prop  if data?

    getEmbedderFn =(pistachio, view, id, symbol)->
      (childView)->
        view.embedChild id, childView, symbol.isCustom
        unless symbol.isCustom
          symbol.id      = childView.id
          symbol.tagName = childView.getTagName?()
          delete pistachio.symbols[id]
          pistachio.symbols[childView.id] = symbol

    init =->
      { prefix, view, createId } = this
      @template.replace pistachios, (_, tagName, id, classes, attrs, expression)=>

        id = id?.split('#')[1]
        classNames = classes?.split('.').slice(1) or []
        attrs = attrs?.replace(/\]\[/g, ' ').replace(/\[|\]/g, '') or ''

        isCustom = !!(tagName or id or classes.length or attrs.length)

        tagName or= 'span'

        dataPaths = []
        subViewNames = []

        expression = expression
          .replace /#\(([^)]*)\)/g, (_, dataPath)->
            dataPaths.push dataPath
            "data('#{dataPath}')"
          .replace /^(?:> ?|embedChild )(.+)/, (_, subViewName)->
            subViewNames.push subViewName.replace /\@\.?|this\./, ''
            "embedChild(#{subViewName})"

        @registerDataPaths dataPaths
        @registerSubViewNames subViewNames

        js = 'return ' + expression

        if 'debug' is tagName
          console.debug js
          tagName = 'span'

        paramKeys     = Object.keys @params
        paramValues   = paramKeys.map (key)=> @params[key]

        formalParams = ['data', 'embedChild', paramKeys...]

        try code = Function formalParams..., js

        catch e then throw new Error \
          """
          Pistachio encountered an error: #{e}
          Source: #{js}
          """

        id or= createId prefix

        render = ->
          '' + code.apply view, [
            dataGetter.bind view
            embedChild
            paramValues...
          ]

        symbol = {
          tagName, id, isCustom, js, code, render, dataPaths, subViewNames
        }

        @addSymbolInternal symbol

        embedChild = getEmbedderFn @, view, id, symbol

        dataPathsAttr =
          if dataPaths.length
            " data-#{prefix}paths='#{dataPaths.join ' '}'"
          else ""

        subViewNamesAttr =
          if subViewNames.length
            classNames.push "#{prefix}subview"
            " data-#{prefix}subviews='#{cleanSubviewNames(subViewNames.join ' ')}'"
          else ""

        classAttr =
          if classNames.length then " class='#{classNames.join ' '}'"
          else ""

        "<#{tagName}#{classAttr}#{dataPathsAttr}#{subViewNamesAttr} #{attrs} id='#{id}'></#{tagName}>"

  addSymbolInternal: (symbol) ->
    { dataPaths, subViewNames } = symbol

    @symbols[symbol.id] = symbol

    for dataPath in dataPaths
      @symbolsByDataPath[dataPath] ?= []
      @symbolsByDataPath[dataPath].push symbol         

    for subViewName in subViewNames
      @symbolsBySubViewName[subViewName] ?= []
      @symbolsBySubViewName[subViewName].push symbol

    return symbol

  addSymbol:(childView)->
    @symbols[childView.id] = {
      id      : childView.id
      tagName : childView.getTagName?()
    }

  appendChild:(childView)->
    @addAdhocSymbol childView

  prependChild:(childView)->
    @addAdhocSymbol childView

  registerDataPaths:(paths)->
    @dataPaths[path] = yes for path in paths

  registerSubViewNames:(subViewNames)->
    @subViewNames[subViewName] = yes for subViewName in subViewNames

  getDataPaths:-> Object.keys @dataPaths

  getSubViewNames:-> Object.keys @subViewNames

  cleanSubviewNames =(name)-> name.replace /(this\["|\"])/g, ''

  symbolKeys = 
    subview : 'symbolsBySubViewName'
    path    : 'symbolsByDataPath'

  refreshChildren: (childType, items, forEach = (->)) ->
    unique = {}

    for item in items
      
      symbols = @[symbolKeys[childType]][item]

      continue  unless symbols?
      
      for symbol in symbols

        unique[symbol.id] = symbol

    for own id, symbol of unique
      el = @view.getElement().querySelector "##{id}"
      continue unless el?

      out = symbol?.render()
      forEach.call el, out  if out

  embedSubViews:(subviews=@getSubViewNames())->
    @refreshChildren 'subview', subviews

  update:(paths = @getDataPaths())->
    @refreshChildren 'path', paths, (html)-> @innerHTML = html
