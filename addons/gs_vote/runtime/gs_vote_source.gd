class_name GSVoteSource
extends RefCounted

## Where the choices come from, and what "play this one" means.
## The one seam that makes the addon general: everything above works in ids, and only a source knows an id is a game, a map or a database row. Subclass it, or hand [GSVoteListSource] a [Callable].
## [method apply] may be a coroutine; [GSVoteDirector] awaits the result either way.

## A short name for logs and console output.
func source_name() -> String:
	return "source"


## Everything that could be offered, in the source's own order.
## Called on every ballot fill, not cached, so a game added at runtime is offered.
func choices() -> Array[GSVoteChoice]:
	return []


## What is running now, or [code]&""[/code].
func current_id() -> StringName:
	return &""


func find(id: StringName) -> GSVoteChoice:
	for choice in choices():
		if choice.id == id:
			return choice

	return null


func has(id: StringName) -> bool:
	return find(id) != null


func ids() -> Array[StringName]:
	var out: Array[StringName] = []

	for choice in choices():
		out.append(choice.id)

	return out


## Re-reads whatever this source caches, for an admin's "reload the list".
## Most sources cache nothing, so the default does nothing; a source that reads a file overrides it.
func reload() -> GSResult:
	return GSResult.success(0)


## Called by [GSVoteDirector] when a choice begins and before a ballot is filled; nothing by default.
## [GSVoteListSource] re-reads its [member GSVoteListSource.entries_fn] here.
func before_ballot() -> void:
	pass


## Whether this source can act on a result at all.
## A source that only lists is legitimate (a client-side mirror of a server's vote); [signal GSVoteDirector.change_due] is emitted either way.
func supports_apply() -> bool:
	return false


## Switches to [param id]. May be a coroutine.
func apply(id: StringName) -> GSResult:
	return GSResult.fail(
		GSError.CODE_UNSUPPORTED,
		"%s cannot change what is running." % source_name(),
		"connect to GSVoteDirector.change_due and do it in the host"
	)


func describe() -> Dictionary:
	return {
		"source": source_name(),
		"choices": choices().size(),
		"current": String(current_id()) if current_id() != &"" else "-",
		"can_apply": supports_apply(),
	}
