%% MIT License
%% ===========

%% Copyright (c) 2012 Son Tran <esente@gmail.com>

%% Permission is hereby granted, free of charge, to any person obtaining a
%% copy of this software and associated documentation files (the "Software"),
%% to deal in the Software without restriction, including without limitation
%% the rights to use, copy, modify, merge, publish, distribute, sublicense,
%% and/or sell copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following conditions:

%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.

%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
%% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
%% DEALINGS IN THE SOFTWARE.
-module(broker_app).

-behaviour(application).

-behaviour(cowboy_http_handler). %% To handle the default route

%% Application callbacks
-export([start/0, start/2, stop/1]).

%% Cowboy callbacks
-export([init/3, handle/2, terminate/2]).
-record (client, {id, socket_id, vhost = none, subscriptions=dict:new()}).
-include_lib("amqp_client/include/amqp_client.hrl").
-compile([{parse_transform, lager_transform}]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() ->
  application:start(crypto),
  application:start(public_key),
  application:start(ssl),
  application:start(sockjs),
  application:start(cowboy),
  lager:start(),
  application:start(broker, permanent).

start(_StartType, _StartArgs) ->
  lager:set_loglevel(lager_console_backend, get_env(verbosity, info)),

  PidFile = get_env(pid_file, "./broker.pid"),
  ShellPid = os:getpid(),

  case file:write_file(PidFile, ShellPid) of
    ok -> io:format("Pid written to file ~p~n", [PidFile]);
    {error, Reason} ->
      io:format("Could not write to file ~p because: ~p~n", [PidFile, Reason])
  end,

  NumberOfAcceptors = 100,
  Port = get_env(port, 8008),

  error_logger:tty(get_env(verbose, true)),
  
  SockOpts = [{websocket, true}, {cookie_needed, true}],
  SockjsState = sockjs_handler:init_state(
          <<"/subscribe">>, fun handle_client/3, {}, SockOpts),
  VhostRoutes = [
    {
      [<<"subscribe">>, '...'], 
      sockjs_cowboy_handler, 
      SockjsState
    },
    {'_', ?MODULE, []} % The rest is handled within this module.
  ],
  Routes = [{'_',  VhostRoutes}], % any vhost

  lager:info(" [*] Running at http://localhost:~p", [Port]),

  case cowboy:start_listener(http, NumberOfAcceptors,
                    cowboy_tcp_transport, [{port, Port}],
                    cowboy_http_protocol, [{dispatch, Routes}]) of
    {ok, _Pid} -> app_sup:start_link();
    {_, _} -> {error, "failed to start Erlang broker"}
  end.

%%% State is passed from Module:start/2 or []. Return new state for stop/1
prep_stop(State) -> State.

stop(_State) ->
  ok.

%% ===================================================================
%% Cowboy callbacks
%% ===================================================================

init({_Any, http}, Req, []) ->
  {ok, Req, []}.

handle(Req, State) ->
  {Path, Req1} = cowboy_http_req:path(Req),
  {ok, Req2} = case Path of
    [<<"broker.js">>] ->
      {ok, Data} = file:read_file("./apps/broker/priv/www/js/broker.js"),
      cowboy_http_req:reply(200, [{<<"Content-Type">>, "application/javascript"}],
                 Data, Req1);

    _ ->
      cowboy_http_req:reply(404, [],
                 <<"404 - Nothing here\n">>, Req1)
    end,
  {ok, Req2, State}.

terminate(_Req, _State) ->
  ok.

%% ===================================================================
%% SockJS_MQ Handlers
%% ===================================================================

handle_client(Conn, init, _State) ->
  SocketId = list_to_binary(uuid:to_string(uuid:uuid4())),
  Event = <<"connected">>,
  EventProp = {<<"event">>, Event},
  Payload = {<<"socket_id">>, SocketId},
  Conn:send(jsx:encode([EventProp, Payload])),

  {ok, #client{socket_id=SocketId}};

%%--------------------------------------------------------------------
%% Handle vhost setting from the client
%%--------------------------------------------------------------------
handle_client(Conn, {recv, Data},
          State=#client{vhost=none,socket_id=SocketId}) ->
  case jsx:decode(Data) of
    [{<<"vhost">>, VHost}] ->
      Event = <<"connected">>,
      Payload = {<<"socket_id">>, SocketId},
      send_system_event(Conn, Event, [Payload], VHost),
      {ok, State#client{vhost=VHost}};
    _ ->
      {ok, State}
  end;

%%--------------------------------------------------------------------
%% Handle receiving data when vhost is set
%%--------------------------------------------------------------------
handle_client(Conn, {recv, Data}, 
          State=#client{subscriptions=Subscriptions,
          vhost=VHost}) ->

  [Event, Exchange, _Payload, _Meta] = Decoded = decode(Data),
  Check = {Event, dict:is_key(Exchange, Subscriptions)},
  NewSubs = handle_event(Conn, Check, Decoded, Subscriptions, VHost),
  {ok, State#client{subscriptions=NewSubs}};

%%--------------------------------------------------------------------
%% Handle disconnection from the client
%%--------------------------------------------------------------------
handle_client(Conn, closed, #client{socket_id=SocketId,vhost=VHost,
                  subscriptions=Subscriptions}) ->
  Event = <<"disconnected">>,
  Sid = {<<"socket_id">>, SocketId},
  Exchanges = {<<"exchanges">>, dict:fetch_keys(Subscriptions)},
  send_system_event(Conn, Event, [Sid, Exchanges], VHost),

  Handler = fun
    (Sub) ->
      broker:trigger(Sub, Event, jsx:encode([Sid]), [], true),
      broker:unsubscribe(Sub)
  end,

  case dict:size(Subscriptions) of 
    0 -> ok;
    _ ->
      List = dict:to_list(Subscriptions),
      [Handler(Subscription) 
        || {_Exchange, Subscription} <- List]
  end,
  {ok, #client{}};

handle_client(_Conn, Other, State) ->
  io:format("Other data ~p~n", [Other]),
  {ok, State}.

% handle_event(Conn, {<<"client-presence">>, false}, Data, Subs, VHost) ->
%   [_Event, Where, Who, _Meta] = Data,
%   % This only acts as a key so that it can be used to
%   % remove the subscription later from the dictionary.
%   Exchange = <<Who/bitstring,Where/bitstring,"-presence">>,
%   case dict:find(Exchange, Subs) of
%     {ok, Subscription} ->
%       broker:unsubscribe(Subscription),
%       dict:erase(Exchange, Subs);
%     error ->
%       VHostToUse = get_vhost(Exchange, VHost),
%       case broker:presence(Conn, Where, Who, VHostToUse) of
%         {error, _Error} -> Subs;
%         {ok, Subscription} ->            
%           dict:store(Exchange, Subscription, Subs)
%       end
%   end;

%%--------------------------------------------------------------------
%% Try to bind an event for the first time
%%--------------------------------------------------------------------
handle_event(Conn, {<<"client-bind">>, false}, Data, Subs, VHost) ->
  [Event, Exchange, _Routing, _Payload, _Meta] = Data,
  VHostToUse = get_vhost(Exchange, VHost),
  case broker:subscribe(Conn, Exchange, VHostToUse) of
    {error, _Error} -> Subs;
    {ok, Subscription} ->
      NewSubs = dict:store(Exchange, Subscription, Subs),
      handle_event(Conn, {Event, true}, Data, NewSubs, VHost)
  end;

%%--------------------------------------------------------------------
%% Bind to an event after already declaring the exchange
%%--------------------------------------------------------------------
handle_event(_Conn, {<<"client-bind">>, true}, Data, Subs, _) ->
  [_Event, Exchange, Routing, _Payload, _Meta] = Data,
  Subscription = dict:fetch(Exchange, Subs),
  broker:bind(Subscription, Routing),
  Subs;

handle_event(_Conn, {<<"client-unbind">>, true}, Data, Subs, _) ->
  [_Event, Exchange, Routing, _Payload, _Meta] = Data,
  Subscription = dict:fetch(Exchange, Subs),
  broker:unbind(Subscription, Routing),
  Subs;

% handle_event(_Conn, {<<"client-unsubscribe">>, true}, Data, Subs, _) ->
%   [_Event, Exchange, _Payload, _Meta] = Data,
%   Subscription = dict:fetch(Exchange, Subs),
%   broker:unsubscribe(Subscription),
%   dict:erease(Exchange, Subs);

handle_event(_Conn, {<<"client-",_EventName/binary>>, true}, Data, Subs, _) ->
  [Event, Exchange, _Routing, Payload, Meta] = Data,
  RegExp = "^secret-",
  case re:run(Exchange, RegExp) of
    nomatch -> Subs;
    {match, _} ->
      Subscription = dict:fetch(Exchange, Subs),
      broker:trigger(Subscription, Event, Payload, Meta),
      Subs
  end;

handle_event(_Conn, _Else, _Data, Subs, _) ->
  Subs.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% Function: get_vhost(Exchange, DefaultVHost) -> VHostToUse
%% Types:
%%  Exchange = binary(),
%%  DefaultVHost = binary(),
%%  VHostToUse = binary 
%% Description: Determine the VHostToUse for specific Exchange using
%% the rules defined in this app's env. If no vhost match the Exchange
%% use the DefaultVHost. Call get_vhost/3 internally.
%%--------------------------------------------------------------------
get_vhost(Exchange, DefaultVHost) ->
  VHostsConfig = get_env(vhosts, []),
  get_vhost(Exchange, VHostsConfig, DefaultVHost).

%%--------------------------------------------------------------------
%% Function: get_vhost(Exchange, VHostConfig, DefaultVHost) -> VHostToUse
%% Types:
%%  Exchange = binary(),
%%  VHostConfig = [Config],
%%  Config = {RegExp, VHostToApply},
%%  RegExp = regex(),
%%  VHostToApply = binary,
%%  DefaultVHost = binary(),
%%  VHostToUse = binary 
%% Description: Recursively performs regular expression checking the
%% VHostConfig for a matching VHost for the Exchange. If not found
%% until empty list, return the DefaultVHost.
%%--------------------------------------------------------------------
get_vhost(_Exchange, [], DefaultVhost) ->
  DefaultVhost;

get_vhost(Exchange, [{RegExp, VHost} | Rest], DefaultVHost) ->
  case re:run(Exchange, RegExp) of
    {match, _} -> VHost;
    nomatch -> get_vhost(Exchange, Rest, DefaultVHost)
  end.

send_system_event(_Conn, _Event, _Payload, none) ->
  ok;

send_system_event(Conn, Event, Payload, VHost) ->
  SystemExchange = get_env(system_exchange, <<"private-broker">>),
  case broker:subscribe(Conn, SystemExchange, VHost) of
    {error, _Error} -> ok;
    {ok, Subscription} ->
      broker:trigger(Subscription, Event, jsx:encode(Payload), []),
      broker:unsubscribe(Subscription)
  end.

%%--------------------------------------------------------------------
%% Function: decode(Data) -> [Event, Exchange, Routing, Payload, Meta]
%% Types:
%%  Data = binary()
%%  Event = binary()
%%  Exchange = binary()
%%  Routing = binary()
%%  Payload = binary()
%%  Meta = binary()
%% Description:  Decode a binary data from the websocket connection
%% into a list of data that the handler expects
%%--------------------------------------------------------------------
decode(Data) ->
  [{<<"event">>, Event}, 
    {<<"exchange">>, Exchange} | Rest] = jsx:decode(Data),

  Routing = bin_key_find(<<"routingKey">>, Rest, <<"#">>),
  Payload = bin_key_find(<<"payload">>, Rest, <<>>),
  Meta = bin_key_find(<<"meta">>, Rest, []),
  [Event, Exchange, Routing, Payload, Meta].

%%--------------------------------------------------------------------
%% Function: bin_key_find(BinKey, List, Default) -> Val || Default
%% Description:  A helper to find a binary key in a binary proplist.
%% If BinKey not found, return the Default.
%%--------------------------------------------------------------------
bin_key_find(BinKey, List, Default) ->
  case lists:keyfind(BinKey, 1, List) of
    {_, Val} when is_integer(Val) -> list_to_binary(integer_to_list(Val));
    {_, Val} -> Val;
    false -> Default
  end.

get_env(Param, DefaultValue) ->
  case application:get_env(broker, Param) of
    {ok, Val} -> Val;
    undefined -> DefaultValue
  end.