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
-export ([init_state/3]).

%% SocjJS Service callbacks
-export([sockjs_init/2, sockjs_handle/3, sockjs_terminate/2]).

-record (state, {broker, func, callback, subscriptions, socket_id, channel}).
-record (subscription, {state, vconn, exchange}).

%% ===================================================================
%% Application callbacks
%% This is for each SockJS connection only.
%% ===================================================================

init_state(Broker, ConnectionFun, Callback) ->
    #state{broker=Broker, 
            func=ConnectionFun,
            callback=Callback, 
            subscriptions=orddict:new()}.

%% ===================================================================
%% SockJS Service callbacks
%% ===================================================================

sockjs_init(Conn, State=#state{broker=Broker, func=Func}) ->
    Channel = Func(Broker),
    SocketId = list_to_binary(uuid:to_string(uuid:uuid4())),
    Event = {<<"event">>, <<"connected">>},
    Payload = {<<"socket_id">>, SocketId},
    Conn:send(jsx:encode([Event, Payload])),
    {ok, State#state{socket_id=SocketId, channel=Channel}}.

sockjs_handle(Conn, Data, State = #state{callback=Callback, 
                                        subscriptions=Subscriptions,
                                        socket_id=SocketId,
                                        channel=Channel}) ->
    [Event, Exchange, Payload] = decode(Data),

    case {Event, orddict:is_key(Exchange, Subscriptions)} of
        {<<"client-subscribe">>, false} ->
            VConn = broker_channel:new(Conn, Exchange),
            Subscription = #subscription{vconn = VConn},
            Sub1 = emit({init, SocketId, Channel}, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-unsubscribe">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            emit(closed, Callback, Subscription),
            Subs1 = orddict:erase(Exchange, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-bind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {bind, Payload, SocketId},
            Sub1 = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-unbind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {unbind, Payload, SocketId},
            Sub1 = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-",_EventName/binary>>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Body = {trigger, Event, Payload, SocketId},
            Sub1 = emit(Body, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        _Else ->
            %% Ignore
            {ok, State}
    end.

sockjs_terminate(_Conn, #state{ callback=Callback, 
                                subscriptions=Subscriptions,
                                channel = Channel}) ->
    [FirstSub | _] = [emit(closed, Callback, Subscription) ||
        {_Exchange, Subscription} <- orddict:to_list(Subscriptions)],

    Callback(FirstSub#subscription.vconn, ended, Channel),
    {ok, #state{callback=Callback, subscriptions=orddict:new()}}.


%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @doc Run the callback for the connection and receive the new state.
%% Function: emit(What, Callback, Subscription) -> NewSubscription
%% Description:  Run the callback for the connection and receive the 
%% new state.
%%--------------------------------------------------------------------
emit(What, Callback, Subscription = #subscription{state = State, 
                                                vconn = VConn}) ->
    case Callback(VConn, What, State) of
        {ok, State1} -> Subscription#subscription{state = State1};
        ok           -> Subscription
    end.

decode(Data) ->
    [{<<"event">>, Event}, 
        {<<"channel">>, Exchange} | Rest] = jsx:decode(Data),
    case lists:keyfind(<<"payload">>, 1, Rest) of
        {<<"payload">>, Payload} ->  [Event, Exchange, Payload];
        false -> [Event, Exchange, <<>>]
    end.