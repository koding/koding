Environments
============


We have several parts for new environments infrastructure. You can find the
explanation of each part below:

  - Kontrol Kite

    TODO: arslan, fill it

  - Kloud Kite

    TODO: arslan, fill it

    Kloud, which is responsible to manage machines on several providers.
    via their APIs. It also responsible to deploy Klient kite to target
    machine.

    For now Kloud Kite supports following providers:

    - Koding (Amazon)
    - Amazon (AWS)
    - DigitalOcean
    - Rackspace


  - Klient Kite

    TODO: arslan, fill it

    Klient, which is responsible to provide following operations on target
    machine:

    - Filesystem operations (designed to be used by Filetree in koding/client)
    - Terminal (designed to be used by Terminal in koding/client)
    - Exec (direct command run on target)


  - Social Worker Backend

    Social worker backend is responsible to manage credentials, stacks and machine
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


      - **JComputeStack**

        Stack model, which is a packed storage for followings:

        - Rules (WIP)
        - Domains  -> `ObjectIDs` of `JProposedDomain`s
        - Machines -> `ObjectIDs` of `JMachine`s
        - Extras (WIP)
        - and the `configuration` which is shared with every member of this
          stack. This configuration is a key/value pair and exposing as
          environment variables while building to machines that includes.


      - **JStackTemplate**

        It's the template version of `JComputeStack`, basically its using as data
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


  - **Koding Front-end**

    ComputeController
    -----------------

    Front-end (client) structure is also similar with backend. There is a main
    controller singleton for managing machines called `ComputeController`, it's
    responsible to fetch stacks/machines form `Social worker` and it's a
    wrapper in client-side for `Kloud kite` at the same time. Which makes it
    the center of following operations related with machines:

      - **build**
      - **destroy**
      - **start**
      - **stop**
      - **info**

    All of these methods requires a `Machine` instance. `Machine` instance is
    a client-side implementation of `JMachine` which gets data from `Social`
    and interacts with the physicall machine by `Klient kite` on the machine.

    To get a `Machine` instance one can pass `JMachine` instance to its
    constructor like `new Machine { machine: aJMachineInstance }` or can use
    one of the following methods from `ComputeController`:

      - **fetchMachine**   : by `JMachine`'s `ObjectId` or `uid`
      - **queryMachines**  : by passing a valid `JMachine` mongo query like:

        ` { provider: "digitalocean" } ` to get a list of `Machine` instances
        from *DigitalOcean* provider.

    To run the `initScript` (`JProvisioner`) of machine one can use the
    `runInitScript` method of `ComputeController` which runs the init script in
    a `TerminalModal` by default. Can be run as background process too by
    passing `false` as second parameter.

    `ComputeController` itself does not include any UI code, for these kind of
    requirements we are using `ComputeController.UI`


    ComputeEventListener
    --------------------

    There is a pull based event information mechanism provided by `Kloud kite`
    to be able to use it efficiently we have a central event listener called
    `ComputeEventListener` which is intialized in `ComputeController` singleton

    It has a internal ticker mechanism which happens only there is something to
    listen left in the listeners queue. It sends corresponding events over
    `ComputeController` singleton for followings when percentage hits `100`:

      - "MachineStopped" when a machine stops
      - "MachineStarted" when a machine starts
      - "MachineBuild" when a `NotInitialized` or `Terminated` machined built
      - "MachineDestroyed" when a machine destroyed

      all of these events are emitting with a `machineId` (`JMachine._id`)
      beside these separate events it also emits `stateChanged-#{machine._id}`
      with the state of machine.

    And for all other individual state changes it emits

      - `public-#{machine._id}` with whole `event` object which consists of

        - `EventId`    : eventType-jmachineId
        - `Message`    : event message
        - `Status`     : machine status
                         (same as defined in `JMachine.Status.State`)
        - `Percentage` : percentage of the event between `0-100`
        - `TimeStamp`  : last updated event time

      - `eventId` with same `event` object

    Anytime a listener can be added by `addListener` method with `type` of the
    event and the `_id` of `JMachine` which is also same in `Machine`.

    A machine state can be triggered manually by calling `triggerState` with
    target `Machine` instance and an `event` object.

    When `ComputeController.info` method called on a machine which has any of
    the following states:

      - `Stopping`    : "stop"
      - `Building`    : "build"
      - `Starting`    : "start"
      - `Rebooting`   : "restart"
      - `Terminating` : "destroy"

    described event types are starting to listening by `ComputeEventListener`
    which provides continuity when user refresh pages, progress of machines
    starts where its left.
