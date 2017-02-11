kd = require 'kd'
particlejson = require './particlejson'
require 'particles.js'
require './style/deleteteamoverlay.styl'

module.exports = class DeleteTeamOverlay extends kd.OverlayView

  constructor: (options = {}, data) ->

    options.cssClass = 'delete-team-overlay'
    options.domId = 'particles'
    options.isRemovable = no

    super options, data

    window.particlesJS 'particles', particlejson

    @addSubView new kd.CustomHTMLView
      cssClass: 'content'
      partial: '''
          <img class='blackhole' src='/a/images/black_hole.png' srcset='/a/images/black_hole.png 1x, /a/images/black_hole@2x.png 2x' />
          <img class="spaceship spaceship1" src='/a/images/UFO.png'  srcset='/a/images/UFO.png 1x, /a/images/UFO@2x.png 2x' />
          <img class="spaceship spaceship2" src='/a/images/UFO.png'  srcset='/a/images/UFO.png 1x, /a/images/UFO@2x.png 2x' />
          <img class="spaceship spaceship3" src='/a/images/UFO.png'  srcset='/a/images/UFO.png 1x, /a/images/UFO@2x.png 2x' />
          <div class='content-header'>
            The end of an era!
          </div>
          <div class='content-description'>
            Your team is gone but we hope the memories were stellar.
            Next, you can login to another team or create a new one.
          </div>
        '''

    setTimeout ->
      window.location = '/Teams/Select'
    , 10000
