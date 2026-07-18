class_name RunResult
extends RefCounted

const RANK_ORDER := {&"S": 4, &"A": 3, &"B": 2, &"C": 1}

var level_id: StringName = &"easy"
var completion_time: float = 0.0
var pulse_count: int = 0
var decoy_count: int = 0
var chase_count: int = 0
var rank: StringName = &"C"


static func create(
	next_level_id: StringName,
	time_seconds: float,
	pulses: int,
	decoys: int,
	chases: int,
	par_time: float,
) -> RunResult:
	var result := RunResult.new()
	result.level_id = next_level_id
	result.completion_time = maxf(time_seconds, 0.0)
	result.pulse_count = maxi(pulses, 0)
	result.decoy_count = maxi(decoys, 0)
	result.chase_count = maxi(chases, 0)
	result.rank = calculate_rank(result.completion_time, result.chase_count, par_time)
	return result


static func calculate_rank(time_seconds: float, chases: int, par_time: float) -> StringName:
	var safe_par := maxf(par_time, 1.0)
	if time_seconds <= safe_par and chases <= 1:
		return &"S"
	if time_seconds <= safe_par * 1.25 and chases <= 3:
		return &"A"
	if time_seconds <= safe_par * 1.6:
		return &"B"
	return &"C"


static func is_better(candidate: RunResult, best_rank: StringName, best_time: float) -> bool:
	var candidate_order: int = RANK_ORDER.get(candidate.rank, 0)
	var best_order: int = RANK_ORDER.get(best_rank, 0)
	return candidate_order > best_order or (
		candidate_order == best_order
		and (best_time <= 0.0 or candidate.completion_time < best_time)
	)
