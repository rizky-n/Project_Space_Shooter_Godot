#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# Add source path
env.Append(CPPPATH=["src/"])

# Explicitly list all cpp files
sources = []
sources += Glob("src/*.cpp")  # Files in src/
sources += Glob("src/**/*.cpp")  # Files in subdirectories

print("Found sources:", [str(s) for s in sources])  # Debug print

# Output to demo/bin/ folder
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "demo/bin/libgdexample.{}.{}.framework/libgdexample.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "demo/bin/libgdexample.{}.{}.{}{}".format(
            env["platform"], env["target"], env["arch"], env["SHLIBSUFFIX"]
        ),
        source=sources,
    )

Default(library)