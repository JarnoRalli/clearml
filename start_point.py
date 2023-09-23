import sys
import os
from clearml import Task

task: Task = Task.init(project_name="Docker", task_name="test", output_uri=True)

print("--- BEGIN start_point.py ---")

# Check which Python executable is being used
print(f'Python executable: {sys.executable}')

# Check if torch_geometric can be imported
try:
    import torch_geometric
    print('import torch_geometric: OK')
except Exception as e:
    print(f'import torch_geometric: failed -> {e}')

# Check if torch_scatter can be imported
try:
    import torch_scatter
    print('import torch_scatter: OK')
except Exception as e:
    print(f'import torch_scatter: failed -> {e}')

# Print all the environment variables
print(os.environ)

print("--- END start_point.py ---")
