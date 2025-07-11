python src/sv_grapher.py inputs/stress.sv -o build/sv_graph
dot -Tpng build/sv_graph.dot -o build/sv_graph.png
xdg-open build/sv_graph.png