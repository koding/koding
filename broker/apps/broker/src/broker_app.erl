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
-export([start/0, start/2, stop/1, subscribe/4]).

%% Cowboy callbacks
-export([init/3, handle/2, terminate/2]).
-record (user_info, {name, broker, channel, exchange}).
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

    MultiplexState = sockjs_mq:init_state(fun handle_subscription/3),

    %% sockjs_handler:init_state(Prefix, Callback, State, Options)
    %% Callback is a sockjs_service behavior module.
    SockjsState = sockjs_handler:init_state(
                    <<"/subscribe">>, sockjs_mq, MultiplexState, []),

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

    io:format(" [*] Running at http://localhost:~p~n", [Port]),

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
            PrivateChannel = uuid:to_string(uuid:uuid4()),
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

%% This callback is called for a combination of a Queue in an Exchange
%% on a Channel.
handle_subscription(Conn, {init, From}, _State) ->
    {ok, Broker} =
        amqp_connection:start(#amqp_params_network{host = "localhost"}),

    {topic, Exchange} = lists:last(Conn:info()),

    {ok, Channel} = amqp_connection:open_channel(Broker),
    spawn(?MODULE, subscribe, [Conn, Channel, Exchange, From]),
    {ok, #user_info{broker=Broker, channel=Channel, exchange=Exchange}};
    % B = broker:start(Broker, Conn, term_to_binary(self())),
    % broker:subscribe(B, Exchange),
    % {ok, #user_info{broker=B}};
    
handle_subscription(_Conn, {recv, Payload, From}, State) ->
    #user_info{channel=Channel, exchange=Exchange, broker=Broker} = State,

    broadcast(From, Channel, Exchange, Payload),
    {ok, State};

handle_subscription(_Conn, closed, State) ->
    {ok, State}.

broadcast(From, Channel, Exchange, Data) ->
    Props = #'P_basic'{correlation_id = From},
    amqp_channel:cast(Channel,
                      #'basic.publish'{exchange = Exchange, routing_key = <<"#">>},
                      #amqp_msg{props = Props, payload = Data}).

%%--------------------------------------------------------------------
%% Function: subscribe(Conn, Channel, Queue, Subscriber) -> void()
%% Subscriber -> pid() the id of the connection to subscribe.
%% Description: Exported but internal function to be spawned to handle
%% the receive loop for data from subscribed exchange of RabbitMQ.
%%--------------------------------------------------------------------
subscribe(Conn, Channel, Exchange, Subscriber) -> 
    amqp_channel:call(Channel, #'exchange.declare'{exchange = Exchange,
                                                   type = <<"topic">>}),   
    #'queue.declare_ok'{queue = Queue} =
        amqp_channel:call(Channel, #'queue.declare'{exclusive = true}),
    amqp_channel:call(Channel, #'queue.bind'{exchange = Exchange,
                                    routing_key = <<"#">>,
                                     queue = Queue}),
    amqp_channel:subscribe(Channel, #'basic.consume'{queue = Queue,
                                                     no_ack = true}, self()),
    loop(Conn, Subscriber).

rpc_call(Broker, RoutingKey, Payload) ->
    %Fun = fun(X) -> X + 1 end,
    %RPCHandler = fun(X) -> term_to_binary(Fun(binary_to_term(X))) end,
    %Server = amqp_rpc_server:start(Broker, <<"RoutingKey">>, RPCHandler),
    RpcClient = amqp_rpc_client:start(Broker, RoutingKey),
    io:format("RpcClient ~p~n", [RpcClient]),
    Reply = amqp_rpc_client:call(RpcClient, list_to_binary(Payload)).
    %Reply = amqp_rpc_client:call(RpcClient, term_to_binary(1)),
    %io:format("Reply ~p~n", [binary_to_term(Reply)]).

%%--------------------------------------------------------------------
%% Function: loop(Conn) -> void()
%% Description: The receive loop to send broadcast message to client.
%%--------------------------------------------------------------------
loop(Conn, Subscriber) ->
    receive
        #'basic.consume_ok'{} ->
            loop(Conn, Subscriber);
        {#'basic.deliver'{routing_key = Key}, #amqp_msg{props = #'P_basic'{correlation_id = Subscriber}, payload = Body}} ->
            %Conn:send(Body),
            loop(Conn, Subscriber);
        {#'basic.deliver'{exchange = Exchange}, #amqp_msg{payload = Body}} ->
            io:format(" [x] ~p:~p~n", [Exchange, Body]),
            Conn:send(<<"client-message">>, Body),
            loop(Conn, Subscriber)
    end.