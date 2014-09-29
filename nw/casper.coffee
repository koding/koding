getLinks = ->
  links = document.querySelectorAll "h3.r a"
  Array::map.call links, (e) -> e.getAttribute "href"

links = []
casper = require('casper').create
  verbose  : yes
  loglevel : "debug"
  # clientScripts: [
  #     "../../website/a/site.landing/js/pistachio.js?d5a65b02"
  #     "../../website/a/site.landing/js/kd.libs.js?d5a65b02"
  #     "../../website/a/site.landing/js/kd.js?d5a65b02"
  #     "../../website/a/site.landing/js/main.js?d5a65b02"
  # ]
  pageSettings :
    javascriptEnabled : yes
  viewportSize :
    width : 1440
    height: 900


casper.start()
casper.setHttpAuth('koding', '1q2w3e4r')

casper.thenOpen "http://sandbox.koding.com", ->
  # document.querySelector("form.login-form input[name='email']").value = "devrim+joe@koding.com"
  @capture "foo1.png"

  # @echo @getPageContent()
  # @echo @evaluate -> location.href
  @echo @evaluate -> KD
  js = @evaluate ->
    document.getElementsByTagName("html")[0].innerHTML

  @echo js

# casper.thenEvaluate ->
#   document

# casper.thenEvaluate ->
  # @debugHTML()
  # @debugPage()
  # @capture "foo0.png"


# casper.thenEvaluate ->
#   @debugHTML()
#   @capture "foo1.png"

# casper.wait 1000,->
#   @debugHTML()
#   @capture "foo2.png"

# casper.waitForSelector "form.login-form", ->
#   # search for 'casperjs' from google form
#   @fill "form.login-form",
#     email    : "devrim+boo@koding.com"
#     username : "devrimboo"
#   ,yes


casper.run ->
  # display results
  @echo "bitti."
  casper.exit()


# casper.then ->
#   # aggregate results for the 'casperjs' search
#   links = @evaluate getLinks
#   # search for 'phantomjs' from google form
#   @fill "form[action='/search']", q: "phantomjs", true

# casper.then ->
#   # concat results for the 'phantomjs' search
#   links = links.concat @evaluate(getLinks)

