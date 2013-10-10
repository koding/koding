
FRAMEWORK_VERSION = "0.0.1"
KODING_VERSION    = "0.0.1"

projects      =

  KDFramework :
    files     : "client/Framework/includes.coffee"
    style     : "css/kd.#{FRAMEWORK_VERSION}.css"
    script    : "js/kd.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Framework/"

  KDBackend   :
    files     : "client/Bongo/includes.coffee"
    script    : "js/bongo.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Bongo/"

  KDMainApp   :
    files     : "client/includes.coffee"
    style     : "css/kdapp.#{KODING_VERSION}.css"
    script    : "js/kdapp.#{KODING_VERSION}.js"

  TestApp     :
    files     : "client/testapp/includes.coffee"
    style     : "css/testapp.css"
    script    : "js/testapp.js"

bundles       =

  Koding      :
    projects  : ['KDBackend', 'KDMainApp']
    style     : "css/koding.#{KODING_VERSION}.css"
    script    : "js/koding.#{KODING_VERSION}.js"


module.exports  = {projects, bundles}