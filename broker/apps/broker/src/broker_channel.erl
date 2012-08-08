-module(broker_channel, [Conn, Exchange]).

-export([send/1, send/2, close/0, close/2, info/0]).

send(Data) ->
    Conn:send(Data).

send(Event, Data) ->
    E = {<<"event">>, Event},
    Channel = {<<"channel">>, Exchange},
    Payload = {<<"payload">>, Data},
    Conn:send(jsx:encode([E, Channel, Payload])).

close() ->
    close(1000, "Normal closure").

close(_Code, _Reason) ->
    Event = {<<"event">>, <<"client-unsubscribe">>},
    Channel = {<<"channel">>, Exchange},
    Conn:send(jsx:encode([Event, Channel])).

info() ->
    Conn:info() ++ [{topic, Exchange}].