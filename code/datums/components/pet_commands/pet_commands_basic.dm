// None of these are really complex enough to merit their own file

/**
 * # Pet Command: Idle
 * Tells a pet to resume its idle behaviour, usually staying put where you leave it
 */
/datum/pet_command/idle
	command_name = "Stay"
	command_desc = "Command your pet to stay idle in this location."
	radial_icon = 'icons/testing/turf_analysis.dmi'
	radial_icon_state = "red_arrow"
	command_key = PET_COMMAND_IDLE
	speech_commands = list("sit", "stay", "stop")
	command_feedback = "sits"

/datum/pet_command/idle/execute_action(datum/ai_controller/controller)
	return SUBTREE_RETURN_FINISH_PLANNING // This cancels further AI planning

/**
 * # Pet Command: Stop
 * Tells a pet to exit command mode and resume its normal behaviour, which includes regular target-seeking and what have you
 */
/datum/pet_command/free
	command_name = "Loose"
	command_desc = "Allow your pet to resume its natural behaviours."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "repulse"
	command_key = PET_COMMAND_NONE
	speech_commands = list("free", "loose")
	command_feedback = "relaxes"

/datum/pet_command/free/execute_action(datum/ai_controller/controller)
	return // Just move on to the next planning subtree.

/**
 * # Pet Command: Follow
 * Tells a pet to follow you until you tell it to do something else
 */
/datum/pet_command/follow
	command_name = "Follow"
	command_desc = "Command your pet to accompany you."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "summons"
	command_key = PET_COMMAND_FOLLOW
	speech_commands = list("heel", "follow")

/datum/pet_command/follow/set_command_active(mob/living/parent, mob/living/commander)
	. = ..()
	set_command_target(parent, commander)

/datum/pet_command/follow/execute_action(datum/ai_controller/controller)
	controller.queue_behavior(/datum/ai_behavior/pet_follow_friend, BB_CURRENT_PET_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Attack
 * Tells a pet to chase and bite the next thing you point at
 */
/datum/pet_command/point_targetting/attack
	command_name = "Attack"
	command_desc = "Command your pet to attack things that you point out to it."
	radial_icon = 'icons/effects/effects.dmi'
	radial_icon_state = "bite"

	command_key = PET_COMMAND_ATTACK
	speech_commands = list("attack", "sic", "kill")
	command_feedback = "growl"
	pointed_reaction = "growls"
	/// Balloon alert to display if providing an invalid target
	var/refuse_reaction = "shakes head"
	/// Attack behaviour to use, generally you will want to override this to add some kind of cooldown
	var/attack_behaviour = /datum/ai_behavior/basic_melee_attack

// Refuse to target things we can't target, chiefly other friends
/datum/pet_command/point_targetting/attack/set_command_target(mob/living/parent, atom/target)
	if (!target)
		return
	var/mob/living/living_parent = parent
	if (!living_parent.ai_controller)
		return
	var/datum/targetting_datum/targeter = living_parent.ai_controller.blackboard[targetting_datum_key]
	if (!targeter)
		return
	if (!targeter.can_attack(living_parent, target))
		refuse_target(parent, target)
		return
	return ..()

/// Display feedback about not targetting something
/datum/pet_command/point_targetting/attack/proc/refuse_target(mob/living/parent, atom/target)
	var/mob/living/living_parent = parent
	living_parent.balloon_alert_to_viewers("[refuse_reaction]")
	living_parent.visible_message(span_notice("[living_parent] refuses to attack [target]."))

/datum/pet_command/point_targetting/attack/execute_action(datum/ai_controller/controller)
	controller.queue_behavior(attack_behaviour, BB_CURRENT_PET_TARGET, targetting_datum_key)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Targetted Ability
 * Tells a pet to use some kind of ability on the next thing you point at
 */
/datum/pet_command/point_targetting/use_ability
	command_name = "Use ability"
	command_desc = "Command your pet to use one of its special skills on something that you point out to it."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "projectile"
	command_key = PET_COMMAND_USE_ABILITY
	speech_commands = list("shoot", "blast", "cast")
	command_feedback = "growl"
	pointed_reaction = "growls"
	/// Blackboard key where a reference to some kind of mob ability is stored
	var/pet_ability_key

/datum/pet_command/point_targetting/use_ability/execute_action(datum/ai_controller/controller)
	if (!pet_ability_key)
		return
	var/datum/action/cooldown/using_action = controller.blackboard[pet_ability_key]
	if (QDELETED(using_action))
		return
	// We don't check if the target exists because we want to 'sit attentively' if we've been instructed to attack but not given one yet
	// We also don't check if the cooldown is over because there's no way a pet owner can know that, the behaviour will handle it
	controller.queue_behavior(/datum/ai_behavior/pet_use_ability, pet_ability_key, BB_CURRENT_PET_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING
