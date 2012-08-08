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
-export ([init_state/1]).

%% SocjJS Service callbacks
-export([sockjs_init/2, sockjs_handle/3, sockjs_terminate/2]).

-record (state, {callback, subscriptions, socket_id}).
-record (subscription, {state, vconn, exchange}).

%% ===================================================================
%% Application callbacks
%% This is for each SockJS connection only.
%% ===================================================================

init_state(Callback) ->
    #state{callback=Callback, subscriptions=orddict:new()}.

%% ===================================================================
%% SockJS Service callbacks
%% ===================================================================

sockjs_init(Conn, State) ->
    SocketId = list_to_binary(uuid:to_string(uuid:uuid4())),
    Event = [{<<"event">>,<<"connected">>}, {<<"socket_id">>,SocketId}],
    Conn:send(jsx:encode(Event)),
    {ok, State#state{socket_id=SocketId}}.

sockjs_handle(Conn, Data, State = #state{callback=Callback, 
                                        subscriptions=Subscriptions,
                                        socket_id=SocketId}) ->
    [Event, Exchange, Payload] = decode(Data),

    % Check the event type and whether Conn is subscribed to the Exchange
    case {Event, orddict:is_key(Exchange, Subscriptions)} of
        {<<"client-subscribe">>, false} ->
            VConn = broker_channel:new(Conn, Exchange),
            Subscription = #subscription{vconn = VConn},
            Sub1 = emit({init, SocketId}, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-unsubscribe">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            emit(closed, Callback, Subscription),
            Subs1 = orddict:erase(Exchange, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-bind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Sub1 = emit({bind, Payload, SocketId}, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-unbind-event">>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Sub1 = emit({unbind, Payload, SocketId}, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        {<<"client-",_EventName/binary>>, true} ->
            Subscription = orddict:fetch(Exchange, Subscriptions),
            Sub1 = emit({trigger, Event, Payload, SocketId}, Callback, Subscription),
            Subs1 = orddict:store(Exchange, Sub1, Subscriptions),
            {ok, State#state{subscriptions=Subs1}};

        _Else ->
            %% Ignore
            {ok, State}
    end.

sockjs_terminate(_Conn, #state{ callback=Callback, 
                                subscriptions=Subscriptions}) ->
    _ = [ {emit(closed, Callback, Subscription)} ||
            {_Exchange, Subscription} <- orddict:to_list(Subscriptions) ],
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
    [{<<"event">>, Event}, {<<"channel">>, Exchange} | Rest] = jsx:decode(Data),
    case lists:keyfind(<<"payload">>, 1, Rest) of
        {<<"payload">>, Payload} ->  [Event, Exchange, Payload];
        false -> [Event, Exchange, <<>>]
    end.