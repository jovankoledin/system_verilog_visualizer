'''
Python script that reads a SystemVerilog file and 
generates a dataflow graph that shows its architecture
'''

import pyverilog.vparser.ast as vast
from pyverilog.vparser.parser import parse
from graphviz import Digraph
import argparse # Import the argparse module

def system_verilog_visualizer(file_path):
    # Parse the SystemVerilog file
    ast, directives = parse([file_path])

    dot = Digraph(comment='CGRA Module Hierarchy', format='svg')
    dot.attr(rankdir='TB') # Top-to-Bottom layout

    # Dictionary to store module definitions
    modules = {}

    # Traverse the AST to find module definitions
    for module in ast.description.definitions:
        if isinstance(module, vast.ModuleDef):
            module_name = module.name
            modules[module_name] = module
            dot.node(module_name, module_name, shape='box') # Add module as a node

    # Traverse again to find module instantiations and add edges
    for module_name, module_def in modules.items():
        for item in module_def.items:
            if isinstance(item, vast.InstanceList):
                for instance in item.instances:
                    instantiated_module_type = instance.module
                    if instantiated_module_type in modules:
                        dot.edge(module_name, instantiated_module_type)
                    else:
                        print(f"Warning: Module '{instantiated_module_type}' instantiated but not defined in provided files.")

    # Render the graph
    dot.render('cgra_module_hierarchy', view=True) # Renders to cgra_module_hierarchy.svg and opens it

if __name__ == "__main__": 
    # Create the parser
    parser = argparse.ArgumentParser(description='Generate a dataflow graph from a SystemVerilog file.')
    parser.add_argument('file_path', type=str, 
                        help='The path to the SystemVerilog file (e.g., ./example_code_inputs/serdes.sv)')
    args = parser.parse_args()

    # Call the function with the provided file path
    system_verilog_visualizer(args.file_path)