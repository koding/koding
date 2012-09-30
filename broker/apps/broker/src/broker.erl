%%%-------------------------------------------------------------------
%%% File : broker.erl
%%% Author : Son Tran-Nguyen <son@koding.com>
%%% Description : A named gen_server to handle subscribe request from
%%% client. It keeps track of a supervisor to create subscriptions.
%%% It is under the supervision of another supervisor.
%%%
%%% Created : 27 August 2012 by Son Tran <sntran@koding.com>
%%%-------------------------------------------------------------------
-module(broker).
-behaviour(gen_server).
%% API
-export([start_link/0, subscribe/3, presence/4, unsubscribe/1,
      bind/2, unbind/2, trigger/4, trigger/5, rpc/3]).
%% gen_server callbacks
-export([init/1, terminate/2, code_change/3,
    handle_call/3, handle_cast/2, handle_info/2]).
-define (SERVER, ?MODULE).

-include_lib("amqp_client/include/amqp_client.hrl").
-compile([{parse_transform, lager_transform}]).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() -> 
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%--------------------------------------------------------------------
%% Function: subscribe(Exchange) -> Reply
%% Description: Init a subscription for the requesting client.
%%--------------------------------------------------------------------
subscribe(Conn, Exchange, VHost) ->
  gen_server:call(?SERVER, {subscribe, Conn, Exchange, VHost}).

unsubscribe(Subscription) when is_pid(Subscription) ->
  gen_server:call(?SERVER, {unsubscribe, Subscription}).

presence(Conn, Where, Presenter, VHost) ->
  gen_server:call(?SERVER, {presence, Conn, Where, Presenter, VHost}).

%%====================================================================
%% Wrappers for subscription gen_server
%%====================================================================
bind(Subscription, Event) ->
  subscription:bind(Subscription, Event).

unbind(Subscription, Event) ->
  subscription:unbind(Subscription, Event).

trigger(Subscription, Event, Payload, Meta) ->
  trigger(Subscription, Event, Payload, Meta, false).

trigger(Subscription, Event, Payload, Meta, NoRestriction) ->
  subscription:trigger(Subscription, 
            Event, 
            Payload, 
            Meta, 
            NoRestriction).

rpc(Subscription, RoutingKey, Payload) ->
  gen_server:call(Subscription, {rpc, RoutingKey, Payload}).

%%====================================================================
%% gen_server callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%% {ok, State, Timeout} |
%% ignore |
%% {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
  % To know when the supervisor shuts down. In that case, this
  % terminate function will be called to give the gen_server a chance
  % to clean up.
  process_flag(trap_exit, true),
  MqVHost = get_env(mq_vhost, <<"/">>),
  % Doesn't matter getting new connection or not, just return the pool
  {_ConOrError, Connections} = amqp_connection(MqVHost, dict:new()),
  {ok, Connections}.

%%--------------------------------------------------------------------
%% Function: %% handle_call({subscribe, Conn, Exchange}, From, State) 
%%                          -> {reply, Subscription, State} 
%% Description: Handling subscription request. Subscription supervisor
%% will create one under its supervision tree.
%%--------------------------------------------------------------------
handle_call({subscribe, Conn, Exchange, VHost}, From, Connections) ->
  Result = case amqp_connection(VHost, Connections) of
    {error, NewConnections} when NewConnections =:= Connections ->
      {error, precondition_failed};
    {Connection, NewConnections} ->
      subscription_sup:start_subscription(Connection,
                        From, 
                        Conn, 
                        Exchange)
  end,
  {reply, Result, NewConnections};

%%--------------------------------------------------------------------
%% Function: %% handle_call({unsubscribe, Subscription}, From, State) -> 
%%                          {noreply, State} 
%% Description: Handling unsubscription request. This will tell the
%% subscription supervisor to stop the child subscription, but not call
%% its `terminate/2` to do all clean up necessesary.
%%-------------------------------------------------------------------- 
handle_call({unsubscribe, Subscription}, _From, Connections) ->
  ok = subscription_sup:stop_subscription(Subscription),
  {reply, ok, Connections};

%%--------------------------------------------------------------------
%% Function: %% handle_call({presence, Conn, Exchange}, From, State) -> 
%%                          {noreply, State} 
%% Description: Handling presence. It will subscribe to an x-presence
%% exchange, create a binding with an empty key, and another binding
%% with the presenter key to announce the presenter's presence. 
%%--------------------------------------------------------------------
handle_call({presence,Conn,Where,Presenter,VHost},From,Connections) ->
  PresencePrefix = get_env(presence_prefix, <<"KDPresence-">>),
  Exchange = <<PresencePrefix/bitstring, Where/bitstring>>,

  Result = case amqp_connection(VHost, Connections) of
    {error, NewConnections} when NewConnections =:= Connections ->
      {error, precondition_failed};
    {Connection, NewConnections} ->
      subscription_sup:start_subscription(Connection,
                        From, 
                        Conn, 
                        Exchange)
  end,

  case Result of
    {ok, SID} ->
      subscription:bind(SID, <<>>),
      subscription:bind(SID, Presenter),
      {reply, Result, NewConnections};
    {error, _Err} ->
      {reply, Result, NewConnections}
  end;

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%% {reply, Reply, State, Timeout} |
%% {noreply, State} |
%% {noreply, State, Timeout} |
%% {stop, Reason, Reply, State} |
%% {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
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
handle_info(_Info, State) ->
  {noreply, State}.
  
%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, Connections) ->
  Closer = fun (VHost) -> 
    Connection = dict:fetch(VHost, Connections),
    amqp_connection:close(Connection)
  end,
  [Closer(VHost) || VHost <- dict:fetch_keys(Connections)],
  lager:info("Broker server dies, closing connections"),
  ok.

%%--------------------------------------------------------------------
%% Function: amqp_connection(VHost, Connections) -> 
%%                                {Connection, NewConnections} |
%%                                {error, Connections}
%% Description: Establishes a connection pool based on VHost.
%%--------------------------------------------------------------------
amqp_connection(VHost, Connections) ->
  case dict:find(VHost, Connections) of
    {ok, Connection} -> {Connection, Connections};
    error ->
      MqHost = get_env(mq_host, "localhost"),
      MqUser = get_env(mq_user, <<"guest">>),
      MqPass = get_env(mq_pass, <<"guest">>),
      case amqp_connection:start(#amqp_params_network{
        host = MqHost, username = MqUser, password = MqPass,
        virtual_host = VHost}) of
        {ok, Connection} ->
          {Connection, dict:store(VHost, Connection, Connections)};
        {error, Error} ->
          lager:error("Failed to establish connection to vhost ~p with reason ~p",
                                                  [VHost, Error]),
          {error, Connections}
      end
  end.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
get_env(Param, DefaultValue) ->
  case application:get_env(broker, Param) of
    {ok, Val} -> Val;
    undefined -> DefaultValue
  end.