__bookPages = [
    title     : "Table of Contents"
    embed     : BookTableOfContents
    section   : -1
  ,
    title     : "A Story"
    content   : "Once upon a time, there were developers just like you<br/>Despite the sea between them, development had ensued"
    routeURL  : ""
    section   : 11
    parent    : 0
  ,
    cssClass  : "a-story more-1"
    content   : "Over time they noticed, that ‘how it’s done’ was slow<br/>“With 1,000 miles between us, problems start to show!”"
    routeURL  : ""
    section   : 11
    parent    : 1
  ,
    cssClass  : "a-story more-2"
    content   : "“Several different services for just a hello world?<br/>And each a different cost!” Their heads began to swirl."
    routeURL  : ""
    section   : 11
    parent    : 2
  ,
    cssClass  : "a-story more-3"
    content   : "They made up their minds, “It’s time to leave the crowd</br>all of these environments should reside in the cloud!”"
    routeURL  : ""
    section   : 11
    parent    : 3
  ,
    cssClass  : "a-story more-4"
    content   : "“Then simplify the process, from several steps to one<br/>A terminal in a browser? That would help a ton!”"
    routeURL  : ""
    section   : 11
    parent    : 4
  ,
    cssClass  : "a-story more-5"
    content   : "Build it on a community, we'll teach and learn together<br/>Of course we'll charge nothing for it."
    routeURL  : ""
    section   : 11
    parent    : 5
  ,
    cssClass  : "a-story more-6"
    content   : "“This sounds amazing!” They each began to sing,<br/>“Let’s package it together and call it Koding!”"
    routeURL  : ""
    section   : 11
    parent    : 5
  ,
    title     : "Foreword"
    content   : """<p>Koding is your new development computer in your browser.</p>
                   <p>As an experienced developer you will find awesome tools to set up shop here.</p>
                   <p>If you are new to programming, writing your first "Hello World" application literally is 5 minutes away from you.</p><p> Welcome home - This is going to be fun!</p>"""
    routeURL  : ""
    section   : 11
    parent    : 0
  ,
    title     : "Welcome to Koding!"
    content   : """
                <p class="centered">It's probably your first time using Koding! Follow this quick tutorial to learn everything you can do with this amazing tool!</p>
                """
    routeURL  : "/Activity"
    section   : 1
    embed     : StartTutorialButton
    parent    : 0
  ,
    title     : "Activity"
    content   : "<p>Think of this as the town center of Koding. Ask questions, get answers, start a discussion...be social! The community is a great tool for development, and here is where you can get started. In fact, let’s start with your first status update! Just click the 'Show me how!' button at the top of this page!</p>"
    routeURL  : "/Activity"
    section   : 3
    parent    : 0
    showHow   : yes
    howToSteps: ['enterNewStatusUpdate']
    menuItem  : "Activity"
  ,
    title     : "Members"
    content   : """<h2>Welcome to the club!</h2>
                   <p>Here you’ll find all of Koding’s members. To find another member, just enter a name in the search bar and hit enter! This is a place where you can connect and collaborate. Feel free to follow the whole Koding Team!</p>"""
    routeURL  : "/Members"
    section   : 2
    parent    : 0
  ,

    title     : "Topics"
    embed     : BookTopics
    content   : """<p>Wouldn’t it be great if you could listen to only what you cared about? Well, you can! Topics let you filter content to your preferences. Select your Topics and if someone shares any information about your topic, you will be informed.</p>
                """
    routeURL  : "/Topics"
    section   : 4
    parent    : 0
  ,
    title     : "Develop"
    content   : """<p>This is where the magic happens! Your file tree, your Virtual Machines, your applications and more are located here in the Develop section</p>
                """
    routeURL  : "/Develop"
    section   : 5
    parent    : 0
    showHow   : no
  ,
    cssClass  : "develop more-1"
    content   :
              """
              <h2>What are the folders in my Develop tab?</h2>
              <p>The Applications folder is a place where your koding applications are located. The Web Folder is where your http://{{#(profile.nickname)}}.kd.io adress is accessable at. Other folders do what they intend to. You can create new folders by right-clicking on your file tree!</p>
              """
    section   : 1
    parent    : 5
    showHow   : yes
    howToSteps: ['showFileTreeFolderAndFileMenu']
    menuItem  : "Develop"
  ,
    cssClass  : "develop more-1"
    content   : """<h2> Your default applications: </h2>
                   <p><strong>Ace</strong> is your perfect text editor on cloud! Use it to edit documents in your file tree! </p>
                   <p><strong>Terminal</strong> is a terminal for your Virtual Machine. You have full root access to the machine!
                      <div class='tip'><span>tip:</span> your root password is your koding password. </div>
                   </p>
                """
    section   : 2
    parent    : 5
    showHow   : no
    routeURL  : 'Develop'
  ,

    cssClass  : "develop enviroments"
    content   : """<h2>Control Your Virtual Machine!</h2>
                   <p>It's easy to control your Virtual Machine(s)! Some basic actions you can perform are listed below:</p>
                   <ul>
                     <li>Turn your Virtual Machine on and off</li>
                     <li>Re-Initialize your Virtual Machine</li>
                     <li>Delete your Virtual Machine and start with a fresh one</li>
                     <li>Checkout the Virtual Machine menu for more features</li>
                   </ul>
                """
    section   : 3
    parent    : 5
    showHow   : yes
    howToSteps: ['showVMMenu']
    menuItem  : "Develop"

  ,
    cssClass  : "develop enviroments more"
    content   : """<h2>Open Virtual Machines in your Terminal</h2>
                   <p>If you have more than 1 Virtual Machine, you can open that Virtual Machine's
                   menu by clicking terminal icon on Virtual Machine menu.</p>
                """
    section   : 4
    parent    : 5
    showHow   : yes
    howToSteps: ['openVMTerminal']
    menuItem  : "Develop"
  ,
    cssClass  : "develop more-1"
    content   : """<p>You can view your recently opened files by moving your cursor to the footer area. A new section will slide up displaying your recently opened files!</p>
                """
    section   : 5
    parent    : 5
    routeURL  : "/Develop"
    showHow   : yes
    howToSteps: ['showRecentFiles']
    menuItem  : "Develop"
  ,
    cssClass  : "develop buy more-1"
    content   : """<h2>Need more Virtual Machines?</h2>
                   <p>It's easy to buy more Virtual Machines. Paid machines will never go down and will remain in an 'up' state 24/7</p>
                """
    section   : 6
    parent    : 5
    routeURL  : "/Develop"
    showHow   : yes
    howToSteps: ['showNewVMMenu']
    menuItem  : "Develop"
  ,
    cssClass  : "develop more-1"
    content   : """<p>It's easy to change your homepage! Currently: <a href= "#"> http://{{#(profile.nickname)}}.kd.io </a>
                  <ol>
                    <li> Open your index.html file under Web folder on file tree.</li>
                    <li> change the content and save your file</li>
                    <li> Then save it with ⌘+S or clicking the save button to the right of your tabs </li>
                    <li>It's done!! No FTP no SSH no other stuff!! Just click and change</li>
                  </ol>
                """
    section   : 7
    parent    : 5
    showHow   : yes
    howToSteps: ['changeIndexFile']
    menuItem  : "Develop"

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
                <ul>
                  <li>save file <span>Ctrl-S</span></li>
                  <li>saveAs <span>Ctrl-Shift-S</span></li>
                  <li>find text <span>Ctrl-F</span></li>
                  <li>find and replace text <span>Ctrl-Shift-F</span></li>
                  <li>compile application <span>Ctrl-Shift-C</span></li>
                  <li>preview file Ctrl-Shift-P </li>
                </ul>
                """
    embed     : BookDevelopButton
    routeURL  : ""
    section   : 5
    parent    : 5
  ,
    cssClass  : "develop more-3"
    content   : """
                <p>Dont’ forget about your settings in the bottom corner.
                Here you can change the syntax, font, margins, and a whole
                lot of other features.</p>
                """
    embed     : BookDevelopButton
    routeURL  : ""
    section   : 10
    parent    : 5
    showHow   : yes
    howToSteps: ['showAceSettings']
    menuItem  : 'Develop'
  ,
    title     : "Terminal"
    content   : """<p>Terminal is a very important aspect of development, that's why we have invested a lot of time to provide a fast, smooth and responsive console. It's an Ubuntu Virtual Machine that you can use to program Java,C++,Perl,Python,Ruby,Node,Erlang,Haskell and what not, out of the box. Everything is possible. This Virtual Machine is not a simulation, it is a real computer, and it's yours.</p>"""
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
                <p>Voila!! You are now root on your own Virtual Machine</p>
                <p>You can also install new packages. Search mySQL packages and install if you want! </p>
                <code> apt-cache search mysql </code>
                """
    section   : 12
    parent    : 5
  ,

    title     : "Apps"
    content   : """<p>What makes Koding so useful are the apps provided by its users. Here you can perform one-click installs of incredibly useful applications provided by users and major web development tools. In addition to applications for the database, there are add-ons, and extensions to get your projects personalized, polished, and published faster.</p>"""
    routeURL  : "/Apps"
    section   : 6
    parent    : 0
  ,
    title     : "Groups"
    cssClass  : "groups-intro "
    content   : """<p class='centered'>Join a group which you want to discuss, share code and find tutorials about specific topic! By changing group you are completely changing context. When you are on a group page, you only see updates, Virtual Machines and Members of that group.</p>
                """
    routeURL  : "/Groups"
    section   : 7
    parent    : 0
  ,
    title     : "Chat"
    cssClass  : "chats-intro"
    content   : """<p class='centered'>You can chat with your friends or anyone from koding. Just type his/her name and hit enter thats all!</p>
                """
    section   : 8
    parent    : 0
    showHow   : yes
    howToSteps: ['showConversationsPanel']
  ,
    title     : "Account"
    content   : """<p class='centered'>Here is your control panel! Manage your personal settings, add your Facebook, Twitter, Github etc.. See payment history and more..</p>
                """
    routeURL  : "/Account"
    menuItem  : "Account"
    howToSteps: ['showAccountPage']
    section   : 9
    parent    : 0
  ,

    title     : "Etiquette"
    content   : """<p>Seems like a fancy word, huh? Don’t worry, we’re not going to preach. This is more of a Koding Mission Statement. Sure, Koding is built around cloud development, but its second pillar is community.</p>
                   <p>So what does that mean? That means that developers of all skill levels are going to grace your activity feed. Some need help, some will help others, some will guide the entire group, whatever your role is it’s important to remember one important word: help.</p>
                   <p>Help by providing insight and not insult to people asking basic questions. Help by researching your question to see if it has had already been given an answer. And lastly, help us make this service the best it can be!</p>"""
    section   : -1
  ,
    title     : "Enjoy!"
    content   : """<span>book and illustrations by <a href='http://twitter.com/petorial' target='_blank'>@petorial</a></span>
                   <p>That's it, we hope that you enjoy what we built.</p>"""
    section   : -1
]
