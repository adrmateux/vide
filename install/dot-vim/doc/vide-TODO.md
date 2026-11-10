# Improve vide shortcuts
Currently, in vim+vide+plugins, shortcuts are defined:
  - across several vide files. User defines the desired mapping anywhere.
  - to see mapping: map, nmap, ...
    - the gold standard are VSCode and Intellij's IDEA

Implement function(s) where:
  - The user gives/passes:
    - brief text (limited to 40 chars)
    - desired mapping
    - mode (normal,insert, etc)
  - The function shall:
    - register mapping and brief text to the help
    - create a file with the commands to create the mapping
    - create a file to unregister the mappings

# Improve help
Currently you have:
  - :help
  - Ctrl+F1 
