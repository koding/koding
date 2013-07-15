class ModalAppsListItemView extends KDListItemView

  constructor:(options,data)->
    options.cssClass = 'topic-item'

    super options, data

    @titleLink = new AppLinkView {expandable:no}, data
    @titleLink.on "click", =>
      @getDelegate().emit "CloseTopicsModal"

  pistachio:->
    """
    <div class="apptitle">
      {{> @titleLink }}
    </div>
    <div class="stats">
      <p class="installs">
        <span class="icon"></span>{{#(counts.installed) or 0}} Installs
      </p>
      <p class="fers">
        <span class="icon"></span>{{#(counts.followers) or 0}} Followers
      </p>
    </div>
    """

  viewAppended: JView::viewAppended