metrics
-------

metrics is a multiplexer to send events to different analytic
services. Currently on `mixpanel` is implemented.

Example:

```go
  trackers := InitTrackers(
    NewMixpanelTracker("your token here"),
  )

	trackers.Track("simple event")

  trackers.TrackWithProp("event with properties", Prop{
    "favorite movie": "indiana jones",
  })
```
