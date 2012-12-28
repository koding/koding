%%%-------------------------------------------------------------------
%%% File : subscription.erl
%%% Author : Son Tran <sntran@koding.com>
%%% Description : A gen_server to handle request within an exchange of
%%% a specific client.
%%%
%%% Created : 27 August 2012 by Son Tran <sntran@koding.com>
%%%-------------------------------------------------------------------
-module(subscription).
-behaviour(gen_server).
%% API
-export([start_link/4,
    bind/2, unbind/2, trigger/5, rpc/3,
    notify_first/3]).
%% gen_server callbacks
-export([init/1, terminate/2, code_change/3,
    handle_call/3, handle_cast/2, handle_info/2]).

-record(state, {connection, channel, 
    exchange, client, broadcastable,
    bindings = dict:new(), sender}).

-define (SERVER, ?MODULE).
-define (MESSAGE_TTL, 5000).
-include_lib("amqp_client/include/amqp_client.hrl").
-compile([{parse_transform, lager_transform}]).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link(Connection, Client, Conn, Exchange) -> 
%%                          {ok,Pid} | ignore | {error,Error}
%% Types: 
%%  Connection = pid(),
%%  Client = pid(),
%%  Conn = sockjs_connection(),
%%  Exchange = binary().
%%
%% Description: Starts the subscription server.
%%  Connection is the broker connection to MQ.
%%  Client is the PID of the client whose request was made.
%%  Conn is the sockjs_connection used to send message.
%%  Exchange is the name of the exchange to connect to.
%%--------------------------------------------------------------------
start_link(Connection, Client, Conn, Exchange) ->
  gen_server:start_link(?MODULE, [Connection, Client, Conn, Exchange], []).

bind(Subscription, Event) ->
  gen_server:call(Subscription, {bind, Event}).

unbind(Subscription, Event) ->
  gen_server:call(Subscription, {unbind, Event}).

trigger(Subscription, Event, Payload, Meta, NoRestriction) ->
  CallData = {trigger, Event, Payload, Meta, NoRestriction},
  gen_server:call(Subscription, CallData).

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
%% Description: Initiates the server, arguments are passed by third arg
%% in gen_server:start_link call
%%--------------------------------------------------------------------
init([Connection, Client, Conn, Exchange]) ->
  % To know when the supervisor shuts down. In that case, this
  % terminate function will be called to give the gen_server a chance
  % to clean up.
  process_flag(trap_exit, true),

  SendFun = fun (Data) -> send(Conn, Exchange, Data) end,

  {ok, Channel} = channel(Connection),
  Broadcastable = broadcastable(Exchange),

  spawn(?MODULE, notify_first, [SendFun, channel(Connection), Exchange]),

  State = #state{ connection = Connection,
          channel = Channel,
          exchange = Exchange,
          broadcastable = Broadcastable,
          client = Client,
          sender = SendFun},

  Type = get_exchange_type(Exchange),

  {Durable, AutoDelete} = case Exchange of
    <<"updateInstances">> -> {true, false};
    _ -> {true, true}
  end,

  try subscribe(SendFun,Channel,Exchange,Type,Durable,AutoDelete) of
    ok -> {ok, State}
  catch
    error:precondition_failed ->
      ErrMsg = get_env(precondition_failed, <<"Unknow error">>),
      SendFun([<<"broker:subscription_error">>, ErrMsg]),
      {stop, precondition_failed}
  end.
  

%%--------------------------------------------------------------------
%% Function: %% handle_call({bind, Event}, From, State) 
%%                      -> {noreply, State}.
%% Types:
%%  Event = binary(),
%%  From = pid(),
%%  State = #state{}
%% Description: Handling key binding to the exchange.
%%--------------------------------------------------------------------
handle_call({bind, Event}, _From, State=#state{channel=Channel,
                        exchange=Exchange,
                        bindings=Bindings}) ->
  % Ensure one queue per key per exchange
  case dict:find(Event, Bindings) of
    {ok, _Queue} -> {reply, ok, State};
    error ->
      {Queue, CTag} = bind_queue(Channel, Exchange, Event),
      NewBindings = dict:store(Event, {Queue,CTag}, Bindings),
      {reply, ok, State#state{bindings = NewBindings}}
  end;

%%--------------------------------------------------------------------
%% Function: %% handle_call({unbind, Event}, From, State) 
%%                      -> {noreply, State}.
%% Types:
%%  Event = binary(),
%%  From = pid(),
%%  State = #state{}
%% Description: Handling key unbinding from the exchange.
%%--------------------------------------------------------------------
handle_call({unbind, Event}, _From, State=#state{channel=Channel,
                        exchange=Exchange,
                        bindings=Bindings}) ->
  case dict:find(Event, Bindings) of 
    {ok, {Queue, CTag}} ->
      unbind_queue(Channel, Exchange, Event, Queue, CTag),
      % Remove from the dictionary
      NewBindings = dict:erase(Event, Bindings),
      {reply, ok, State#state{bindings = NewBindings}};
    error ->
      {reply, ok, State}
  end;

%%--------------------------------------------------------------------
%% Function: %% handle_call({trigger, Event, Payload}, From, State) 
%%                      -> {noreply, State}.
%% Types:
%%  Event = binary(),
%%  Payload = bitstring(),
%%  Meta = [Props],
%%  NoRestriction = boolean(),
%%  Props = {<<"replyTo">>, ReplyTo} || TBA
%%  ReplyTo = binary(),
%%  From = pid(),
%%  State = #state{}
%% Description: Handling key unbinding from the exchange.
%%--------------------------------------------------------------------
handle_call({trigger, Event, Payload, Meta, NoRestriction}, From, 
      State=#state{channel=Channel,
            exchange=Exchange,
            broadcastable=Broadcastable}) ->

  case {NoRestriction, Broadcastable} of 
    {false, false} -> {reply, ok, State};
    {_, _} ->  
      broadcast(From, Channel, Exchange, Event, Payload, Meta),
      {reply, ok, State}
  end;

%%--------------------------------------------------------------------
%% Function: %% handle_call({rpc, RoutingKey, Payload}, From, State) 
%%                      -> {noreply, State}.
%% Types:
%%  Exchange = pid(),
%%  From = pid(),
%%  State = #state{}
%% Description: Handling new subscription.
%%--------------------------------------------------------------------
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
%% Function: handle_info(#'basic.consume_ok'{}, State) -> 
%%                                          {noreply, State}
%% Description: Acknowledge the subscription from MQ.
%%--------------------------------------------------------------------
handle_info(#'basic.consume_ok'{}, State) ->
  {noreply, State};

%%--------------------------------------------------------------------
%% Function: handle_info({Deliver, Msg}, State) -> 
%%                                          {noreply, State}.
%% Types:
%%  Deliver = #'basic.deliver'{exchange = Exchange},
%%  Exchange = <<"KDPresence">>,
%%  Msg = #amqp_msg{props = Props},
%%  Props = #'P_basic'{headers = Headers}.
%%  Headers = [Prop],
%%  Prop =  {<<"action">>, longstr, Status} |
%%          {<<"exchange">>, longstr, Exchange} |
%%          {<<"queue">>, longstr, Queue} |
%%          {<<"key">>, longstr, Presence},
%%  Status = "bind" | "unbind"
%%  Exchange = binary()
%%  Queue = binary()
%%  Presence = binary()
%% Description: Presence announcement. This makes an assumption that
%% there is a proplist of headers and empty body (how presence type
%% defines it.)
%%--------------------------------------------------------------------
handle_info({#'basic.deliver'{exchange = Exchange},
      #amqp_msg{props=#'P_basic'{headers = [
        {<<"action">>, longstr, Status}, % "bind" || "unbind"
        {<<"exchange">>, longstr, Exchange}, % same as this excchange
        {<<"queue">>, longstr, _QName}, % name of queue
        {<<"key">>, longstr, Presence}
      ]}, payload = <<>>}}, State=#state{sender=Sender}) ->

  Sender([<<"broker:presence">>, [Presence, Status]]),
  {noreply, State};

%%--------------------------------------------------------------------
%% Function: handle_info({Deliver, Msg}, State) -> 
%%                                          {noreply, State}.
%% Types:
%%  Deliver = #'basic.deliver'{routing_key = Key, exchange = Exchange},
%%  Key = binary(),
%%  Exchange = binary(),
%%  Msg = #amqp_msg{payload = Payload},
%%  Payload = bitstring(),
%% Description: Echo to the client receiving message from bound events.
%%--------------------------------------------------------------------
handle_info({#'basic.deliver'{routing_key = Event, exchange = _Exchange}, 
      #amqp_msg{props = #'P_basic'{correlation_id = CorId},
        payload = Payload}}, State=#state{sender=Sender}) ->
  Self = term_to_binary(self()),
  case CorId of 
    Self -> 
      {noreply, State};
    _ -> 
      Sender([Event, Payload]),
      {noreply, State}
  end;

% handle_info(#'basic.cancel'{}, State) ->
%     {noreply, State};

%%--------------------------------------------------------------------
%% Function: handle_info(#'basic.cancel_ok'{}, State) -> 
%%                                          {noreply, State}.
%% Description: Ignores confirmation when cancelling subscription.
%%--------------------------------------------------------------------
handle_info(#'basic.cancel_ok'{}, State) ->
  {noreply, State};

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%% {noreply, State, Timeout} |
%% {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(Info, State) ->
  io:format("Receive other message: ~p~n", [Info]),
  {noreply, State}.
  
%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Types:
%%  Reason = shutdown | normal
%% Description: This function is called by a gen_server when it is about
%% to terminate ('normal' reason) or when the parent terminates it with
%% 'shutdown' reason. Either reason, we unbind all queues and close
%% the channel.
%%--------------------------------------------------------------------
terminate(_Reason, #state{channel = Channel,
              exchange = Exchange,
              bindings = Bindings}) ->
  [unbind_queue(Channel, Exchange, Binding, Queue, CTag) || 
    {Binding, {Queue, CTag}} <- dict:to_list(Bindings)],
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

channel(Connection) ->
  {ok, Channel} = amqp_connection:open_channel(Connection),
  amqp_selective_consumer:register_default_consumer(Channel, self()),
  {ok, Channel}.

%%--------------------------------------------------------------------
%% Func: broadcastable(Exchange) -> boolean()
%% Description: Detect whether the exchange is private.
%%--------------------------------------------------------------------
broadcastable(Exchange) ->
  %RegExp = "^priv[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
  %Options = [{capture, [1], list}],
  SystemExchange = get_env(system_exchange, <<"private-broker">>),
  System = Exchange =:= SystemExchange,
  Private = re:run(Exchange, get_env(privateRegEx, ".private$")),
  case {System, Private} of
    {false, nomatch} -> false;
    {_, _} -> true % either system or not system but private.
  end.

%%--------------------------------------------------------------------
%% Func: get_exchange_type(Exchange) -> binary()
%% Description: Determines exchange type based on certain rules.
%%--------------------------------------------------------------------
get_exchange_type(Exchange) ->
  Prefix = get_env(presence_prefix, <<"KDPresence-">>),
  Size = bit_size(Prefix),
  case Exchange of 
     <<Prefix:Size/bitstring, _/bitstring>> -> <<"x-presence">>;
    _ -> <<"topic">>
  end.

%%--------------------------------------------------------------------
%% Function: notify_first(Sender, Channel, Exchange) -> void()
%% Description: Perform a check for existence against an exchange and 
%% notify the Conn if the exchange does not exist.
%% This is a one-off function to be run in a separate process and exit
%% normally to avoid blocking the current process.
%%--------------------------------------------------------------------
notify_first(Sender, Channel, Exchange) ->
  Check = #'exchange.declare'{ exchange = Exchange,
                  passive = true},
  try amqp_channel:call(Channel, Check) of
    #'exchange.declare_ok'{} -> exit(normal)
  catch exit:_Ex1 -> 
      Sender([<<"broker:first_connection">>, Exchange]),
      exit(normal)
  end.

%%--------------------------------------------------------------------
%% Function: subscribe(Conn, Channel, Queue) -> void()
%% Description: Declares a durable and auto-delete exchange of type
%% "topic". Calls subscribe/6 internally.
%%--------------------------------------------------------------------
subscribe(Sender, Channel, Exchange) ->
  subscribe(Sender, Channel, Exchange, <<"topic">>).

subscribe(Sender, Channel, Exchange, Type) ->
  subscribe(Sender, Channel, Exchange, Type, true, true).

%%--------------------------------------------------------------------
%% Function: subscribe(Conn, Channel, Queue) -> void()
%% Description: More configurable exchange declaration. 
%%--------------------------------------------------------------------
subscribe(Sender, Channel, Exchange, Type, Durable, AutoDelete) -> 
  Declare = #'exchange.declare'{  exchange = Exchange, 
                  type = Type,
                  durable = Durable,
                  auto_delete = AutoDelete},

  try amqp_channel:call(Channel, Declare) of
    #'exchange.declare_ok'{} -> 
      Sender([<<"broker:bind_succeeded">>, <<>>]),
      ok
  catch
    exit:Error ->
      handle_amqp_error(Error)
  end.

%%--------------------------------------------------------------------
%% Function: bind_queue(Channel, Exchange, Routing) -> pid()
%% Description: Declares a queue and bind to the routing key. Also
%% starts the subscription on that queue.
%%--------------------------------------------------------------------
bind_queue(Channel, Exchange, Routing) ->
  % Ensure the client has time to consume the message
  % Args = [{<<"x-message-ttl">>, long, ?MESSAGE_TTL}],
  #'queue.declare_ok'{queue = Queue} =
    amqp_channel:call(Channel, #'queue.declare'{exclusive = true,
                          durable = true}),

  Binding = #'queue.bind'{exchange = Exchange,
              routing_key = Routing,
              queue = Queue},
  #'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),
  Sub = #'basic.consume'{queue = Queue, no_ack = true},
  #'basic.consume_ok'{consumer_tag = CTag} = 
    amqp_channel:subscribe(Channel, Sub, self()),
  {Queue, CTag}.

%%--------------------------------------------------------------------
%% Function: unbind_queue(Channel, Exchange, Routing, Queue) -> pid()
%% Description: Unbinds the queue from the routing key in the exchange
%% and deletes it.
%%--------------------------------------------------------------------
unbind_queue(Channel, Exchange, Routing, Queue, CTag) ->
  % Unbind the queue from the routing key
  Binding = #'queue.unbind'{  exchange    = Exchange,
                routing_key = Routing,
                queue       = Queue},
  #'queue.unbind_ok'{} = amqp_channel:call(Channel, Binding),
  % Cancel the consumer
  amqp_channel:call(Channel, #'basic.cancel'{consumer_tag = CTag}),
  % Delete the queue
  Delete = #'queue.delete'{queue = Queue},
  #'queue.delete_ok'{} = amqp_channel:call(Channel, Delete).

%%--------------------------------------------------------------------
%% Function: broadcast(From, Channel, Exchange, Event, Data, Meta) -> void()
%% Description: Set up the correlation id, then publish the Data to 
%% the Exchange on the routing key the same as the Event.
%%--------------------------------------------------------------------
broadcast(From, Channel, Exchange, Event, Data, Meta) ->
  Publish = #'basic.publish'{ exchange = Exchange, 
                routing_key = Event},
  CorId = term_to_binary(self()),

  case lists:keyfind(<<"replyTo">>, 1, Meta) of 
    {_, ReplyTo} -> 
      Props = #'P_basic'{correlation_id = CorId,
                reply_to = ReplyTo},
      Msg = #amqp_msg{props = Props, payload = Data},
      amqp_channel:cast(Channel, Publish, Msg);
    false ->        
      Props = #'P_basic'{correlation_id = CorId},
      Msg = #amqp_msg{props = Props, payload = Data},
      amqp_channel:cast(Channel, Publish, Msg)
  end.

send(Conn, Exchange, [Key, Payload]) ->
  Event = {<<"event">>, Key},
  Channel = {<<"exchange">>, Exchange},
  Data = {<<"payload">>, Payload},
  Conn:send(jsx:encode([Event, Channel, Data])).

handle_amqp_error({{shutdown, {_Reason, 406, _Msg}}, _Who}) ->
  error(precondition_failed).

get_env(Param, DefaultValue) ->
  case application:get_env(broker, Param) of
    {ok, Val} -> Val;
    undefined -> DefaultValue
  end.