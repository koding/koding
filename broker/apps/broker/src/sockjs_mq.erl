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
-module (sockjs_mq).

-behaviour (sockjs_service).

%% Application callbacks
-export ([init_state/2]).

%% SocjJS Service callbacks
-export([sockjs_init/2, sockjs_handle/3, sockjs_terminate/2]).

-record (state, {   connection_fun, callback, subscriptions, 
                    socket_id, channel}).
-record (subscription, {state, vconn, exchange}).

%% ===================================================================
%% Application callbacks
%% This is for each SockJS connection only.
%% ===================================================================

init_state(ConnectionFun, Callback) ->
    #state{ connection_fun=ConnectionFun,
            callback=Callback, 
            subscriptions=orddict:new()}.

%% ===================================================================
%% SockJS Service callbacks
%% ===================================================================

sockjs_init(Conn, State=#state{connection_fun=Func}) ->
    Channel = Func(),
    SocketId = list_to_binary(uuid:to_string(uuid:uuid4())),
    Event = {<<"event">>, <<"connected">>},
    Payload = {<<"socket_id">>, SocketId},
    Conn:send(jsx:encode([Event, Payload])),
    {ok, State#state{socket_id=SocketId, channel=Channel}}.

sockjs_handle(Conn, Data, State = #state{callback=Callback, 
                                        subscriptions=Subscriptions,
                                        socket_id=SocketId,
                                        channel=Channel,
                                        connection_fun=Func}) ->
    [Event, Exchange, Payload, Meta] = decode(Data),

    case {Event, orddict:is_key(Exchange, Subscriptions)} of
        {<<"client-subscribe">>, false} ->
            VConn = broker_channel:new(Conn, Exchange),
            Subscription = #subscription{vconn = VConn},
            What = {init, SocketId, Channel, Func},
            {Status, Sub1} = emit(What, Callback, Subscription),
            case Status of
                ok ->
                    Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
                    {ok, State#state{subscriptions=Subs1}};
                error ->
                    {ok, State}
            end;

        {<<"client-unsubscribe">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            emit(closed, Callback, Subscription),
            Subs1 = orddict:erase(Exchange, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-bind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {bind, Payload, SocketId},
            {ok, Sub1} = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-unbind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {unbind, Payload, SocketId},
            {ok, Sub1} = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-",_EventName/binary>>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {trigger, Event, Payload, SocketId, Meta},
            {ok, Sub1} = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        _Else ->
            %% Ignore
            {ok, State}
    end.

sockjs_terminate(_Conn, #state{ callback=Callback, 
                                subscriptions=Subscriptions,
                                channel = Channel}) ->
    case orddict:size(Subscriptions) of 
        0 -> Callback(none, ended, Channel);
        _ ->
            List = orddict:to_list(Subscriptions),
            [{_, Sub} | _] = [emit(closed, Callback, Subscription) ||
                {_Exchange, Subscription} <- List],
            Callback(Sub#subscription.vconn, ended, Channel)
    end,
    
    {ok, #state{callback=Callback, subscriptions=orddict:new()}}.


%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @doc Run the callback for the connection and receive the new state.
%% Function: emit(What, Callback, Subscription) -> 
%%                          {ok, NewSubscription} ||
%%                          {error, NewSubscription}
%% Types:
%%  What = {Type, ...}
%%  Type = atom()
%%  Callback = fun()
%%  Subscription = record#subscription
%%  NewSubscription = record#subscription
%% Description:  Run the callback for the connection and receive the 
%% new state.
%%--------------------------------------------------------------------
emit(What, Callback, Subscription = #subscription{state = State, 
                                                vconn = VConn}) ->
    case Callback(VConn, What, State) of
        {Status, State1} -> 
            {Status, Subscription#subscription{state = State1}};
        ok           -> {ok, Subscription}
    end.

%%--------------------------------------------------------------------
%% Function: decode(Data) -> [Event, Exchange, Payload, Meta]
%% Types:
%%  Data = binary()
%%  Event = binary()
%%  Exchange = binary()
%%  Payload = binary()
%%  Meta = binary()
%% Description:  Decode a binary data from the websocket connection
%% into a list of data that the handler expects
%%--------------------------------------------------------------------
decode(Data) ->
    [{<<"event">>, Event}, 
        {<<"channel">>, Exchange} | Rest] = jsx:decode(Data),

    Payload = bin_key_find(<<"payload">>, Rest),
    Meta = bin_key_find(<<"meta">>, Rest),
    [Event, Exchange, Payload, Meta].

%%--------------------------------------------------------------------
%% Function: bin_key_find(BinKey, List) -> Val || false
%% Description:  A helper to find a binary key in a binary proplist.
%%--------------------------------------------------------------------
bin_key_find(BinKey, List) ->
    case lists:keyfind(BinKey, 1, List) of
        {BinKey, Val} -> Val;
        false -> <<>>
    end.