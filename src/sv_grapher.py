import re
import os
import argparse
from graphviz import Digraph

def strip_comments(text):
    """
    Removes C-style comments from a string to simplify parsing.
    """
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    text = re.sub(r'//.*', '', text)
    return text

def tokenize_verilog(code):
    tokens = []
    # Key changes:
    # 1. Added '#' to the list of operators/symbols to capture it individually if not part of '#('
    # 2. Added '#\(' to capture '#(' as a single token for parameter overrides
    # 3. Updated identifier pattern `[a-zA-Z_]\w*` to `[a-zA-Z_][a-zA-Z0-9_$]*` to include '$'
    token_pattern = re.compile(
        r'\b(?:module|endmodule|input|output|logic|assign|always_ff|always_comb|if|else|case|endcase|for|int|posedge|or|default|begin|end|generate|genvar)\b|' # Added 'generate' and 'genvar' keywords
        r'#\(|' # Capture '#(' as a single token for parameter overrides
        r'[a-zA-Z_][a-zA-Z0-9_$]*|' # Verilog identifiers (includes $)
        r'\d+\'?[bdhBHD][0-9a-fA-F_]+|\d+|' # Numbers
        r'[{}()\[\].,;:=*/+-]|<=|==|!=|<|>|&&|\|\||~&|~\||\'\w|`\w+|:' # Operators and symbols
    )

    lines = code.split('\n')
    for line in lines:
        cleaned_line = strip_comments(line).strip()
        if not cleaned_line:
            continue

        matches = token_pattern.finditer(cleaned_line)
        for match in matches:
            token = match.group(0)
            cleaned_token = token.strip()
            if cleaned_token:
                tokens.append(cleaned_token)
    return tokens



def parse_verilog_no_regex(file_path):
    """
    Parses a SystemVerilog file to find module definitions and instantiations
    using a token-based approach.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File not found at {file_path}")
        return {}
    except Exception as e:
        print(f"Error reading file: {e}")
        return {}

    content = content.replace(u'\xa0', ' ')
    content = strip_comments(content)
    tokens = tokenize_verilog(content)

    module_hierarchy = {}
    defined_modules = set()
    
    # --- Pass 1: Identify all module definitions ---
    i = 0
    while i < len(tokens):
        if tokens[i] == 'module':
            print(tokens[1+i])
            if i + 1 < len(tokens):
                module_name = tokens[i+1]
                defined_modules.add(module_name)
                # Initialize module in hierarchy even if it has no children
                if module_name not in module_hierarchy:
                    module_hierarchy[module_name] = []
                i += 1
        i += 1

    print(f"DEBUG: Defined modules (Pass 1): {defined_modules}") # DEBUG PRINT

    # --- Pass 2: Find instantiations within module blocks ---
    i = 0
    current_module = None
    while i < len(tokens):
        if tokens[i] == 'module':
            #print(tokens[1+i])
            if i + 1 < len(tokens):
                current_module = tokens[i+1]

                # Now 'i' is at the start of the module's body
                while i < len(tokens) and tokens[i] != 'endmodule':
                    is_potential_instantiation = False
                    # Look for potential instantiations: ModuleType InstanceName (
                    # The ModuleType must be one of our defined_modules.
                    
                    # Check if the current token is a defined module name
                    # and the next token is an alphanumeric identifier (instance name)
                    # and the token after that is an opening parenthesis
                    def is_verilog_identifier(s):
                        return re.fullmatch(r'[a-zA-Z_]\w*', s) is not None

                    if (tokens[i] in defined_modules and
                        i + 1 < len(tokens) and is_verilog_identifier(tokens[i+1]) and # <--- CHANGE IS HERE
                        i + 2 < len(tokens) and tokens[i+2] == '('):
                        is_potential_instantiation = True

                    if (tokens[i] in defined_modules and
                        i + 1 < len(tokens) and tokens[i+1] == '#('):
                        is_potential_instantiation = True

                    if is_potential_instantiation:
                        potential_instance_type = tokens[i]
                                                
                        if current_module and potential_instance_type != current_module:
                            if potential_instance_type not in module_hierarchy[current_module]:
                                module_hierarchy[current_module].append(potential_instance_type)                        
                    
                    # If not an instantiation, just move to the next token
                    i += 1
            
            # If we exited the inner loop because of 'endmodule', update global index
            if i < len(tokens) and tokens[i] == 'endmodule':
                i += 1
            current_module = None # Reset current module context
        else:
            i += 1 # Move to next token if not 'module'

    # Ensure all defined modules are in the hierarchy dictionary, even if they have no children
    for mod in defined_modules:
        if mod not in module_hierarchy:
            module_hierarchy[mod] = []

    return module_hierarchy

def generate_dot_graph(module_hierarchy, output_file='module_graph.dot'):
    """
    Generates a .dot file from the module hierarchy.
    """
    dot = Digraph(comment='SystemVerilog Module Hierarchy')
    dot.attr('node', shape='box', style='rounded', fontname='Helvetica')
    dot.attr('edge', fontname='Helvetica')
    dot.attr(rankdir='TB', splines='ortho')

    all_modules = set(module_hierarchy.keys())
    for children in module_hierarchy.values():
        for child in children:
            all_modules.add(child)

    for module in all_modules:
        dot.node(module, module)

    for parent_module, child_modules in module_hierarchy.items():
        if child_modules:
            for child_module in set(child_modules): # Use set to avoid duplicate edges
                dot.edge(parent_module, child_module)

    try:
        dot.render(output_file, view=False, format='dot')
        print(f"Successfully generated DOT graph: {output_file}.dot")
    except Exception as e:
        print(f"Error generating DOT file: {e}")
        print(f"Please ensure Graphviz is installed and in your system's PATH.")
        print(f"   (e.g., on Ubuntu: sudo apt-get install graphviz)")
        print(f"   (e.g., on macOS: brew install graphviz)")
        print(f"   (e.g., on Windows: install from graphviz.org and add to PATH)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate a .dot graph from SystemVerilog module hierarchy."
    )
    parser.add_argument("input_file", help="Path to the SystemVerilog source file.")
    parser.add_argument(
        "-o", "--output",
        default="sv_graph",
        help="Name of the output .dot file (without extension)."
    )
    args = parser.parse_args()

    if os.path.exists(args.input_file):
        hierarchy = parse_verilog_no_regex(args.input_file)
        if hierarchy:
            generate_dot_graph(hierarchy, args.output)
        else:
            print("No module hierarchy found or an error occurred.")
    else:
        print(f"Error: Input file '{args.input_file}' not found.")