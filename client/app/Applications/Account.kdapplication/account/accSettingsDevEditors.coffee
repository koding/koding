class AccountEditorListController extends KDListViewController
  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "Editor settings are coming soon" }
        # { title : "Ace Editor",     extensions : ["html","php","css"],   type : "aceeditor"}
        # { title : "Pixlr Editor",   extensions : ["jpg","png","pxd"],    type : "pixlreditor"}
        # { title : "Pixlr Express",  extensions : ["gif","bmp"],          type : "pixlrexpress"}
        # { title : "CodeMirror",     extensions : ["js","py"],            type : "codemirror"}
      ]
    ,data
    super options,data

class AccountEditorList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountEditorListItem
    ,options
    super options,data

class AccountEditorExtensionTagger extends KDFormView
  viewAppended:->
    # FIXME : SET AUTOCOMPLETE VIEW AS IN MEMBERS SEARCH
    @addSubView tagInput = new KDInputView
      placeholder  : "add a file type... (not available on Private Beta)"
      name         : "extension-tag"

    @addSubView actions = new KDView
      cssClass : "actions-wrapper"

    actions.addSubView save = new KDButtonView
      title        : "Save"

    actions.addSubView cancel = new KDCustomHTMLView
      tagName      : "a"
      partial      : "cancel"
      cssClass     : "cancel-link"
      click        : => @emit "FormCancelled"



class AccountEditorTags extends KDView
  viewAppended:->
    @setPartial @partial @data

  partial:(data)->
    extHTMLArr = for extension in data
      "<span class='blacktag'>#{extension}</span>"
    """
      #{extHTMLArr.join("")}
    """

class AccountEditorListItem extends KDListItemView
  constructor:(options,data)->
    options = tagName : "li"
    super options,data

  viewAppended:->
    super
    @form = form = new AccountEditorExtensionTagger
      delegate : @
      cssClass : "posstatic"
    ,@data.extensions

    @info = info = new AccountEditorTags
      cssClass : "posstatic"
      delegate : @
    ,@data.extensions

    info.addSubView editLink = new KDCustomHTMLView
      tagName  : "a"
      partial  : "Edit"
      cssClass : "action-link"
      click    : @bound "swapSwappable"

    @swappable = swappable = new AccountsSwappable
      views : [form,info]
      cssClass : "posstatic"

    @addSubView swappable,".swappable-wrapper"

    form.on "FormCancelled", @bound "swapSwappable"

  swapSwappable:->
    @swappable.swapViews()

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
    # """
    #   <div class='labelish'>
    #     <span class="icon #{data.type}"></span>
    #     <span class='editor-method-title'>#{data.title}</span>
    #   </div>
    #   <div class='swappableish swappable-wrapper posstatic'></div>
    # """