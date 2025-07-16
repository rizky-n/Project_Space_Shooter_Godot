#include "enemies/tanker_enemy.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot {

TankerEnemy::TankerEnemy() {}
TankerEnemy::~TankerEnemy() {}

void TankerEnemy::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_collision_damage"), &TankerEnemy::get_collision_damage);
    ClassDB::bind_method(D_METHOD("set_collision_damage", "p_damage"), &TankerEnemy::set_collision_damage);
    ClassDB::add_property("TankerEnemy", PropertyInfo(Variant::FLOAT, "collision_damage"), "set_collision_damage", "get_collision_damage");
}

void TankerEnemy::shoot() {
    Ref<PackedScene> bullet_scene = get_bullet_scene();
    if (!bullet_scene.is_valid()) return;

    Node* muzzles = get_node_or_null("Muzzle");
    if (!muzzles) return;

    for (int i = 0; i < muzzles->get_child_count(); ++i) {
        Marker2D* muzzle = Object::cast_to<Marker2D>(muzzles->get_child(i));
        if (muzzle) {
            Node* bullet_instance = bullet_scene->instantiate();
            get_parent()->add_child(bullet_instance);

            Node2D* bullet_2d = Object::cast_to<Node2D>(bullet_instance);
            if (bullet_2d) {
                bullet_2d->set_global_position(muzzle->get_global_position());
                
                // INI ADALAH BARIS YANG BENAR DAN FINAL BERDASARKAN API C++
                Vector2 fire_direction = muzzle->get_global_transform()[1].normalized();
                
                bullet_2d->set_rotation(fire_direction.angle() + Math_PI / 2.0);
            }
        }
    }
}

void TankerEnemy::_on_body_entered(Node *body) {
    if (is_dying) return; // Asumsi is_dying() adalah fungsi dari base class
    if (body->is_in_group("player")) {
        body->call("take_damage", collision_damage); // Gunakan collision_damage
        die(); // Hancurkan diri setelah menabrak
    }
}

void TankerEnemy::set_collision_damage(const float p_damage) { collision_damage = p_damage; }
float TankerEnemy::get_collision_damage() const { return collision_damage; }

} // namespace godot