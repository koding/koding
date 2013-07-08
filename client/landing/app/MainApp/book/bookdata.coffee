__bookPages = [
    title     : "Table of Contents"
    embed     : BookTableOfContents
    section   : -1
  ,
    title     : "Welcome"
    content   : """
                <p><h1>Welcome To Koding!</h1></p>
                <p>Because this is your first time on Koding. We will assist you to understand basics of koding</p>
                <p>Give us 2 min. and it will be done!</p>
                """
    routeURL  : "/Activity"
    section   : 1
    parent    : 0
  ,
    title     : "Members"
    content   : """<p>Welcome to the club!</p>
                   <p>Here you’ll find all of Koding’s members. Follow people you’re working with, you’re learning from, or maybe some that you just find interesting...</p>
                   <p>Here’s your chance to connect and collaborate! Feel free to follow the whole Koding Team!</p>"""
    routeURL  : "/Members"
    section   : 2
    parent    : 0
  ,
    title     : "Activity"
    content   : "<p>Think of this as the town center of Koding. Ask questions, get answers, start a discussion...be social! Community can be a great tool for development, and here’s the place to get started. In fact, let’s start with your first status update! <a href='#' class='cta_button full_width'>Show me how!<a></p>"
    embed     : BookUpdateWidget
    routeURL  : "/Activity"
    section   : 3
    parent    : 0
    showHow   : yes
    howToSteps: ['enterNewStatusUpdate']
  ,

    title     : "Topics"
    embed     : BookTopics
    content   : """<p>Wouldn’t it be great if you could listen to only what you cared about? Well, you can! Topics let you filter content to your preferences.</p>
                   <p>Select your Topics and if someone shares any information about your topic, you will be informed.</p>
                """
    routeURL  : "/Topics"
    section   : 4
    parent    : 0
  ,
    title     : "Develop"
    content   : """<p>That part is where the magic happens! Your file tree, your VM's, your applications and more is here!</p>
                """
    routeURL  : "/Develop"
    section   : 5
    parent    : 0
    showHow   : no
  ,
    cssClass  : "develop more-1"
    content   :
              """
              <p> <h1>What those folders are?</h1></p>
              <p> Applications folder is a place where your koding applications will stay. </p>
              <p> Web Folder on file tree, is where your http://{{#(profile.nickname)}}.kd.io adress goes to. </p>
              <p> Other folders do what they intend to. You can create new folders by clicking right on your file tree </p>
              """
    section   : 1
    parent    : 5
    showHow   : yes
    howToSteps: ['showFileTreeFolderAndFileMenu']
  ,
    cssClass  : "develop more-1"
    content   : """<p> <h1> What those two applications do? </h1></p>
                   <p> <strong>Ace</strong> is your perfect text editor on cloud! </p>
                   <p> <strong>Terminal</strong> is your real terminal! If you want to be root, then just type it!
                      <pre><h2>hint</h2>: your root password is your koding password. </pre>
                   </p>
                """
    section   : 2
    parent    : 5
    showHow   : no
  ,

    cssClass  : "develop enviroments"
    content   : """<p> <h1> Control Your VM! </h1></p>
                   <p> You can change your VM to up or down, Re-Initialize also you can delete your VM.</p>
                   <p> By just clicking, your enviroments menu on below menu </p>
                """
    section   : 3
    parent    : 5
    showHow   : yes
    howToSteps: ['showVMMenu']
  ,
    cssClass  : "develop enviroments more"
    content   : """<p> <h1> Open VM's Terminal </h1></p>
                   <p> If you have more than 1 VM, you can open that VM's menu by clicking terminal icon on VM menu.</p>
                """
    section   : 4
    parent    : 5
    showHow   : yes
    howToSteps: ['openVMTerminal']
  ,
    cssClass  : "develop more-1"
    content   : """<p> There is a shortcut to your recently opened files</p>
                   <p> Just move your cursor to footer and it will appear .</p>
                """
    section   : 5
    parent    : 5
    routeURL  : "/Develop"
    showHow   : yes
    howToSteps: ['showRecentFiles']
  ,
    cssClass  : "develop buy vm"
    content   : """<p> <h1>Need more VM's ?</h1></p>
                   <p> You can buy more VM's there are more features with paid VM's like it is allways on UP State</p>
                """
    section   : 6
    parent    : 5
    routeURL  : "/Develop"
    showHow   : yes
    howToSteps: ['showBuyVMMenu']
  ,
    cssClass  : "develop more-1"
    content   : """<p> Let's change your homepage! <a href= "#"> http://{{#(profile.nickname)}}.kd.io </a> </p>
                   <p> Open your index.html file under Web folder on file tree.</p>
                   <p> change the content and save your file</p>
                   <p> Then save it with ⌘+S or clicking the save button to the right of your tabs </p>

                """
    section   : 7
    parent    : 5
    showHow   : yes
    howToSteps: ['changeIndexFile']
  ,
    cssClass  : "develop more-1"
    content   : """
                   <p>Now type</p>
                   <strong>http://{{#(profile.nickname)}}.kd.io</strong>
                   </p> Yes you made it!! </p>
                   <p>Now continue to learn more about development environment </p>
                """
    section    : 8
    parent     : 5

  ,
    cssClass  : "develop more-2"
    content   : """<p>When you open a new file from the file tree, a new tab is created. Use tabs to manage working on multiple files at the same time.</p>
                   <p>You can also create a new file using either the “+” button on Tabs, or by right-clicking the file tree.</p>
                   <p>Save the new file to your file tree by clicking the save button to the right of your tabs. </p>
                """
    section   : 9
    parent    : 5
  ,
    cssClass  : "develop more-4"
    content   : """
                <p>There are some handy keybord bindings when working with Ace</p>
                <strong>Push ⌘+S To Save File</strong>
                <strong>Push super+⌘+S To Save File As</strong>
                """
    embed     : BookDevelopButton
    routeURL  : ""
    section   : 5
    parent    : 5
  ,
    cssClass  : "develop more-3"
    content   : """
                <p>Dont’ forget about your settings in the bottom corner. Here you can change the syntax, font, margins, and a whole lot of other features.</p>
                """
    embed     : BookDevelopButton
    routeURL  : ""
    section   : 10
    parent    : 5
    showHow   : yes
    howToSteps: ['showAceSettings']
  ,
    title     : "Terminal"
    content   : """<p>Terminal is a very important aspect of development, that's why we have invested a lot of time to provide a fast, smooth and responsive console.</p>
                   <p>It's an Ubuntu VM that you can use to program Java,C++,Perl,Python,Ruby,Node,Erlang,Haskell and what not, out of the box. Everything is possible. This VM is not a simulation, it is a real computer, and it's yours.</p>"""
    routeURL  : "/Develop/Terminal"
    section   : 11
    parent    : 5
  ,
    cssClass  : "terminal more-1"
    content   : """
                <p> Let's test our terminal, type code below to see list files and folders on root and hit enter!.</p>
                <code> ls -la / </code>
                <p>You should see your file tree.. Now If you are okay with them lets get serious and be ROOT! </p>
                <code> sudo su </code>
                <p>Voila!! You are now root on your own VM</p>
                <p>You can also install new packages. Search mySQL packages and install if you want! </p>
                <code> apt-cache search mysql </code>
                """
    section   : 12
    parent    : 5
  ,
    cssClass  : "terminal more-1"
    content   : """
                <p>We said that we give you a VM that is really VM. So if you want to shutdown your VM, just click from Menu and it's ok.</p>
                <p> Re-initializing your VM will reset all of your settings that you've done in root filesystem. This process will not remove any of your files under your home directory.</p>
                <strong>From below, Click Personal VM ,see what you can do </strong>
                """
    routeURL  : ""
    section   : 13
    parent    : 5
  ,
    title     : "Apps"
    content   : """<p>What makes Koding so useful are the apps provided by its users. Here you can perform one click installs of incredibly useful applications provided by users and major web development tools.</p>
                   <p>In addition to applications for the database, there are add-ons, and extensions to get your projects personalized, polished, and published faster.</p>"""
    routeURL  : "/Apps"
    section   : 6
    parent    : 0
  ,
    title     : "Groups"
    cssClass  : "groups-intro"
    content   : """<p>Join a group which you want to discuss, share code and find tutorials about specific topic!</p>
                   <p>By changing group you are completely changing context. When you are on a group page, you only see updates, VM's and Members of that group.</p>
                """
    routeURL  : "/Groups"
    section   : 7
    parent    : 0
  ,
    title     : "Chat"
    cssClass  : "chats-intro"
    content   : """<p> You can chat with your friends or anyone from koding. Just type his/her name and hit enter thats all!</p>
                """
    section   : 8
    parent    : 0
    showHow   : yes
    howToSteps: ['showConversationsPanel']
  ,
    title     : "Account"
    content   : """<p>Here is your control panel! Manage your personal settings, add your Facebook, Twitter, Github etc.. See payment history and more..</p>
                """
    routeURL  : "/Account"
    section   : 9
    parent    : 0
  ,

    title     : "Etiquette"
    content   : """<p>Seems like a fancy word, huh? Don’t worry, we’re not going to preach. This is more of a Koding Mission Statement. Sure, Koding is built around cloud development, but its second pillar is community.</p>
                   <p>So what does that mean? That means that developers of all skill levels are going to grace your activity feed. Some need help, some will help others, some will guide the entire group, whatever your role is it’s important to remember one important word: help.</p>
                   <p>Help by providing insight and not insult to people asking basic questions. Help by researching your question to see if it has had already been given an answer. And lastly, help us make this service the best it can be!</p>"""
    section   : 10
    parent    : 0
  ,
    title     : "Enjoy!"
    content   : """<span>book and illustrations by <a href='http://twitter.com/petorial' target='_blank'>@petorial</a></span>
                   <p>That's it, we hope that you enjoy what we built.</p>"""
    section   : -1
]
