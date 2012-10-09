% MIT License
% ===========

% Copyright (c) 2012 Son Tran <esente@gmail.com>

% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense,
% and/or sell copies of the Software, and to permit persons to whom the
% Software is furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.
-module(broker_sup).

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
    RestartStrategy = one_for_all,
    MaxR = 5, 
    MaxT = 10,
    {ok, { {RestartStrategy, MaxR, MaxT}, 
        [broker_spec(), subscription_sup_spec()]} }.

broker_spec() ->
    StartFunc = {broker, start_link, []},
    Restart = transient,
    Shutdown = 5000,
    Type = worker,
    Modules = [broker],
    {broker, StartFunc, Restart, Shutdown, Type, Modules}.

subscription_sup_spec() ->
    StartFunc = {subscription_sup, start_link, []},
    Restart = transient,
    Shutdown = infinity,
    Type = supervisor,
    Modules = [subscription_sup],
    {subscription_sup, StartFunc, Restart, Shutdown, Type, Modules}.