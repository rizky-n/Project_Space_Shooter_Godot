#include "enemies/spinning_enemy.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

SpinningEnemy::SpinningEnemy() {}
SpinningEnemy::~SpinningEnemy() {}

void SpinningEnemy::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_rotation_speed"), &SpinningEnemy::get_rotation_speed);
    ClassDB::bind_method(D_METHOD("set_rotation_speed", "p_speed"), &SpinningEnemy::set_rotation_speed);
    ClassDB::add_property("SpinningEnemy", PropertyInfo(Variant::FLOAT, "rotation_speed"), "set_rotation_speed", "get_rotation_speed");
}

void SpinningEnemy::_physics_process(double delta) {
    // Panggil dulu implementasi dari kelas dasar (untuk bergerak maju)
    EnemyBase::_physics_process(delta);

    // Tambahkan logika baru: berputar
    set_rotation(get_rotation() + rotation_speed * delta);
}

void SpinningEnemy::shoot() {
    // Implementasi shoot() yang benar-benar baru, sesuai GDScript Anda
    Ref<PackedScene> bullet_scene = get_bullet_scene();
    if (!bullet_scene.is_valid()) return;

    Node* muzzles = get_node_or_null("Muzzle"); // Asumsi nama node Muzzle sama
    if (!muzzles) return;

    for (int i = 0; i < muzzles->get_child_count(); ++i) {
        Marker2D* muzzle = Object::cast_to<Marker2D>(muzzles->get_child(i));
        if (muzzle) {
            Node* bullet_instance = bullet_scene->instantiate();
            get_parent()->add_child(bullet_instance);
            
            Node2D* bullet_2d = Object::cast_to<Node2D>(bullet_instance);
            if (bullet_2d) {
                bullet_2d->set_global_position(muzzle->get_global_position());

                Vector2 fire_direction = (muzzle->get_global_position() - get_global_position()).normalized();
                bullet_2d->set_rotation(fire_direction.angle() + Math_PI / 2.0);
            }
        }
    }
}

void SpinningEnemy::_on_body_entered(Node *body) {
    // Di GDScript, Anda tidak memanggil die() saat tabrakan
    if (body->is_in_group("player")) {
        body->call("take_damage", get_damage());
        // Tidak memanggil die() di sini, sesuai logika Anda
    }
}

void SpinningEnemy::set_rotation_speed(const float p_speed) { rotation_speed = p_speed; }
float SpinningEnemy::get_rotation_speed() const { return rotation_speed; }

} // namespace godot