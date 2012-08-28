%%%-------------------------------------------------------------------
%%% File : subscription_sub.erl
%%% Author : Son Tran <sntran@koding.com>
%%% Description : A supervisor managing subscriptions
%%%
%%% Created : 27 August 2012 by Son Tran <sntran@koding.com>
%%%-------------------------------------------------------------------
-module (subscription_sup).
-behaviour (supervisor).

%% API
-export([start_link/1, start_subscription/3, stop_subscription/1]).

%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================
start_link(Connection) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [Connection]).

start_subscription(Client, Conn, Exchange) ->
    % In the case of SOFO, the second argument of start_child will be
    % appended to the Args of StartFunc.
    {ok, _SubscriptionId} = 
        supervisor:start_child(?MODULE, [Client, Conn, Exchange]).

stop_subscription(SubscriptionId) ->
    ok = supervisor:terminate_child(?MODULE, SubscriptionId).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([Connection]) ->
    RestartStrategy = simple_one_for_one,
    MaxRestart = 5,
    MaxTime = 10,

    StartFunc = {subscription, start_link, [Connection]},
    % Always restart if not terminated normally.
    Restart = transient,
    % For simple_one_for_one, the shutdown wait time is not respected,
    % supervisor will just exit, and each workers terminate on own.
    Shutdown = 1000,
    Type = worker,
    % One-element list of the callback module used by child behavior.
    Modules = [subscription],
    ChildSpecs = {subscription, StartFunc, Restart, Shutdown, Type, Modules},

    {ok, {{RestartStrategy, MaxRestart, MaxTime},[ChildSpecs]}}.