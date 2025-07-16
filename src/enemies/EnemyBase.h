#ifndef ENEMY_BASE_H
#define ENEMY_BASE_H

#pragma once // Mencegah file di-include lebih dari sekali

// Include semua header dari kelas Godot yang kita gunakan
#include <godot_cpp/classes/area2d.hpp>
#include <godot_cpp/classes/animated_sprite2d.hpp>
#include <godot_cpp/classes/audio_stream_player2d.hpp>
#include <godot_cpp/classes/collision_polygon2d.hpp>
#include <godot_cpp/classes/marker2d.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/classes/visible_on_screen_notifier2d.hpp>

namespace godot {

class EnemyBase : public Area2D {
    GDCLASS(EnemyBase, Area2D)

private:
    // Properti yang akan diekspos ke Godot Editor
    float health = 10.0;
    float damage = 3.0;
    float speed = 100.0;
    int score_value = 100;
    float fire_cooldown = 3.0;
    Ref<PackedScene> explosion_scene;
    Ref<PackedScene> bullet_scene;
    Ref<PackedScene> damage_text_scene;

    // Referensi ke Node anak (diambil di _ready)
    Sprite2D* sprite = nullptr;
    CollisionPolygon2D* collision_shape = nullptr;
    Marker2D* muzzle = nullptr;
    AnimatedSprite2D* animated_sprite = nullptr;
    AudioStreamPlayer2D* sfx_power_up = nullptr;
    VisibleOnScreenNotifier2D* screen_notifier = nullptr;
    
    // Variabel internal untuk logika
    bool is_dying = false;
    float fire_timer = 0.0;

protected:
    // Wajib ada untuk mendaftarkan method dan properti ke Godot
    static void _bind_methods();

public:
    // Konstruktor & Destruktor
    EnemyBase();
    ~EnemyBase();

    // Fungsi "lifecycle" Godot
    virtual void _ready() override;
    virtual void _physics_process(double delta) override;

    // Fungsi untuk logika game
    void take_damage(float amount);
    void die();
    void spawn_explosion();
    virtual void shoot();
    void set_as_power_shot();

    // Fungsi yang dipanggil oleh sinyal (signal callbacks)
    virtual void _on_area_entered(Area2D* area); // <-- Tambah virtual
    virtual void _on_body_entered(Node* body); // <-- Tambah virtual
    void _on_visible_on_screen_notifier_2d_screen_exited();

    // Getters & Setters untuk properti yang diekspos (digunakan oleh _bind_methods)
    void set_health(const float p_health);
    float get_health() const;
    void set_damage(const float p_damage);
    float get_damage() const;
    void set_speed(const float p_speed);
    float get_speed() const;
    void set_score_value(const int p_value);
    int get_score_value() const;
    void set_fire_cooldown(const float p_cooldown);
    float get_fire_cooldown() const;
    void set_explosion_scene(const Ref<PackedScene> &p_scene);
    Ref<PackedScene> get_explosion_scene() const;
    void set_bullet_scene(const Ref<PackedScene> &p_scene);
    Ref<PackedScene> get_bullet_scene() const;
    void set_damage_text_scene(const Ref<PackedScene> &p_scene);
    Ref<PackedScene> get_damage_text_scene() const;
};

} // namespace godot

#endif // ENEMY_BASE_H