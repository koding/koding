module.exports = class ThirdPartyLogos extends KDView


  IMAGEPATH = '/a/site.landing/images/teams/'
  LOGOS     = [
    { logo : 'dropbox.png',     url : '' }
    { logo : 'airbnb.png',      url : '' }
    { logo : 'pinterest.png',   url : '' }
    { logo : 'slack.png',       url : '' }
  ]


  constructor: (options = {}, data) ->

    super options, data

    @setPartial @partial()

    @prepareLogos()


  prepareLogos: ->

    for item in LOGOS

      logo = new KDCustomHTMLView
        tagName : 'a'
        attributes :  href : item.url
        partial : "<img src='#{IMAGEPATH}/#{item.logo}' alt='' />"

      @addSubView logo, '.third-party'


  partial: ->
    """
    <div class='third-party'></div>
    """


