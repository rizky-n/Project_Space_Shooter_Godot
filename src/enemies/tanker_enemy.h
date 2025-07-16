#ifndef TANKER_ENEMY_H
#define TANKER_ENEMY_H

#pragma once
#include "enemies/EnemyBase.h"

namespace godot {

class TankerEnemy : public EnemyBase {
    GDCLASS(TankerEnemy, EnemyBase)

private:
    float collision_damage = 40.0;

protected:
    bool is_dying = false; 

    // Wajib ada untuk mendaftarkan method dan properti ke Godot
    static void _bind_methods();

public:
    TankerEnemy();
    ~TankerEnemy();

    // Override fungsi dari EnemyBase
    void shoot() override;
    void _on_body_entered(Node* body) override;

    // Getter & Setter
    void set_collision_damage(const float p_damage);
    float get_collision_damage() const;
};

} // namespace godot

#endif // TANKER_ENEMY_H