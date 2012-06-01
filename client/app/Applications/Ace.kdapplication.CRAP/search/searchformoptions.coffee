class Editor_SearchForm_Options extends KDModalView
  viewAppended: ->
    # backwards     : options.backwards
    # wrap          : options.wrap
    # caseSensitive : options.caseSensitive
    # wholeWord     : options.wholeWord
    # regExp        : options.regExp
    @setTitle "Options"

    searchOptions = @getDelegate().getLastSearchOptions()

    backwardsFieldset = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'modalformline'

    backwardsLabel    = new KDLabelView 
      title: 'Backwards search'

    backwardsInput    = new KDRySwitch
      label: backwardsLabel
      defaultValue: searchOptions.backwards
      callback: (state) =>
        @getDelegate().setSearchOptions backwards: !!state

    wrapFieldset      = new KDCustomHTMLView 
      tagName : 'div'
      cssClass : 'modalformline'

    wrapLabel         = new KDLabelView title: 'Wrap'
    wrapInput         = new KDRySwitch
      label: wrapLabel
      defaultValue: searchOptions.wrap
      callback: (state) =>
        @getDelegate().setSearchOptions wrap: !!state

    caseSensitiveFieldset   = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'modalformline'

    caseSensitiveLabel      = new KDLabelView title: 'Case sensitive'
    caseSensitiveInput      = new KDRySwitch
      label: caseSensitiveLabel
      defaultValue: searchOptions.caseSensitive
      callback: (state) =>
        @getDelegate().setSearchOptions caseSensitive: !!state

    wholeWordFieldset       = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'modalformline'

    wholeWordLabel          = new KDLabelView title: 'Whole word'
    wholeWordInput          = new KDRySwitch
      label: wholeWordLabel
      defaultValue: searchOptions.wholeWord
      callback: (state) =>
        @getDelegate().setSearchOptions wholeWord: !!state

    regexpFieldset          = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'modalformline'

    regexpLabel             = new KDLabelView title: 'RegExp'
    regexpInput             = new KDRySwitch
      label: regexpLabel
      defaultValue: searchOptions.regExp
      callback: (state) =>
        @getDelegate().setSearchOptions regExp: !!state

    backwardsFieldset.addSubView backwardsLabel
    backwardsFieldset.addSubView backwardsInput

    wrapFieldset.addSubView wrapLabel
    wrapFieldset.addSubView wrapInput

    caseSensitiveFieldset.addSubView caseSensitiveLabel
    caseSensitiveFieldset.addSubView caseSensitiveInput

    wholeWordFieldset.addSubView wholeWordLabel
    wholeWordFieldset.addSubView wholeWordInput

    regexpFieldset.addSubView regexpLabel
    regexpFieldset.addSubView regexpInput

    @addSubView backwardsFieldset, ".kdmodal-content"
    @addSubView wrapFieldset, ".kdmodal-content"
    @addSubView caseSensitiveFieldset, ".kdmodal-content"
    @addSubView wholeWordFieldset, ".kdmodal-content"
    @addSubView regexpFieldset, ".kdmodal-content"
    
    
  destroy: ->
    @emit 'destroy'
    super
