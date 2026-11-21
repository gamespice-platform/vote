extends "res://examples/selftest/selftest_config_and_quorum.gd"

## Selftest sections: that every rules setting is read.


## Fails for any setting nothing reads.
func _test_every_setting_is_read() -> void:
	_section("Every setting is read by something")

	var sources := {}
	_read_scripts("res://addons/gs_vote", sources)

	_check(sources.size() >= 12, "%d scripts scanned" % sources.size())

	var rules := GSVoteRules.new()
	var declarations := str(sources.get("res://addons/gs_vote/core/gs_vote_rules.gd", ""))
	var unread := PackedStringArray()

	for key in rules.config_keys():
		if _reads_setting(key, sources, declarations):
			continue

		unread.append(key)

	_check(
		unread.is_empty(),
		"all %d settings are read somewhere" % rules.config_keys().size(),
		"declared and read by nothing: %s" % ", ".join(unread)
	)

	_done()
