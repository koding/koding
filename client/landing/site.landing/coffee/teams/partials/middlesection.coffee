JView           = require './../../core/jview'
Reviews         = require './reviews'
ThirdPartyLogos = require './thirdpartylogos'


module.exports = class MiddleSection extends JView


  constructor: (options = {}, data) ->

    super options, data

    @storiesTitle = new KDCustomHTMLView
      tagName : 'h2'
      partial : 'Success Stories'

    @storiesDesc = new KDCustomHTMLView
      tagName : 'p'
      partial : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc venenatis dui velit, a pretium velit volutpat vel.'

    @reviews = new Reviews

    @moreStoriesButton = new KDButtonView
      cssClass  : 'solid more-stories'
      icon      : yes
      title     : 'MORE STORIES'
      callback  : ->
        alert 'clicked'

    @envTitle = new KDCustomHTMLView
      tagName : 'h2'
      partial : 'Setting-up Environments'

    @envDesc = new KDCustomHTMLView
      tagName : 'p'
      partial : 'Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.'

    @envSchema = new KDCustomHTMLView
      cssClass : 'setting-up-steps'
      partial  : ''

    @envSchemaStepStart = new KDCustomHTMLView
      tagName  : 'span'
      partial  : '<b>Start</b> with lorem ipsum'

    @envSchema.addSubView @envSchemaStepStart

    @envSchemaStepNext = new KDCustomHTMLView
      tagName  : 'span'
      partial  : '<b>Next:</b> Do the lorem ipsum'

    @envSchema.addSubView @envSchemaStepNext

    @envSchemaStepFinal = new KDCustomHTMLView
      tagName  : 'span'
      partial  : '<b>Voila!</b> Env is ready to rock!'

    @envSchema.addSubView @envSchemaStepFinal

    @gitHubTitle = new KDCustomHTMLView
      tagName : 'h2'
      partial : 'GitHub Integration'

    @gitHubDesc = new KDCustomHTMLView
      tagName : 'p'
      partial : 'Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.'

    @thirdPartyTitle = new KDCustomHTMLView
      tagName : 'h2'
      partial : 'They Know How To Party'

    @thirdPartyDesc = new KDCustomHTMLView
      tagName : 'p'
      partial : 'Bling bling fo shizzle velizzle, bow wow wow volutpizzle, fo shizzle quizzle, fo shizzle mah nizzle fo rizzle, mah home g-dizzle vel, arcu.'

    @thirdPatyLogos = new ThirdPartyLogos

  pistachio: ->
    """
    <section class='main-wrapper middle'>
      {{> @storiesTitle}}
      {{> @storiesDesc}}
      {{> @reviews}}
      {{> @moreStoriesButton}}
      <div class='line'></div>
      {{> @envTitle}}
      {{> @envDesc}}
      {{> @envSchema}}
      <div class='line'></div>
      {{> @gitHubTitle}}
      {{> @gitHubDesc}}
      <div class='browser'>
        <img src='/a/site.landing/images/teams/browser.png' alt='' />
      </div>
      <div class='line'></div>
      {{> @thirdPartyTitle}}
      {{> @thirdPartyDesc}}
      {{> @thirdPatyLogos}}
    </section>
    """