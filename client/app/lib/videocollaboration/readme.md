
## Video Subscribers Lifecycle

### When a connection is created: `connectionCreated`

```coffee
@bound 'handleConnectionCreated'
```

Initializes a new `ParticipantType.Subscriber` via `VideoCollaborationModel::setParticipantConnected` method.

Initalized `subscriber` object will have `connected` state.

It will emit `ParticipantConnected` event along with the `subscriber` instance that is just created.


### When a subscriber from a connection starts to publish: `streamCreated`

```coffee
@bound 'handleSubscriberCreated'
```

Updates the `ParticipantType.Subscriber` instance that is associated with the created stream's `connection` id to be `active`

It will emit `ParticipantJoined` event along with the `subscriber` instance.


### When a subscriber from a connection stops to publish: `streamDestroyed`

```coffee
@bound 'handleStreamDestroyed'
```

Updates the `ParticipantType.Subscriber` instance that is associated with the created stream's `connection` id to be `connected`.

It will emit `ParticipantLeft` event along with the `subscriber` instance.


### When a connection is destroyed: `connectionDestroyed`

```coffee
@bound 'handleConnectionDestroyed'
```

Unregisters the `subscriber` object.

It will emit 'ParticipantDisconnected' event along with the `subscriber` instance.


## Video participant types

`Opentok` uses its own vocabulary for users.

- `Publisher` user is the loggedin user that is sending video. Everytime publisher is user itself.
- `Subscriber` user is a user that is connected to the session other than the `Publisher` user itself.

`Koding` builds its own vocabulary on top of `Opentok` participant types, and also it's not trying to use it as class instances but rather a struct type that can be used by other functions.

- `ParticipantType.Participant` - abstract Participant type.
- `ParticipantType.Subscriber`  - A type to represent a subscriber.
- `ParticipantType.Publisher`   - A type to represent user's publisher.

Example:

```coffee
# a ParticipantType.Subscriber instance
{
  nick: 'foo-user'
  type: 'subscriber'
  videoData: <OT.Subscriber>
  state: constants.PARTICIPANT_OFFLINE
}

# a ParticipantType.Publisher instance
{
  nick: 'umut'
  type: 'publisher'
  videoData: <OT.Publisher>
  state: constants.PARTICIPANT_ACTIVE
}
```

#### Properties

`nick` and `type` are pretty self-explanatory.

`videoData`: Related Opentok participant instance.
`state`: Different than Opentok itself our participants are stateful:

  - `VideoConstants.PARTICIPANT_OFFLINE`
  - `VideoConstants.PARTICIPANT_CONNECTED`
  - `VideoConstants.PARTICIPANT_PUBLISHING`

The basic flow is the following:

When a user is logged-in to video chat.
- User connects to OpenTok video session.
- User gets all the subscribers of session. (via `connectionCreated` and `streamCreated` methods.)
- User subscribes to those sessions. (`streamCreated`)

- When user is host: Publish with both audio and video.
- When user is participant: Don't publish to anything (initially)

When a user (regular participant) want to publish to video chat:
- It will ensure that the user is publishing.
- Depending on the action toggle that user has clicked (audio or video) it will activate the video/audio.


## Collaboration Channel Participants

We added 2 different models into our system: `ChannelParticipantsModel` and `CollaborationChannelParticipantsModel`.

  - Whenever a participant status is changed, `VideoModel` emits necessary events.
  - `VideoCollaborationController` will listen to those changes.
  - It will emit those events to `IDEChatView`.
  - `IDEChatView` will do its job with the event, then it will call necessary `IDEChatMessagePane` method.
  - `IDEChatMessage` will call the `CollaborationParticipantsModel` to update its lists.


