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
-record (subscription, {id}).
-include_lib("amqp_client/include/amqp_client.hrl").

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() ->
    application:start(crypto),
    application:start(public_key),
    application:start(ssl),
    application:start(sockjs),
    application:start(cowboy),

    application:start(broker).

start(_StartType, _StartArgs) ->
    NumberOfAcceptors = 100,
    Port = 8008,

    % This will start the Broker gen_server and the subscription_sup
    broker:start_link(),

    ConnectionFun = fun
        () when guard ->
            ok
    end,

    MultiplexState = sockjs_mq:init_state(ConnectionFun, fun handle_subscription/3),

    %% sockjs_handler:init_state(Prefix, Callback, State, Options)
    %% Callback is a sockjs_service behavior module.
    SockjsState = sockjs_handler:init_state(
                    <<"/subscribe">>, sockjs_mq, MultiplexState, [{disconnect_delay, 10000}]),

    VhostRoutes = [
        {
            [<<"subscribe">>, '...'], 
            sockjs_cowboy_handler, 
            SockjsState
        },
        {
            [<<"static">>, '...'], 
            cowboy_http_static,
            [
                {directory, {priv_dir, broker, [<<"www">>]}},
                {mimetypes, {fun mimetypes:path_to_mimes/2, default}}
            ]
        },
        {'_', ?MODULE, []} % The rest is handled within this module.
    ],
    Routes = [{'_',  VhostRoutes}], % any vhost

    debug_log(" [*] Running at http://localhost:~p~n", [Port]),

    cowboy:start_listener(http, 
        NumberOfAcceptors,
        cowboy_tcp_transport, [{port, Port}],
        cowboy_http_protocol, [{dispatch, Routes}]
    ),

    broker_sup:start_link().

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

        [<<"auth">>] ->
            {Channel, Req3} = cowboy_http_req:qs_val(<<"channel">>, Req1),
            %PrivateChannel = uuid:to_string(uuid:uuid4()),
            PrivateChannel = <<Channel/binary, ".private">>,
            cowboy_http_req:reply(200,
                [{<<"Content-Encoding">>, <<"utf-8">>}], PrivateChannel, Req3);

        [] ->
            {ok, Data} = file:read_file("./apps/broker/priv/www/index.html"),
            cowboy_http_req:reply(200, [{<<"Content-Type">>, "text/html"}],
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

%%--------------------------------------------------------------------
%% Function: handle_subscription(Conn, {init, From}, _State) -> 
%%              {ok, NewState}
%% Description: Set up RabbitMQ connection and channel, then spawn the 
%% receiving loop. This process also declares the Exchange.
%%--------------------------------------------------------------------
handle_subscription(Conn, {init, From, _Channel, Func}, _State) ->
    {topic, Exchange} = lists:last(Conn:info()),

    Subscription = broker:subscribe(Exchange),
    {ok, #subscription{id = Subscription}};

%%--------------------------------------------------------------------
%% Function: handle_subscription(Conn, {bind, Event, _From}, State) -> 
%%              {ok, NewState}
%% Description: When the client binds on certain event, this function
%% declare a queue and bind to an routing key with the same name as
%% the event name. This allows client to only receive messages from
%% that event.
%%--------------------------------------------------------------------
handle_subscription(_Conn, {bind, Event, _From},
                State = #subscription{id=Id}) ->
    broker:bind(Id, Event),
    {ok, State};

%%--------------------------------------------------------------------
%% Function: handle_subscription(Conn, {unbind, Event, _From}, State)
%%              -> {ok, NewState}.
%% Description: When the client unbinds certain event, this function
%% unbinds the associated queue.
%%--------------------------------------------------------------------
handle_subscription(_Conn, {unbind, Event, _From}, 
                    State = #subscription{id=Id}) ->
    broker:unbind(Id, Event),
    {ok, State};

%%--------------------------------------------------------------------
%% Function: handle_subscription(Conn, {trigger, Event, Payload, From}
%%              , State) -> {ok, NewState}.
%% Description: Allows client to trigger certain event in an exchange.
%% The payload of the event will be broadcasted to the exchange under
%% the routing key the same as the event name.
%%--------------------------------------------------------------------
handle_subscription(_Conn, {trigger, Event, Payload, From, Meta},
                    State = #subscription{id=Id}) ->
    broker:trigger(Id, Event, Payload, Meta),
    {ok, State};

%%--------------------------------------------------------------------
%% Function: handle_subscription(_Conn, closed, State) -> {ok, State}.
%% Description: When the client unsubscribes from the exchange, unbind
%% all the bound queues from the exchange.
%%--------------------------------------------------------------------
handle_subscription(_Conn, closed, 
                    #subscription{id=Id}) ->
    broker:unsubscribe(Id),
    {ok, #subscription{}};

%%--------------------------------------------------------------------
%% Function: handle_subscription(_Conn, ended, Channel) -> {ok, State}.
%% Description: When the connection terminates, close the channel.
%%--------------------------------------------------------------------
handle_subscription(_Conn, ended, Channel) ->
    amqp_channel:close(Channel),
    {ok, #subscription{}}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

debug_log(Text, Args) ->
    case application:get_env(broker, verbose) of
        {ok, Val} when Val ->
            io:format(Text, Args);
        _ -> true
    end.