cmake_minimum_required(VERSION 3.20)
project(local_rag_cpp)

set(CMAKE_CXX_STANDARD 20)

find_package(nlohmann_json CONFIG REQUIRED)

add_executable(local_rag
  src/main.cpp
)
target_link_libraries(local_rag
  PRIVATE nlohmann_json::nlohmann_json
)

