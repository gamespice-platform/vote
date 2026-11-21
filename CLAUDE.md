# GameSpice Vote

Voting for what plays next: one ballot engine over ids, with rock-the-vote, nominations, runoffs, weighting, cooldowns, time, round and score limits, and the extend rules, for a server's next map or its next game.

Read the family [CLAUDE.md](../../CLAUDE.md) first; this file is only what is specific to this addon.

**Only GameSpice Core is a dependency, at API level 16 or later (`GSAddonConfig.apply_file`).** GameSpice Map and GameSpice Server are optional, reached by `load()` and `call()`, and linked (`.gitignore`) only so the suite's integration sections can run against the real thing.

## Read before

| Read | Before |
| --- | --- |
| [docs/design.md](docs/design.md) | anything: why it is separate from `GSMapVote` and `GSVoteManager`, choices as ids, the empty server, the three clocks, the ballot view, what is not here, the suite |
| [docs/parity.md](docs/parity.md) | adding a setting: every setting, command, query and event of the community map-choosers against what covers it here; the row may already exist under another name |
| [docs/history.md](docs/history.md) | the bugs, and how each looked |

## Layout

| Path | What |
| --- | --- |
| `addons/gs_vote/core/` | `GSVoteChoice` (an id, a name, a ballot's facts), `GSVoteResult`, `GSVoteRules` (every policy, a `GSConfig`) |
| `addons/gs_vote/runtime/` | `GSVoteDirector` (the engine), `GSVoteBallot`, `GSVoteClock`, `GSVoteNominations`, `GSVoteHistory`, `GSVoteSource` / `GSVoteListSource`, and the client views `GSVoteClockView`, `GSVoteBallotView`, `GSVoteBallotFeed` |
| `addons/gs_vote/integrations/` | `GSVoteCommands`, `GSVoteMapMenu` (the M menu's server half, installed with the commands), `GSVoteMapSource` (GameSpice Map), `GSVoteGameSource` (GameSpice Server's `GSGameManager`), `GSVoteRoundGame` (a round-based game's next-map vote, extended by the game), `GSVoteTimedGame` (the vote of a game on a clock, extended by the game) |
| `addons/gs_vote/runtime/gs_vote_bans.gd`, `gs_vote_ban_rules.gd` | `GSVoteBans` (a yes/no vote to ban one player; `start`, `vote`, `ban_fn`) and its `sv_voteban*` cvars. [design](docs/design.md#votebans) |
| `examples/vote_selftest.tscn` | the suite; `examples/fixtures/` its data |

## Running and testing

- The family's two steps ([family CLAUDE.md](../../CLAUDE.md#validating-anything)), then `godot --headless --path . res://examples/vote_selftest.tscn` (non-zero on failure).
- `addons/gs_map` and `addons/gs_server` must be linked; without them the two integration sections fail loudly, on purpose. [design](docs/design.md#the-suite)
- A new check is not done until it has been armed: break the code it guards and watch it fire. [design](docs/design.md#four-rules-from-the-parity-work)

## Rules that bite

- A choice is an id plus metadata, never a `GSGameDescriptor` or a map; sources are duck-typed; per-choice settings live in the thing's own metadata under `vote`. [design](docs/design.md#the-one-design-decision)
- Every `GSVoteRules` setting must be read by something; the suite's sweep checks it, and a setting read in two branches that behave the same is the same bug. [history](docs/history.md#building-it)
- Never name GameSpice Server or GameSpice Map classes; spell their constants out (`admin_permission = "changemap"` is `GSAdminFlags.CHANGEMAP`). [history](docs/history.md#the-parity-work)
- `GSVoteClock` latches when it fires, so a `vote_due` that cannot open is retried (`_vote_due_pending`), never dropped. [history](docs/history.md#building-it)
- A `start_vote` refused only for `busy_fn` is owed, not dropped; `open_vote` is refused outright. [history](docs/history.md#later)
- `elapsed` counts on a clock with no limit; rock-the-vote timing depends on it. [history](docs/history.md#building-it)
- A no-change ballot restarts the clock after an end-of-map vote and RESUMES it after a rock-the-vote; `_carry_on` is the only place that decides. [design](docs/design.md#four-rules-from-the-parity-work)
- A pending change carries its own moment (`_pending_moment`); `_ready_to_apply` is the one gate every moment goes through, including the `finish_round` hold. [design](docs/design.md#three-clocks-and-only-one-of-them-is-a-rounds)
- `option_ids()` is display order and what a typed number indexes; `countable_ids()` (choices first) is what ties are broken in. [design](docs/design.md#four-rules-from-the-parity-work)
- `round_based` is set only by a host that reports every round end; only a time or score limit waits for the round. [design](docs/design.md#three-clocks-and-only-one-of-them-is-a-rounds)
- `trigger: manual` hands the host only the SCHEDULED ballot; a passed rock-the-vote opens its own under every trigger, and a host's leftover `clock.expired` handler finds it open (vote_due fires before expired). [design](docs/design.md#manual-is-the-schedule-not-rock-the-vote)
- API level is `addons/gs_vote/gs_vote_api.gd`; bump LEVEL for anything a game can call.
- `trigger: round_end` must behave differently from `time_limit` (a held ballot, `is_waiting_for_round_end()`); `rtv_only` and `end_vote: false` never open a ballot at the lead. [history](docs/history.md#the-parity-work)
- Hibernation pauses everything and wakes with `restart()`, which writes no second history entry. An empty server that does not sleep moves on by `empty_choice`, drawn from `empty_rng`, never `fill_seed`. [design](docs/design.md#an-empty-server-the-clock-sleeps-or-the-server-moves-on-by-itself)
- `on_no_votes` is a ballot nobody voted in; `empty_choice` is a server nobody is on. Different keys. [design](docs/design.md#an-empty-server-the-clock-sleeps-or-the-server-moves-on-by-itself)
- `GSVoteBallotFeed` is polled, compares by hash ignoring seconds, and holds `vote_closed` for exactly one poll. [design](docs/design.md#a-ballot-a-player-can-click)
- A line about a player names them through `display_name(voter)`, never the voter id. [history](docs/history.md#later)
- `mapmenu` is open to everybody and gated inside by `sv_map_menu_flag` (`generic`, staff, by default; `anyone` is everybody): the flag changes the map now, anybody else nominates and rocks the vote. **It fails closed**: an empty, unset or unregistered flag is staff, never anybody. A non-staff choice rocks only with `sv_map_menu_vote_min` humans (2, never fewer) playing and never in a way that passes without most of them; the only human on the server changes directly while `sv_map_menu_alone` is 1 (the default); the listen host's own (`local`) session always may. Humans are server sessions, so bots never count. A `+sv_map_menu_*` value on the server's command line is applied when the menu registers the cvar (the boot runs the command line before any module exists). Its server half is installed by `GSVoteCommands.bind`; a game whose apply means "next round" sets `map_menu.change_fn` to change now. `GSVoteMapMenu` holds its commands weakly (they hold it). [design](docs/design.md#the-map-menu)
- Extend comes off the ballot when the extensions are used up; nominations are refused while a ballot is open. [history](docs/history.md#the-parity-work)

## Where a game plugs in

| To change | Where |
| --- | --- |
| Any policy at all | `GSVoteRules`, layered like every `GSConfig` (`defaults < file < GS_VOTE_* < --vote-*`) |
| A round-based game's whole next-map vote (director, source, feed, `!vote`, when the ballot opens) | extend `GSVoteRoundGame` (API 15; hooks `_apply`, `_ballot_may_open`, `_map_noted`, `_ticked` at 16): set `channel`, `metadata_key`, `command_names`, `config_path` in `_init`, override `_default_kinds()` and, for its own defaults, `_rules()`. `examples/round_game_selftest.tscn` |
| The vote of a game on a clock, not rounds (director, source, feed, `!vote`, the signal and clock relay a host sends clients) | extend `GSVoteTimedGame` (API 17): set `channel`, `metadata_key`, `command_names`, `noun`, `config_path` in `_init`, override `_rules()` (a TIME_LIMIT), `_make_source()` for choices that are not a list, `_configure_director()`, `_voters()`, `_in_our_words()`, `_describe_extra()`. `examples/timed_game_selftest.tscn` |
| A game's own defaults, under an operator's file | `GSVoteRules.layer_over_defaults(file, GSVoteGameSource.running_game_metadata("map_vote"))` |
| What can be voted for | `GSVoteSource` subclass, or `GSVoteListSource` with a `Callable` |
| Which maps the server's rotation (maps.yml) plays, and in what order | `GSVoteListSource.in_rotation_fn` / `rotation_order_fn`, applied to the merged `follow_content` maps too |
| A list that grows after the director is built (delivered maps) | `GSVoteListSource.entries_fn`, re-read at `begin` and before every ballot (`GSVoteSource.before_ballot`) |
| How many players there are, who is an admin, who is a spectator | `GSVoteDirector.player_count_fn` / `is_admin_fn` / `is_spectator_fn` |
| What one player's vote is worth | `GSVoteDirector.weight_fn` |
| The name a line gives a player | `GSVoteDirector.people_fn` (or the feed's, handed over when the director has none); the id without one |
| What the players are told | `GSVoteDirector.announce_fn` |
| What they hear | `GSVoteDirector.cue` (a signal carrying a `cue_*` id) |
| A countdown on a HUD | `GSVoteDirector.countdown_started` / `countdown_tick` |
| The time left on a client's HUD | `GSVoteClockView`: `state_of(director)` on the server, sent when `is_stale`; `adopt` and `formatted_at` on the client |
| The ballot drawn on a client's screen | `GSVoteBallotView.state_of(director, people_fn)` and `GSVoteBallotFeed`; gs-ui's `GSBallotPanel` draws it |
| Whether a time limit waits for the round in progress | `GSVoteRules.time_up` / `finish_round_max_sec`, `GSVoteDirector.round_based`, and `round_in_progress_fn` (warmup holds nothing) |
| Whether another vote is on screen | `GSVoteDirector.busy_fn` |
| The leading score, for a score limit | `GSVoteDirector.note_score` |
| Whether this addon changes anything at all | `GSVoteDirector.auto_apply`, or a source with no apply |
| Whether the clock waits while the server sleeps | `GSVoteDirector.follow_hibernation(server)` (duck-typed on `hibernation_changed(bool)`), or `set_hibernating`; `GSVoteRules.wake_restart` |
| What an empty server's limit does when nothing sleeps | `GSVoteRules.empty_choice` (`random`, `rotation`, `wait`); `GSVoteDirector.empty_rng` |
| What a ballot nobody voted in decides | `GSVoteRules.on_no_votes` (`keep`, `random`, `rotation`) |
| Command names | `GSVoteCommands.prefix` / `names` |
| Who may change the map from the M menu | `sv_map_menu_flag` (an admin flag; `anyone` is everybody; empty is staff) |
| Whether the only human here may change it from M | `sv_map_menu_alone` (1) |
| Humans playing before an M choice rocks the vote | `sv_map_menu_vote_min` (2, never fewer) |
| How the M menu changes the map now, and what its rows say | `GSVoteCommands.map_menu.change_fn` / `rows_fn` |
| Why the M menu refuses an id the source does not offer now | the source's duck-typed `unavailable_reason(id) -> String` |
| How a command context becomes a voter | `GSVoteCommands.voter_fn` |
| How what a player typed becomes a choice id | `GSVoteCommands.resolve_fn` (a game whose ids carry a prefix) |

Deliberately not here: a wire format, UI, persistence, per-choice permissions, drawing or playing anything, a GameSpice Audio dependency. [design](docs/design.md#deliberately-not-here)
