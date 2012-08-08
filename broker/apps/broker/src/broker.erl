%%%-------------------------------------------------------------------
%%% File : broker.erl
%%% Author : Son Tran <sntran@koding.com>
%%% Description : Message broker interface to manage RabbitMQ exchanges
%%% and SockJS connections. It organizes connections into exchanges.
%%%
%%% Created : 2 Mar 2007 by Son Tran <sntran@koding.com>
%%%-------------------------------------------------------------------
-module(broker).
-behaviour(gen_server).
%% API
-export([start/3, subscribe/2, broadcast/3]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {channel, subscriber, conn}).
-define (SERVER, ?MODULE).
-include_lib("amqp_client/include/amqp_client.hrl").

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start(Connection, Conn, Subscriber) ->
    {ok, Pid} = gen_server:start(?MODULE, 
                            [Connection, Conn, Subscriber], []),
    Pid.

subscribe(Broker, Exchange) ->
    %gen_server:call(?SERVER, {subscribe, Exchange}).
    gen_server:call(Broker, {subscribe, Exchange}, infinity).

broadcast(Broker, Exchange, Data) ->
    gen_server:call(Broker, {broadcast, Exchange, Data}).

rpc(Broker, RoutingKey, Payload) ->
    gen_server:call(Broker, {rpc, RoutingKey, Payload}).


%%====================================================================
%% gen_server callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%% {ok, State, Timeout} |
%% ignore |
%% {stop, Reason}
%% Description: Initiates the server, arguments are passed by third arg
%% in gen_server:start_link call
%%--------------------------------------------------------------------
init([Connection, Conn, Subscriber]) ->
    {ok, Channel} = amqp_connection:open_channel(Connection),
    {ok, #state{channel=Channel, conn=Conn, subscriber=Subscriber}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%% {reply, Reply, State, Timeout} |
%% {noreply, State} |
%% {noreply, State, Timeout} |
%% {stop, Reason, Reply, State} |
%% {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({subscribe, Exchange}, From, State = #state{channel = Channel}) ->
    amqp_channel:call(Channel,  #'exchange.declare'{exchange = Exchange,
                                                   type = <<"topic">>}),
    #'queue.declare_ok'{queue = Queue} =
        amqp_channel:call(Channel, #'queue.declare'{exclusive = true}),

    amqp_channel:call(Channel, #'queue.bind'{exchange = Exchange,
                                    routing_key = <<"#">>,
                                     queue = Queue}),

    amqp_channel:subscribe(Channel, #'basic.consume'{queue = Queue,
                                                     no_ack = true}, self()),

    {noreply, State};

handle_call({broadcast, Exchange, Data}, _From, 
            State = #state{channel = Channel, subscriber = Subscriber}) ->
    io:format("broadcasting~n"),
    Props = #'P_basic'{correlation_id = Subscriber},
    amqp_channel:cast(Channel,
                      #'basic.publish'{exchange = Exchange, routing_key = <<"#">>},
                      #amqp_msg{props = Props, payload = list_to_binary(Data)}),
    {noreply, State};

handle_call({rpc, RoutingKey, Payload}, _From, State) ->
    RpcClient = amqp_rpc_client:start(self(), RoutingKey),
    io:format("RpcClient ~p~n", [RpcClient]),
    amqp_rpc_client:call(RpcClient, list_to_binary(Payload)),
    {noreply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.
    
%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%% {noreply, State, Timeout} |
%% {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.
    
%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%% {noreply, State, Timeout} |
%% {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(#'basic.consume_ok'{}, State) -> 
    io:format("Start subscribing~n"),
    {noreply, State};

handle_info({#'basic.deliver'{routing_key = Key},
            #amqp_msg{props = #'P_basic'{correlation_id = Subscriber},
                        payload = Payload}},
            State = #state{subscriber = Subscriber}) ->
    io:format("Receiving own message~n"),
    {noreply, State};

handle_info({#'basic.deliver'{}, #amqp_msg{payload = Payload}},
            State = #state{conn = Conn}) ->
    io:format("Receiving other's message~n"),
    Conn:send(Payload),
    {noreply, State}.
    
%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, #state{channel = Channel}) ->
    amqp_channel:close(Channel),
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
