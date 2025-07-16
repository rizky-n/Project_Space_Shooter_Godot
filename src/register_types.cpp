#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

#include "enemies/EnemyBase.h"
#include "enemies/spinning_enemy.h"
#include "enemies/tanker_enemy.h"

using namespace godot;

void initialize_space_shooter_module(ModuleInitializationLevel p_level)
{
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE)
    {
        return;
    }

    ClassDB::register_class<EnemyBase>();
    ClassDB::register_class<SpinningEnemy>();
    ClassDB::register_class<TankerEnemy>();
}

void space_shooter_library_terminate(ModuleInitializationLevel p_level)
{
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE)
    {
        return;
    }
    // Add cleanup code here if needed
}

extern "C"
{
    // Initialization.
    GDExtensionBool GDE_EXPORT space_shooter_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
    {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

        init_obj.register_initializer(initialize_space_shooter_module);

        // VVV PASTIKAN BARIS INI MENGGUNAKAN NAMA FUNGSI YANG BENAR VVV
        init_obj.register_terminator(space_shooter_library_terminate);

        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

        return init_obj.init();
    }
}