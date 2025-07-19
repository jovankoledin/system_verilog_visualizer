python src/sv_grapher.py inputs/CgraRTL_vectorcgra.v -o build/sv_graph
dot -Tpng build/sv_graph.dot -o build/sv_graph.png
xdg-open build/sv_graph.png