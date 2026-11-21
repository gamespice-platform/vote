extends RefCounted

## GameSpice Vote's API level; the bumping rule is on [GSAddonApi].
## LEVEL rises for anything new a game could call; OLDEST is raised when something callable is removed or changes meaning.

# 1: everything before this file existed (an absent file reads as 1).
# 2: GSVoteListSource.entries_fn and refresh(), GSVoteSource.before_ballot(); a passed
#    rock-the-vote opens its ballot under trigger MANUAL.
# 3: GSVoteDirector.round_in_progress_fn; finish_round holds nothing while no round is live.
# 4: GSVoteDirector.people_fn and display_name(); lines about a player name them, not
#    their id; GSVoteBallotFeed.people_fn is handed to a director that has none.
# 5: the map menu's server half: GSVoteMapMenu (`mapmenu`, `sv_map_menu_flag`, change_fn,
#    rows_fn, notice_fn), GSVoteCommands.map_menu and with_map_menu.
# 6: GSVoteMapMenu.unavailable_text(); a source's optional unavailable_reason(id) says why
#    the menu refuses an id it does not offer now.
# 7: the map menu fails closed and counts humans: sv_map_menu_flag empty is staff and
#    `anyone` is everybody; sv_map_menu_alone (the only human may change directly) and
#    sv_map_menu_vote_min (humans before a menu choice rocks the vote); GSVoteMapMenu
#    humans_fn, humans(), is_staff(), is_alone(), alone_allowed(), min_voters(); the
#    listen host's own (local) session may change; an offer carries `alone`.
# 8: votebans: GSVoteBans (start(starter, target, reason), vote, advance, the voteban,
#    voteban_yes and voteban_no commands) and GSVoteBanRules (the sv_voteban* cvars).
# 9: GSVoteBallotFeed.describe() and GSVoteCommands.describe().
# 10: GSVoteListSource.follow_content(index, accepted_kinds) and GSVoteChoice.pack_title and
#     label() ("Name [Pack]"), which every ballot, menu and message prints.
# 11: GSVoteCommands names that take lists (aliases), spec_fn, chat_prefix, skipped, typed;
#     GSVoteGameSource.order; GSVoteMapSource skips maps outside the rotation. Needs GameSpice Core
#     API level 12 (GSCommandNames).
# 12: GSVoteListSource.in_rotation_fn and rotation_order_fn: the rotation filter and order
#     apply to every choice, the maps merged by follow_content included.
# 13: GSVoteRules.apply_cfg_file and load_cfg read cfg/addons/gs_vote/<file>.yml and the
#     operator's cfg/server/addons/gs_vote/, with the flat cfg/<file>.yml as a shim.
#     Needs GameSpice Core API level 16 (GSAddonConfig.apply_file).
# 15: GSVoteRoundGame, the next-map vote of a round-based game (director, list source, feed,
#     commands, when the ballot opens) once; a game extends it and sets its names.
# 16: GSVoteRoundGame hooks a game overrides: _apply, _ballot_may_open, _map_noted, _ticked; the
#     source's label is the noun, pluralised.
# 17: GSVoteTimedGame, the vote of a game on a clock (time limit, no rounds), extended by the game: director, source, feed, `!vote`,
#     relaying the signals and the clock once here.
const LEVEL := 17
const OLDEST := 1
