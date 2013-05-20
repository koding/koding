class ContentDisplayAuthorAvatar extends KDCustomHTMLView
  constructor: (options, data) ->
    options or= {}
    options.tagName = 'span'
    super

  viewAppended: ->
    {account} = @getData()
    @setPartial @partial account

  click:(event)->
    {account} = @getData()
    KD.getSingleton("appManager").tell "Members", "createContentDisplay", account

  partial: (account) ->
    {hash} = account.profile

    host = "//#{location.host}/"
    fallbackUrl = "url(http://www.gravatar.com/avatar/#{hash}?size=40&d=#{encodeURIComponent(host + '/images/defaultavatar/default.avatar.40.png')})"

    """
      <span href='' style='background-image:#{fallbackUrl};'></span>
      <span class="author">AUTHOR</span>
    """
