class_name GSVoteBallotView
extends RefCounted

## A ballot as a player's screen draws it: options, counts, who voted for what, and how to choose.
## The other half of [GSVoteClockView]: a dictionary a server makes from its director and a client draws from, with no wire format of its own. Fields: docs/design.md "A ballot a player can click".
## Options are in [method GSVoteBallot.option_ids] order (what a typed number indexes), never [method GSVoteBallot.countable_ids]. A pure function of the director; logs nothing.

## Most options sent. [member GSVoteRules.max_options] is at most 32 already; this is what a
## reader can rely on without trusting the writer.
const MAX_OPTIONS := 32

## Most voters named. Past this the counts are still right and the rest are not drawn: a
## ballot with a hundred faces on it is not readable anyway, and the dictionary has to fit
## comfortably in one message.
const MAX_VOTERS := 64

## Longest label sent.
const MAX_LABEL := 48


## The ballot [param director] has open, or a closed one when it has none.
## [param people_fn] answers [code]voter -> {"name", "avatar"}[/code] (the host's, since voter ids are the server's); optional.
static func state_of(director: GSVoteDirector, people_fn: Callable = Callable()) -> Dictionary:
	if director == null or director.ballot == null or not director.ballot.open:
		return {"open": false}

	var rules := director.rules
	var ballot := director.ballot
	var ids := ballot.option_ids()
	var counts := ballot.tally()

	var options := []
	var index := {}

	for id in ids:
		if options.size() >= MAX_OPTIONS:
			break

		index[id] = options.size()
		options.append({
			"id": String(id),
			"label": director.option_label(id).left(MAX_LABEL),
			"votes": float(counts.get(id, 0.0)),
		})

	var out := {
		"open": true,
		"runoff": ballot.runoffs_held > 0,
		"seconds": snappedf(director.vote_seconds_remaining(), 0.1),
		"input": input_name(rules.ballot_input),
		"multi": rules.method == GSVoteRules.Method.APPROVAL
			or rules.method == GSVoteRules.Method.INSTANT_RUNOFF,
		"options": options,
	}

	if not rules.ballot_show_voters:
		return out

	var voters := {}
	var people := {}

	for voter: Variant in ballot.ballots:
		if voters.size() >= MAX_VOTERS:
			break

		var chosen: Array = ballot.ballots[voter]

		# An abstention is an empty ballot: answered, and nowhere on the board.
		if chosen.is_empty() or not index.has(chosen[0]):
			continue

		var key := String(voter)
		voters[key] = int(index[chosen[0]])

		if people_fn.is_valid():
			var who: Variant = people_fn.call(StringName(key))

			if who is Dictionary:
				people[key] = {
					"name": str((who as Dictionary).get("name", key)).left(MAX_LABEL),
					"avatar": str((who as Dictionary).get("avatar", "")).left(512),
				}

	out["voters"] = voters

	if not people.is_empty():
		out["people"] = people

	return out


## The closed state for [param result]: what won, for a client to show briefly before the
## ballot goes away.
static func closed_state(director: GSVoteDirector, result: GSVoteResult) -> Dictionary:
	var out := {"open": false}

	if result == null:
		return out

	if result.winner_id != &"":
		out["winner"] = (
			director.option_label(result.winner_id) if director != null
			else String(result.winner_id)
		).left(MAX_LABEL)

	if result.outcome == GSVoteResult.Outcome.RUNOFF:
		out["runoff_next"] = true

	return out


## The lower-case name of a [enum GSVoteRules.BallotInput], as the dictionary carries it.
static func input_name(value: int) -> String:
	match value:
		GSVoteRules.BallotInput.NUMBERS:
			return "numbers"
		GSVoteRules.BallotInput.POINTER:
			return "pointer"
		_:
			return "both"


## Whether two states would draw the same ballot, ignoring the time left — which a client
## counts for itself and which differs on every tick, so comparing it would resend the
## whole ballot sixty times a second.
static func same_ballot(a: Dictionary, b: Dictionary) -> bool:
	var x := a.duplicate()
	var y := b.duplicate()
	x.erase("seconds")
	y.erase("seconds")
	return x.hash() == y.hash()
