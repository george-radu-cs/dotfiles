# For VSCode add this in Include Path

```C
${workspaceFolder}/**
/usr/include/wx-3.0
/usr/lib/x86_64-linux-gnu/wx
/usr/local/lib/wx
/usr/lib/x86_64-linux-gnu/wx/include/gtk3-unicode-3.0
/usr/lib/x86_64-linux-gnu/wx/include/base-unicode-3.0

```

# Create a file named *CMakeLists.txt*

```C
cmake_minimum_required(VERSION 3.0)

project("PROGRAM_NAME")

add_executable("PROGRAM_NAME" "PROGRAM_NAME.cpp")
target_compile_features(PROGRAM_NAME PRIVATE cxx_lambda_init_captures)

find_package(wxWidgets REQUIRED COMPONENTS net core base)
include(${wxWidgets_USE_FILE})
target_link_libraries(PROGRAM_NAME ${wxWidgets_LIBRARIES})

```
