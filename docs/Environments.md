Environments
============


We now have four main parts for new environments infrastructure:

  - Kloud Kite

    Kloud, which is responsible to manage machines on several providers.
    via their APIs. It also responsible to deploy Klient kite to target
    machine.

    For now Kloud Kite supports following providers:

    - Koding (Amazon)
    - Amazon (AWS)
    - DigitalOcean
    - Rackspace


  - Klient Kite

    Klient, which is responsible to provide following operations on target
    machine:

    - Filesystem operations (designed to be used by Filetree in koding/client)
    - Terminal (designed to be used by Terminal in koding/client)
    - Exec (direct command run on target)


  - Koding Backend (in social worker/kite)

    Koding backend is responsible to manage credentials, stacks and machine
    data which `Kloud kite` needs. Also it provides API for koding/client side.

    ComputeProvider is responsible to create machines, it can also provide an
    interface to work with providers, which providers are service provider that
    `Kloud kite` supports. Providers also have individual interfaces which are
    based on `ProviderInterface` which provides following methods:

      - ping           : Test method to send pings to provider
      - create         : Creates required meta data for `Kloud kite`
      - postCreate     : Handles operations after create if provider requires
      - remove         : Handles operations for remove if provider requires
      - update         : Handles operations for update if provider requires
      - fetchAvailable :

        Returns list of available instance types by provider. This data
        consists of following:

        ```
          Array of

          {
            name  : "512mb"
            title : "512 MB"
            spec  : {
              cpu : 1, ram: 512, storage: 20, transfer: "1TB"
            }
            price : "$5 per Month"
          }
        ```

    These provider definitions can be found under:

      - `/workers/social/lib/social/models/computeproviders`


    In the Koding Backend (social worker) we have following models in DB:


      - **JStack**

        Stack model, which is a packed storage for followings:

        - Rules (WIP)
        - Domains  -> `ObjectIDs` of `JDomain`s
        - Machines -> `ObjectIDs` of `JMachine`s
        - Extras (WIP)
        - and the `configuration` which is shared with every member of this
          stack. This configuration is a key/value pair and exposing as
          environment variables while building to machines that includes.


      - **JStackTemplate**

        It's the template version of `JStack`, basically its using as data
        source to create new stacks. It has one extra field (`connections`) to
        keep track relations between domains with machine, rules with domains
        etc.

        These templates can be assigned as default template for `JGroups`
        which will provide to create predefined machine stacks for every member
        of that group. This settings can be found in *Group Dashboard*. If
        `ComputeProvider`s `createGroupStack` method is getting called, this
        pre-defined stack template will be using for request owner.

        `JStackTemplate`s can be re-usable and shareable with others (there may
        be an AppStore category for it) there are three levels for accessing:

          - private : only by owner
          - group   : only by same group members of owner
          - public  : everyone


      - **JMachine**

        Most important model for new environment stack, it's the key for user
        to work with his machines. `Kloud kite` takes as base this document to
        build machine.

        It includes all required information to build a machine and its also
        used by koding/client to represent machine on the UI.

        `JMachine`'s meta field does not have any specified structure instead
        its getting shaped based on the specified provider.

        And there is `credential` field which includes the `publicKey` of
        assigned `JCredential` which is also used by `Kloud kite` to do API
        calls for specified `provider`.


        Machines has predefined states which are also defined in Kloud kite and
        kept under `status.state` field:

          - NotInitialized : Initial state, machine instance does not exists
          - Building       : Build started machine instance creating...
          - Starting       : Machine is booting...
          - Running        : Machine is physically running
          - Stopping       : Machine is turning off...
          - Stopped        : Machine is turned off
          - Rebooting      : Machine is rebooting...
          - Terminating    : Machine is getting destroyed...
          - Terminated     : Machine is destroyed, not exists anymore
          - Unknown        : Machine is in an unknown state needs to solved
                             manually

          * States which description ending with '...' means its an ongoing
          proccess which you may get progress info from Kloud kite about it

        `JMachine`s are getting created by `ComputeProvider` (exposed to
        `KD.remote.api`) and after that its not modified by Koding Backend
        anymore, rest of changes on this model is getting done by `Kloud kite`
        after this point. When build completed and `Klient kite` deployed to
        target machine by `Kloud kite`, the `queryString` field is also updated
        by `Kloud kite` to provide an access point to `Klient kite` on the
        target machine from client-side.

        Beside the `_id` field there is another field to be used by client-side
        requirements called `uid` which consists of following:

          - 0     letter 'u'
          - 1     first letter of `username`
          - 2     first letter of `group slug`
          - 3     first letter of `provider`
          - 4..12 32-bit random hex string

          * JMachine.one method can also be used with `uid` beside the `_id`.

        There is also another feature which provides to define provision
        scripts for machine, which are a list of `JProvisioner` ids. For now
        we are supporting only one provisioner but the data field is ready for
        future requirements. Provisioners are basically shell scripts and they
        are getting executed right after build completes.


      - **JProvisioner**

        Provisioner scripts for `JMachine`s, they are shell scripts but `type`
        of provisioners can be extended. It keep tracks of the sum (`sha1`) of
        script content for comparing requirements when needed.

        `JProvisioner`s can also be re-usable and shareable with others (there
        may be an AppStore category for it) levels for accessing to it are same
        with `JStackTemplate`.

        They can be reachable with `slug`s too like `gokmen/django-installer`


      - **JCredential**

        Credentials are designed to be keep sensitive information like API keys
        and accessTokens. To provide that its splitted into two parts;
        `JCredential` and `JCredentialData` which last one keeps the sensitive
        data and only exposed to client when permissions of request owner
        allows it. `JCredential`s can be sharable with individual users
        (`JUser`) or with a group (`JGroup`), and sharing has two different
        levels:

          - as owner : target user can do everything with this credential
                       one can read, update, delete or share with someone else
          - as user  : target user can only use the key via `ComputeController`
                       one can't read the sensitive data or change in any way.

      - **JCredentialData**

        Sensitive information part of `JCredential` which just keeps data and
        does not exposed to `KD.remote.api`


  - Koding Front-end

    (WIP)
