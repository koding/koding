JView                    = require './../../core/jview'
TeamsHomeReviews         = require './teamshomereviews'
TeamsHomeThirdPartyLogos = require './teamshomethirdpartylogos'


module.exports = class TeamsHomeFeaturesSection extends JView


  constructor: (options = {}, data) ->

    super options, data

    @teamsHomeReviews  = new TeamsHomeReviews

    @moreStoriesButton = new KDButtonView
      cssClass  : 'solid more-stories'
      icon      : yes
      title     : 'MORE STORIES'
      callback  : ->
        alert 'clicked'

    @teamsHomeThirdPartyLogos = new TeamsHomeThirdPartyLogos

  pistachio: ->
    """
    <section class='main-wrapper middle'>
      <h2>Success Stories</h2>
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc venenatis dui velit, a pretium velit volutpat vel.</p>
      {{> @teamsHomeReviews}}
      {{> @moreStoriesButton}}
      <div class='line'></div>
      <h2>Setting-up Environments</h2>
      <p>Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.</p>
      <div class='setting-up-steps'>
        <span><b>Start</b> with lorem ipsum</span>
        <span><b>Next</b> Do the lorem ipsum</span>
        <span><b>Voila!</b> Env is ready to rock!</span>
      </div>
      <div class='line'></div>
      <h2>GitHub Integration</h2>
      <p>Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.</p>
      <div class='browser'>
        <img src='/a/site.landing/images/teams/browser.png' alt='' />
      </div>
      <div class='line'></div>
      <h2>They Know How To Party</h2>
      <p>Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.</p>
      {{> @teamsHomeThirdPartyLogos}}
    </section>
    """
