#ifndef SPINNING_ENEMY_H
#define SPINNING_ENEMY_H

#pragma once
#include "enemies/EnemyBase.h"

namespace godot {

class SpinningEnemy : public EnemyBase {
    GDCLASS(SpinningEnemy, EnemyBase)

private:
    float rotation_speed = 1.2;

protected:
    static void _bind_methods();

public:
    SpinningEnemy();
    ~SpinningEnemy();

    // Override fungsi dari EnemyBase
    void _physics_process(double delta) override;
    void shoot() override;
    void _on_body_entered(Node* body) override;

    // Getter & Setter untuk properti baru
    void set_rotation_speed(const float p_speed);
    float get_rotation_speed() const;
};

} // namespace godot

#endif // SPINNING_ENEMY_H