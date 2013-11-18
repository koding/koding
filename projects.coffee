
# Fetch version info from VERSION file
fs          = require 'fs'
nodePath    = require 'path'
versionFile = nodePath.join(__dirname, 'VERSION')
if fs.existsSync versionFile
  version = (fs.readFileSync versionFile, 'utf-8').trim()

FRAMEWORK_VERSION = version ? "0.0.1"
KODING_VERSION    = version ? "0.0.1"

projects      =

  KDFramework :
    files     : "client/Framework/includes.coffee"
    style     : "website/css/kd.#{FRAMEWORK_VERSION}.css"
    script    : "website/js/kd.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Framework/"

  KDBackend   :
    files     : "client/Bongo/includes.coffee"
    script    : "website/js/bongo.#{FRAMEWORK_VERSION}.js"
    sourceMapRoot : "Bongo/"

  KDMainApp   :
    files     : "client/Main/includes.coffee"
    style     : "website/css/kdapp.#{KODING_VERSION}.css"
    script    : "website/js/kdapp.#{KODING_VERSION}.js"
    sourceMapRoot : "Main/"

  TestApp     :
    files     : "client/Testapp/includes.coffee"
    style     : "website/css/testapp.css"
    script    : "website/js/testapp.js"

  HomeIntro   :
    files     : "client/Intro/includes.coffee"
    style     : "website/css/introapp.#{KODING_VERSION}.css"
    script    : "website/js/introapp.#{KODING_VERSION}.js"

  # Activity        :
  #   files         : "client/Activity/includes.coffee"
  #   style         : "website/css/app.activity.#{KODING_VERSION}.css"
  #   script        : "website/js/app.activity.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Activity/"

  # Members         :
  #   files         : "client/Members/includes.coffee"
  #   style         : "website/css/app.members.#{KODING_VERSION}.css"
  #   script        : "website/js/app.members.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Members/"

  # Topics          :
  #   files         : "client/Topics/includes.coffee"
  #   style         : "website/css/app.topics.#{KODING_VERSION}.css"
  #   script        : "website/js/app.topics.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Topics/"

  # Groups          :
  #   files         : "client/Groups/includes.coffee"
  #   style         : "website/css/app.groups.#{KODING_VERSION}.css"
  #   script        : "website/js/app.groups.#{KODING_VERSION}.js"
  #   sourceMapRoot : "Groups/"

  Account         :
    files         : "client/Account/includes.coffee"
    style         : "website/css/app.account.#{KODING_VERSION}.css"
    script        : "website/js/app.account.#{KODING_VERSION}.js"
    sourceMapRoot : "Account/"

  Terminal        :
    files         : "client/Terminal/includes.coffee"
    style         : "website/css/app.terminal.#{KODING_VERSION}.css"
    script        : "website/js/app.terminal.#{KODING_VERSION}.js"
    sourceMapRoot : "Terminal/"

  Ace             :
    files         : "client/Ace/includes.coffee"
    style         : "website/css/app.ace.#{KODING_VERSION}.css"
    script        : "website/js/app.ace.#{KODING_VERSION}.js"
    sourceMapRoot : "Ace/"

bundles       =

  # Social      :
  #   projects  : ['Activity', 'Members', 'Topics', 'Groups', 'Apps']
  #   style     : "website/css/social.#{KODING_VERSION}.css"
  #   script    : "website/js/social.#{KODING_VERSION}.js"

  Koding      :
    projects  : ['KDBackend', 'KDMainApp']
    style     : "website/css/koding.#{KODING_VERSION}.css"
    script    : "website/js/koding.#{KODING_VERSION}.js"


module.exports  = {projects, bundles}
