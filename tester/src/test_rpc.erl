
-module(test_rpc).
-compile([export_all]).

-include("tester.hrl").
-include("common.hrl").

%% -----------------------------------------------------------------------------
%% @doc 客户端请求服务器数据
%% -----------------------------------------------------------------------------

%% 创建角色
handle(create, Param, State) ->
    ?INFO("test_rpc:handle request_create"),
    tester:send(1001, Param, State#tester.socket),
    {ok, State};

%% 登陆游戏
handle(login, _Param, State = #tester{id = RoleID
        , platform_id = PlatformID, zone_id = ZoneID}) ->
    ?INFO("test_rpc:handle request_login"),
    tester:send(1003, {RoleID, 2, <<"1">>, <<"2">>}, State#tester.socket),
    {ok, State};

%% 登陆成功请求玩家数据
handle(role_data, Param, State) ->
    ?INFO("test_rpc:handle request_role_data[~p]",[Param]),
    tester:send(1031, Param, State#tester.socket),
    {ok, State};

%% 进入场景
handle(enter_map, Param, State) ->
    ?INFO("test_rpc:handle request_enter_map"),
    tester:send(1030, Param, State#tester.socket),
    {ok, State};

%% 请求移动
handle(move, Param = {X, Y, _Dir}, State) ->
    ?INFO("[test_rpc:handle request_move_succ][x:~p y:~p]",[X, Y]),
    tester:send(1032, Param, State#tester.socket),
    {ok, State};

%% -----------------------------------------------------------------------------
%% @doc 服务器数据返回处理
%% -----------------------------------------------------------------------------

%% 创建成功的返回
handle(1051, Param, State) ->
    RoleID = erlang:element(2, Param),
    ?INFO("[create_role Succ][role_id:~p]",[RoleID]),
    NewState = State#tester{id = RoleID, platform_id = 1, zone_id = 1},
    % ets:insert(role, NewState),
    tester:cmd(login, test_rpc, {}, NewState),
    {ok, NewState};

%% 登陆游戏的成功返回
handle(1120, {Result}, State) ->
    case Result of
        1 ->
            ?INFO("test_rpc:handle Login_Succ"),
            tester:cmd(role_data, test_rpc, {1}, State); %% 请求角色基本信息
        _ ->
            ?INFO("[test_rpc:handle login_error]")
    end,
    {ok, State};

%% 请求玩家数据的返回
handle(1031, _Param, State) ->
    %% 通知服务器进入场景
    ?INFO("test_rpc:handle role_data_succ"),
    tester:cmd(enter_map, test_rpc, {0,0,0}, State),
    {ok, State};
%% 进入场景成功返回
handle(1020, _Param, State) ->
    %% 请求玩家面板信息及各模块信息
    ?INFO("[test_rpc:handle enter_map_succ]"),
    % tester:cmd(move, test_rpc, {State#tester.x +10, State#tester.y + 10, 0}, State),
    State#tester.pid ! {move_loop, [], 0},
    {ok, State};

%% 九宫格角色列表
handle(1016, Param, State) ->
    ?INFO("[test_rpc:handle Grid9_role_list]"),
    ?INFO("[test_rpc:handle role_list[~p]]",[Param]),
    {ok, State};

%% 新角色加入九宫中
handle(1013, Param, State) ->
    ?INFO("[test_rpc:handle new_role_join[~p]]",[Param]),
    {ok, State};
handle(1032, {V1_rid, V1_platform_id, V1_zone_id, V1_dir, V1_x, V1_y, V1_dx, V1_dy}, State) ->
    % ?INFO("[test_rpc:handle recv_move_msg][role_id:~p]", [V1_rid]),
    NewState = State#tester{x = V1_x, y = V1_y},
    {ok, NewState};
handle(Type, _, State) ->
    ?INFO("[test_rpc:handle not_match_type][type:~p]",[Type]),
    {ok, State}
.


