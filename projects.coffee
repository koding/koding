
version        = "0.0.1"

module.exports =

  KDFramework  :
    files      : "frameworkincludes.coffee"
    style      : "css/kd.#{version}.css"
    script     : "js/kd.#{version}.js"

  KodingCom    :
    files      : "includes.coffee"
    style      : "css/kdapp.#{version}.css"
    script     : "js/kdapp.#{version}.js"

  TestApp      :
    files      : "testapp/includes.coffee"
    style      : "css/testapp.css"
    script     : "js/testapp.js"