class InstallPane extends Pane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @submit.bind(@)
      buttons               :
        install             :
          title             : "Install Wordpress"
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
        # advanced            :
        #   itemClass         : KDToggleButton
        #   style             : "transparent"
        #   states          : [
        #     "Advanced Options", (callback)=>
        #       @form.buttons.advanced.setClass "toggle"
        #       darks = @form.$ '.formline.dark'
        #       darks.addClass "in"
        #       callback? null
        #     "&times; Advanced Options", (callback)=>
        #       @form.buttons.advanced.unsetClass "toggle"
        #       darks = @form.$ '.formline.dark'
        #       darks.removeClass "in"
        #       callback? null
        #   ]
      fields                :
        name                :
          label             : "Name of your blog:"
          name              : "name"
          placeholder       : "type a name for your blog..."
          defaultValue      : "My Wordpress"
          validate          :
            rules           :
              required      : "yes"
            messages        :
              required      : "a name for your wordpress is required!"
          keyup             : => @completeInputs()
          blur              : => @completeInputs()
        domain              :
          label             : "Domain :"
          name              : "domain"
          itemClass         : KDSelectBox
          defaultValue      : "#{nickname}.koding.com"
          nextElement       :
            pathExtension   :
              label         : "/my-wordpress/"
              type          : "hidden"
        path                :
          label             : "Path :"
          name              : "path"
          placeholder       : "type a path for your blog..."
          hint              : "leave empty if you want your blog to work on your domain root"
          defaultValue      : "my-wordpress"
          keyup             : => @completeInputs yes
          blur              : => @completeInputs yes
          validate          :
            rules           :
              regExp        : /(^$)|(^[a-z\d]+([-][a-z\d]+)*$)/i
            messages        :
              regExp        : "please enter a valid path!"
          nextElement       :
            timestamp       :
              name          : "timestamp"
              type          : "hidden"
              defaultValue  : Date.now()
        # Database            :
        #   cssClass          : "dark"
        #   label             : "Create a new database:"
        #   name              : "db"
        #   title             : ""
        #   labels            : ["YES","NO"]
        #   itemClass         : KDOnOffSwitch
        # dbName              :
        #   cssClass          : "dark"
        #   label             : "Database Name:"
        #   name              : "dbName"
        #   placeholder       : "a mysql database that wordpress will use..."
        # dbUser              :
        #   cssClass          : "dark"
        #   label             : "Database Username:"
        #   name              : "dbUser"
        #   placeholder       : "username of the given database"
        # dbHost              :
        #   cssClass          : "dark"
        #   label             : "Database Host:"
        #   name              : "dbHost"
        #   placeholder       : "host of the given database"
        #   defaultValue      : "mysql0.db.koding.com"
        # dbPrefix            :
        #   cssClass          : "dark"
        #   label             : "Database Host:"
        #   name              : "dbPrefix"
        #   placeholder       : "prefix that all tables will start in the database"
        #   defaultValue      : "wp_"

    @form.on "FormValidationFailed", => @form.buttons["Install Wordpress"].hideLoader()

    domainsPath = "/Users/#{nickname}/Sites"

    kc.run
      withArgs  :
        command : "ls #{domainsPath} -lpva"
    , (err, response)=>
      if err then warn err
      else
        files = FSHelper.parseLsOutput [domainsPath], response
        newSelectOptions = []

        files.forEach (domain)->
          newSelectOptions.push {title : domain.name, value : domain.name}

        {domain} = @form.inputs
        domain.setSelectOptions newSelectOptions

  completeInputs:(fromPath = no)->

    {path, name, pathExtension} = @form.inputs
    if fromPath
      val  = path.getValue()
      slug = __utils.slugify val
      path.setValue val.replace('/', '') if /\//.test val
    else
      slug = __utils.slugify name.getValue()
      path.setValue slug

    slug += "/" if slug

    pathExtension.inputLabel.updateTitle "/#{slug}"

  submit:(formData)=>

    split.resizePanel 250, 0
    {path, domain, name, db} = formData
    formData.timestamp = parseInt formData.timestamp, 10
    formData.fullPath = "#{domain}/website/#{path}"

    failCb = =>
      @form.buttons["Install Wordpress"].hideLoader()
      @utils.wait 5000, -> split.resizePanel 0, 1

    successCb = =>
      installWordpress formData, (path, timestamp)=>
        @emit "WordPressInstalled", formData
        @form.buttons["Install Wordpress"].hideLoader()

    checkPath formData, (err, response)=>
      if err # means there is no such file
        if db
          prepareDb (err, db)=> if err then failCb() else successCb()
        else
          successCb()
      else # there is a folder on the same path so fail.
        failCb()



  pistachio:-> "{{> @form}}"
