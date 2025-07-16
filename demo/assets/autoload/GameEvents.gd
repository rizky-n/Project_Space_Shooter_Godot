# GameEvents.gd
extends Node

# Sinyal untuk semua kejadian penting di dalam game
signal score_updated(new_score)
signal high_score_updated(new_high_score)
signal player_health_updated(current_health, max_health)
signal boss_appeared(boss_name, max_health)
signal boss_health_updated(current_health)
signal boss_defeated
signal player_died
