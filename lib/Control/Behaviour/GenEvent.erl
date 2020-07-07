%%---------------------------------------------------------------------------
%% |
%% Module      :  GenEvent
%% Copyright   :  (c) 2020 EMQ Technologies Co., Ltd.
%% License     :  BSD-style (see the LICENSE file)
%%
%% Maintainer  :  Feng Lee, feng@emqx.io
%%                Yang M, yangm@emqx.io
%% Stability   :  experimental
%% Portability :  portable
%%
%% The GenEvent FFI module.
%%
%%---------------------------------------------------------------------------
-module('GenEvent').

-export([ start/3
        , startWith/4
        , startWithGlobal/4
        , startLink/3
        , startLinkWith/4
        , startLinkWithGlobal/4
        , stop/1
        , stopWith/3
        ]).

-export([ addHandler/4
        , notify/2
        , notifyTo/2
        , syncNotify/2
        , syncNotifyTo/2
        ]).

-define(MOD, 'Control.Behaviour.GenEvent.Proxy').

%%---------------------------------------------------------------------------
%% | Start/Stop
%%---------------------------------------------------------------------------

start(Class, Init, Args) ->
  doStart(fun gen_event:start/0, Class, Init, Args).

startWith(Class, Name, Init, Args) ->
  doStartWith(fun gen_event:start/1, {local, Name}, Class, Init, Args).

startWithGlobal(Class, Name, Init, Args) ->
  doStartWith(fun gen_event:start/1, {global, Name}, Class, Init, Args).

startLink(Class, Init, Args) ->
  doStart(fun gen_event:start_link/0, Class, Init, Args).

startLinkWith(Class, Name, Init, Args) ->
  doStartWith(fun gen_event:start_link/1, {local, Name}, Class, Init, Args).

startLinkWithGlobal(Class, Name, Init, Args) ->
  doStartWith(fun gen_event:start_link/1, {global, Name}, Class, Init, Args).

stop(EMgrRef) ->
  gen_event:stop(toErl(EMgrRef)).

stopWith(EMgrRef, Reason, Timeout) ->
  apply(gen_event, stop, [toErl(A) || A <- [EMgrRef, Reason, Timeout]]).

%%---------------------------------------------------------------------------
%% | GenEvent APIs
%%---------------------------------------------------------------------------

addHandler(Class, EMgrRef, Init, Args) ->
  case gen_event:add_handler(EMgrRef, {?MOD, Class}, [Class, Init, Args]) of
    ok -> ok;
    {'EXIT', Reason} -> error(Reason)
  end.

notify(EMgrRef, Event) ->
  gen_event:notify(toErl(EMgrRef), Event).

notifyTo(Pid, Event) ->
  gen_event:notify(Pid, Event).

syncNotify(EMgrRef, Event) ->
  gen_event:sync_notify(toErl(EMgrRef), Event).

syncNotifyTo(Pid, Event) ->
  gen_event:sync_notify(Pid, Event).

%%---------------------------------------------------------------------------
%% | Internal functions
%%---------------------------------------------------------------------------

doStart(Start, Class, Init, Args) ->
  {ok, Pid} = Start(),
  ok = addHandler(Class, Pid, Init, Args),
  {'StartOk', Pid}.

doStartWith(Start, Name, Class, Init, Args) ->
  case Start(Name) of
    {ok, Pid} ->
      ok = addHandler(Class, Pid, Init, Args),
      {'StartOk', Pid};
    {error, Reason} ->
      {'StartError', Reason}
  end.

toErl({'EMgrPid', Pid}) -> Pid;
toErl({'EMgrRef', Name}) -> Name;
toErl({'EMgrRefAt', Name, Node}) -> {Name, Node};
toErl({'EMgrRefGlobal', Name}) -> {global, Name};

toErl({'Infinity'}) -> infinity;
toErl({'Timeout', I}) -> I.
