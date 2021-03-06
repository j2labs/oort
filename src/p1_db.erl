-module(p1_db).
-author("orbitz@ortdotlove.net").

-include("db.hrl").

-export([create_tables/0,
         start/0,
         stop/0,
         insert_row/1,
         select/2,
         foldl/3,
         write/1,
         wait_for_tables/0,
         create_database/0,
         read/2,
         transaction/1,
         create_table/2,
         delete/2,
         delete_record/1,
         get_all_keys/1]).

start() ->
    ok = mnesia:start().

create_database() ->
    mnesia:create_schema([node()]),
    start(),
    create_tables().

create_tables() ->
    mnesia:create_table(irc_bot_db, [{disc_copies, [node()]}, {attributes, record_info(fields, irc_bot_db)}]),
    mnesia:create_table(relay_client, [{type, bag}, {disc_copies, [node()]}, {attributes, record_info(fields, relay_client)}]),
    mnesia:create_table(factoid_tree, [{type, bag}, {disc_copies, [node()]}, {attributes, record_info(fields, factoid_tree)}]),
    mnesia:create_table(plugin_record, [{disc_copies, [node()]}, {record_name, plugin_record}, {type, set}]),
    mnesia:create_table(factoid_data, [{type, bag}, {disc_copies, [node()]}, {attributes, record_info(fields, factoid_data)}]).


%%
% This creates a table if it does not exist already
create_table(Name, Opts) ->
    Tables = mnesia:system_info(local_tables),
    case lists:member(Name, Tables) of
        true ->
            ok;
        false ->
            {atomic, ok} = mnesia:create_table(Name, Opts),
            ok
    end.
        

insert_row(Row) ->
    transaction(fun() -> mnesia:write(Row) end).

select(Tag, Matchspec) ->
    transaction(fun() -> mnesia:select(Tag, Matchspec) end).

foldl(Func, Acc0, Tab) ->
    transaction(fun() -> mnesia:foldl(Func, Acc0, Tab) end).

write(Data) ->
    transaction(fun() -> mnesia:write(Data) end).

read(Tab, Key) ->
    transaction(fun() -> mnesia:read(Tab, Key, read) end).

delete(Tab, Key) ->
    transaction(fun() -> mnesia:delete({Tab, Key}) end).

delete_record(Record) ->
    transaction(fun() -> mnesia:delete_object(Record) end).

get_all_keys(Table) ->
    transaction(fun() -> mnesia:all_keys(Table) end).
                

transaction(Fun) ->
    mnesia:transaction(Fun).

wait_for_tables() ->
    mnesia:wait_for_tables([irc_bot_db], infinity).

stop() ->
    mnesia:stop().

