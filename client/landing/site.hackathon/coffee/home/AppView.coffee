CustomLinkView   = require './../core/customlinkview'
HomeRegisterForm = require './registerform'

TWEET_TEXT       = 'I\'ve applied for the world\'s first global virtual #hackathon by @koding. Join my team!'
SHARE_URL        = 'http://koding.com/Hackathon'

VIDEO_URL        = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.webm'
VIDEO_URL_MP4    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.mp4'
VIDEO_URL_OGG    = 'https://koding-cdn.s3.amazonaws.com/campaign/hackathon/intro-bg.ogv'

{
  judges   : JUDGES
  partners : PARTNERS
} = KD.campaignStats.campaign

module.exports = class HomeView extends KDView

  getStats = ->

    KD.campaignStats ?=
      campaign           :
        cap              : 50000
        prize            : 10000
      totalApplicants    : 34512
      approvedApplicants : 12521
      isApplicant        : no
      isApproved         : no
      isWinner           : no

  constructor: (options = {}, data)->

    super options, data

    @setPartial @partial()


  updateWidget : ->

    @updateStats()


  viewAppended : ->

    super

    @addSubView new KDCustomHTMLView
      cssClass  : 'logos'
      tagName   : 'figure'
      bind      : 'mousemove mouseleave mouseenter'
      mousemove : (event) ->
        ww        = window.innerWidth
        width     = @getWidth()
        slideable = width - ww
        margin    = -(width / 2)
        percent   = event.clientX / ww
        slide     = slideable * percent
        newMargin = (margin + (slideable / 2)) - slide
        @setCss 'margin-left', "#{newMargin}px"
      mouseenter : ->
        KD.utils.wait 300, => @setClass 'no-anim'
      mouseleave : ->
        @unsetClass 'no-anim'
        @setCss 'margin-left', '-1280px'

      partial    : """
        <i class="odesk"></i>
        <i class="kissmetrics"></i>
        <i class="accel"></i>
        <i class="udemy"></i>
        <i class="aws"></i>
        <i class="tutum"></i>
        <i class="code"></i>
        <i class="facebook"></i>
        <i class="iron"></i>
        <i class="turkcell"></i>
        <i class="digitalocean"></i>
        <i class="deviantart"></i>
        <i class="baincapital"></i>
        <i class="eniac"></i>
      """


    video = document.getElementById 'bgVideo'
    if window.innerWidth < 680
      video.parentNode.removeChild video
    else
      video.addEventListener 'loadedmetadata', ->
        @currentTime = 8
        @playbackRate = .7
        KD.utils.wait 3000, -> video.classList.add 'in'
      , no


  updateStats: -> @$('div.counters').html @getStats()

  getStats: ->

    { totalApplicants, approvedApplicants, campaign } = getStats()
    { cap, prize } = campaign

    return """
      PRIZE: <span>$#{prize.toLocaleString()}</span>
      TOTAL SLOTS: <span>#{cap.toLocaleString()}</span>
      APPLICATIONS RECEIVED: <span>#{totalApplicants.toLocaleString()}</span>
      APPROVED APPLICANTS: <span>#{approvedApplicants.toLocaleString()}</span>
      """

  partial: ->

    """
    <section class="introduction">
      <video id="bgVideo" autoplay loop muted>
        <source src="#{VIDEO_URL}" type="video/webm"; codecs=vp8,vorbis">
        <source src="#{VIDEO_URL_OGG}" type="video/ogg"; codecs=theora,vorbis">
        <source src="#{VIDEO_URL_MP4}">
      </video>
      <h1>ANNOUNCING THE WORLD’S FIRST GLOBAL VIRTUAL <span>#HACKATHON</span></h1>
      <h3>Let's hack together, no matter where we are!</h3>
      <h3>STARTING MONDAY OCTOBER 27 2014 10:00AM PDT</h3>
    </section>
    <div class="counters">#{@getStats()}</div>
    """
      # <h4>Apply today with your Koding account to get a chance <strong>to win up to $10,000 in cash prizes.</strong></h4>
