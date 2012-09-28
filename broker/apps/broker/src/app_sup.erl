-module(app_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->

    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
	RestartStrategy = one_for_one,
	MaxR = 5,
	MaxT = 10,

    {ok, { {RestartStrategy, MaxR, MaxT}, [broker_sup_spec()]} }.

broker_sup_spec() ->
	StartFunc = {broker_sup, start_link, []},
	Restart = transient,
	Shutdown = 5000,
	Type = supervisor,
	Modules = [broker_sup],
	{broker_sup, StartFunc, Restart, Shutdown, Type, Modules}.

start_client(Params) ->
    supervisor:start_child(?MODULE, [Params]).