#include "EnemyBase.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/classes/sprite_frames.hpp> 
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void EnemyBase::_bind_methods() {
    // Bind export properties
    ClassDB::bind_method(D_METHOD("get_health"), &EnemyBase::get_health);
    ClassDB::bind_method(D_METHOD("set_health", "health"), &EnemyBase::set_health);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::FLOAT, "health"), "set_health", "get_health");

    ClassDB::bind_method(D_METHOD("get_damage"), &EnemyBase::get_damage);
    ClassDB::bind_method(D_METHOD("set_damage", "damage"), &EnemyBase::set_damage);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::FLOAT, "damage"), "set_damage", "get_damage");

    ClassDB::bind_method(D_METHOD("get_speed"), &EnemyBase::get_speed);
    ClassDB::bind_method(D_METHOD("set_speed", "speed"), &EnemyBase::set_speed);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::FLOAT, "speed"), "set_speed", "get_speed");

    ClassDB::bind_method(D_METHOD("get_explosion_scene"), &EnemyBase::get_explosion_scene);
    ClassDB::bind_method(D_METHOD("set_explosion_scene", "scene"), &EnemyBase::set_explosion_scene);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::OBJECT, "explosion_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_explosion_scene", "get_explosion_scene");

    ClassDB::bind_method(D_METHOD("get_bullet_scene"), &EnemyBase::get_bullet_scene);
    ClassDB::bind_method(D_METHOD("set_bullet_scene", "scene"), &EnemyBase::set_bullet_scene);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::OBJECT, "bullet_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_bullet_scene", "get_bullet_scene");

    ClassDB::bind_method(D_METHOD("get_damage_text_scene"), &EnemyBase::get_damage_text_scene);
    ClassDB::bind_method(D_METHOD("set_damage_text_scene", "scene"), &EnemyBase::set_damage_text_scene);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::OBJECT, "damage_text_scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_damage_text_scene", "get_damage_text_scene");

    ClassDB::bind_method(D_METHOD("get_fire_cooldown"), &EnemyBase::get_fire_cooldown);
    ClassDB::bind_method(D_METHOD("set_fire_cooldown", "cooldown"), &EnemyBase::set_fire_cooldown);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::FLOAT, "fire_cooldown"), "set_fire_cooldown", "get_fire_cooldown");

    ClassDB::bind_method(D_METHOD("get_score_value"), &EnemyBase::get_score_value);
    ClassDB::bind_method(D_METHOD("set_score_value", "value"), &EnemyBase::set_score_value);
    ClassDB::add_property("EnemyBase", PropertyInfo(Variant::INT, "score_value"), "set_score_value", "get_score_value");

    // Bind public methods
    ClassDB::bind_method(D_METHOD("take_damage", "amount"), &EnemyBase::take_damage);
    ClassDB::bind_method(D_METHOD("die"), &EnemyBase::die);
    ClassDB::bind_method(D_METHOD("spawn_explosion"), &EnemyBase::spawn_explosion);
    ClassDB::bind_method(D_METHOD("shoot"), &EnemyBase::shoot);
    ClassDB::bind_method(D_METHOD("set_as_power_shot"), &EnemyBase::set_as_power_shot);

    // Bind signal callbacks
    ClassDB::bind_method(D_METHOD("_on_area_entered", "area"), &EnemyBase::_on_area_entered);
    ClassDB::bind_method(D_METHOD("_on_body_entered", "body"), &EnemyBase::_on_body_entered);
    ClassDB::bind_method(D_METHOD("_on_visible_on_screen_notifier_2d_screen_exited"), &EnemyBase::_on_visible_on_screen_notifier_2d_screen_exited);

    // Add property group
    ClassDB::add_property_group("EnemyBase", "Shooting", "");
}

EnemyBase::EnemyBase() {
}

EnemyBase::~EnemyBase() {
}

void EnemyBase::_ready() {
    // Get node references
    sprite = get_node<Sprite2D>("Sprite2D");
    collision_shape = get_node<CollisionPolygon2D>("CollisionPolygon2D");
    muzzle = get_node<Marker2D>("Muzzle");
    
    // Optional nodes (might not exist in all enemy types)
    if (has_node("AnimatedSprite2D")) {
        animated_sprite = get_node<AnimatedSprite2D>("AnimatedSprite2D");
    }
    
    if (has_node("SfxPowerUp")) {
        sfx_power_up = get_node<AudioStreamPlayer2D>("SfxPowerUp");
    }
    
    if (has_node("VisibleOnScreenNotifier2D")) {
        screen_notifier = get_node<VisibleOnScreenNotifier2D>("VisibleOnScreenNotifier2D");
        if (screen_notifier) {
            screen_notifier->connect("screen_exited", Callable(this, "_on_visible_on_screen_notifier_2d_screen_exited"));
        }
    }

    // Connect signals
    connect("area_entered", Callable(this, "_on_area_entered"));
    connect("body_entered", Callable(this, "_on_body_entered"));
}

void EnemyBase::_physics_process(double delta) {
    // Move enemy straight down
    Vector2 pos = get_global_position();
    pos.y += speed * delta;
    set_global_position(pos);

    // SHOOTING LOGIC
    // Only run if enemy is not dying
    if (!is_dying) {
        // Countdown cooldown
        if (fire_timer > 0) {
            fire_timer -= delta;
        } else {
            // If cooldown finished, shoot!
            shoot();
            // Reset cooldown (add some randomness to avoid monotony)
            fire_timer = fire_cooldown + UtilityFunctions::randf_range(-0.5f, 0.5f);
        }
    }
}

void EnemyBase::take_damage(float amount) {
    // Spawn damage text
    if (damage_text_scene.is_valid()) {
        Node* damage_text = damage_text_scene->instantiate();
        // Add to root scene so it doesn't get destroyed with enemy
        get_tree()->get_root()->add_child(damage_text);
        // Start animation - assuming damage text has show_damage method
        damage_text->call("show_damage", amount, get_global_position());
    }

    health -= amount;
    if (health <= 0 && !is_dying) {
        die();
    }
}

void EnemyBase::die() {
    is_dying = true;
    // Disable collision to prevent other interactions
    if (collision_shape) {
        collision_shape->call_deferred("set_disabled", true);
    }

    // Spawn explosion
    spawn_explosion();

    // Hide sprite and emit score event
    if (sprite) {
        sprite->hide();
    }
    
    // Emit score update - assuming GameEvents is an autoload singleton
    Node* game_events = get_tree()->get_root()->get_node<Node>(NodePath("GameEvents"));
    if (game_events) {
        game_events->emit_signal("score_updated", score_value);
    }

    queue_free();
}

void EnemyBase::spawn_explosion() {
    // Make sure explosion scene is set in inspector
    if (!explosion_scene.is_valid()) return;

    // Create instance from explosion scene
    Node* explosion = explosion_scene->instantiate();
    // Add explosion to parent scene
    get_parent()->add_child(explosion);
    // Set explosion position same as enemy position
    if (Node2D* explosion_2d = Object::cast_to<Node2D>(explosion)) {
        explosion_2d->set_global_position(get_global_position());
    }
}

void EnemyBase::_on_area_entered(Area2D* area) {
    // Check if entered area is laser from 'player_lasers' group
    if (area && area->is_in_group("player_lasers")) {
        // Deal damage to self by 1 (as per specification)
        take_damage(1);
        // Destroy laser that hit
        area->queue_free();
    }
}

void EnemyBase::_on_body_entered(Node* body) {
    UtilityFunctions::print("SESUATU MASUK! Namanya: ", body->get_name()); // <-- TAMBAHKAN INI

    if (body->is_in_group("player")) {
        UtilityFunctions::print("YANG MASUK ADALAH PLAYER!"); // <-- TAMBAHKAN INI
        body->call("take_damage", damage);
        die();
    }
}

void EnemyBase::shoot() {
    // Make sure bullet scene is set in Inspector
    if (!bullet_scene.is_valid()) return;

    // Create bullet instance
    Node* bullet = bullet_scene->instantiate();

    // Add bullet to parent scene
    get_parent()->add_child(bullet);
    
    // Set bullet initial position at Muzzle
    if (Node2D* bullet_2d = Object::cast_to<Node2D>(bullet)) {
        if (muzzle) {
            bullet_2d->set_global_position(muzzle->get_global_position());
        }
        // Rotate 180 degrees to move downward
        bullet_2d->set_rotation_degrees(180);
    }
}

void EnemyBase::set_as_power_shot() {
    // Check if "power_up" animation exists in AnimatedSprite2D
    if (animated_sprite) {
        Ref<SpriteFrames> sprite_frames = animated_sprite->get_sprite_frames();
        if (sprite_frames.is_valid() && sprite_frames->has_animation("power_up")) {
            animated_sprite->play("power_up");
        }
    }

    // Check if power-up sound node exists before playing
    if (sfx_power_up) {
        sfx_power_up->play();
    }
}

void EnemyBase::_on_visible_on_screen_notifier_2d_screen_exited() {
    queue_free();
}

// Implementasi Getters & Setters
void EnemyBase::set_health(const float p_health) { health = p_health; }
float EnemyBase::get_health() const { return health; }

void EnemyBase::set_damage(const float p_damage) { damage = p_damage; }
float EnemyBase::get_damage() const { return damage; }

void EnemyBase::set_speed(const float p_speed) { speed = p_speed; }
float EnemyBase::get_speed() const { return speed; }

void EnemyBase::set_score_value(const int p_value) { score_value = p_value; }
int EnemyBase::get_score_value() const { return score_value; }

void EnemyBase::set_fire_cooldown(const float p_cooldown) { fire_cooldown = p_cooldown; }
float EnemyBase::get_fire_cooldown() const { return fire_cooldown; }

void EnemyBase::set_explosion_scene(const Ref<PackedScene>& p_scene) { explosion_scene = p_scene; }
Ref<PackedScene> EnemyBase::get_explosion_scene() const { return explosion_scene; }

void EnemyBase::set_bullet_scene(const Ref<PackedScene>& p_scene) { bullet_scene = p_scene; }
Ref<PackedScene> EnemyBase::get_bullet_scene() const { return bullet_scene; }

void EnemyBase::set_damage_text_scene(const Ref<PackedScene>& p_scene) { damage_text_scene = p_scene; }
Ref<PackedScene> EnemyBase::get_damage_text_scene() const { return damage_text_scene; }
