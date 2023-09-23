# 1 ClearML

##  1.0 ClearML Agent 1.6.1, Conflicting Environment Variables

ClearML's [documentation](https://clear.ml/docs/latest/docs/clearml_agent/clearml_agent_env_var/) mentions that creation of a new venv, and
which Python interpreter is used to execute the tests, can be controlled with following environment variables:

| Name                                  | Description                                                                                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| CLEARML_AGENT_SKIP_PIP_VENV_INSTALL   | Skips Python virtual env installation on execute and provides a custom venv binary                   |
| CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL | Skips entire Python venv installation and assumes python as well as every dependency is preinstalled |

Expected behaviour is that if we create a Docker image, which has a Conda virtual environment, we can use the above environment variables
to instruct clearml-agent to use the Python interpreter set by `CLEARML_AGENT_SKIP_PIP_VENV_INSTALL`. The documentation doesn't state clearly
what is the expected behaviour if both of the environment variables are set.

### 1.0.0 Local Test

Testing environment:
* Ubuntu 20.04
* Driver Version: 525.125.06
* CUDA version: 11.7

We create a Conda environment (you first need to install and activate miniconda), activate the environment and execute the Python code.

```bash
conda env create -f gnn.yml
conda activate gnn
python start_point.py
```

Output is as follows:

```bash
ClearML Task: created new task id=<TASK ID HERE>
ClearML results page: <RESULTS PAGE HERE>
--- BEGIN start_point.py ---
Python executable: /home/jarno/miniconda3/envs/gnn/bin/python
import torch_geometric: OK
import torch_scatter: OK
# A list of environment variables
--- END start_point.py ---
```

As we can see, above Python code created a task in Clearml. Next step is running the docker-agent on the local machine, with Docker image.

### 1.0.1 ClearML Agent without Docker

Testing environment:
* Ubuntu 20.04
* Driver Version: 525.125.06
* CUDA version: 11.7

Before starting the clearml-agent, we export the environment variables. Expectation here is that the agent would not be able to execute the test successfully,
as we have set the Python intepreter to point to the location that exists in the Docker image.

```bash
export CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL=1
export CLEARML_AGENT_SKIP_PIP_VENV_INSTALL=/miniconda/envs/gnn/bin/python
conda activate clearml
clearml-agent daemon --queue "docker" --foreground --log-level DEBUG
```

, we now have the agent listening to a queue called `docker`. Next we clone the task in the ClearML UI, and launch it. Output is as follows:

```bash
--- BEGIN start_point.py ---
Python executable: /home/jarno/miniconda3/envs/clearml/bin/python
import torch_geometric: failed -> No module named 'torch_geometric'
import torch_scatter: failed -> No module named 'torch_scatter'
# A list of environment variables
--- END start_point.py ---
```

Environment variables are as follows:

```bash
env | grep CLEARML
CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL=1
CLEARML_AGENT_SKIP_PIP_VENV_INSTALL=/miniconda/envs/gnn/bin/python
```

As we can see, clearml-agent is picking the Python interpreter that is defined in the active Conda environment and not the one defined by `CLEARML_AGENT_SKIP_PIP_VENV_INSTALL`.

### 1.0.2 ClearML Agent with Docker

Testing environment:
* Ubuntu 20.04
* Driver Version: 525.125.06
* CUDA version: 11.7

Before running this part, you need to install docker and Nvidia docker toolkit, and make sure that CUDA works in the docker. In this test
we run the task, creating when running the local test, from the ClearML UI. Before starting the clearml-agent, we export the environment variables as the documentation
isn't 100% clear regarding whether these should be set in the machine where the clearml-agent is started from, or inside the Docker container, 
so we set these in both.

```bash
export CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL=1
export CLEARML_AGENT_SKIP_PIP_VENV_INSTALL=/miniconda/envs/gnn/bin/python
docker build -t clearml-runner .
clearml-agent daemon --docker clearml-runner --queue "docker" --foreground --log-level DEBUG
```

, we now have the agent listening to a queue called `docker`. Next we clone the task in the ClearML UI, and launch it. Following is the error message that we get:

```bash
/miniconda/bin/python3.11: can't open file '/root/.clearml/venvs-builds/task_repository/clearml.git/start_point.py': [Errno 2] No such file or directory
```

As we can see from the error message, clearml-agent is trying to use the Python interpreter `/miniconda/bin/python3.11`, 
instead of the one it was instructed to use which is `/miniconda/envs/gnn/bin/python`.

## 1.1 ClearML Agent 1.6.1, Docker with Conda

Setting the environment variable `CLEARML_AGENT_SKIP_PIP_VENV_INSTALL` to a Conda installed Python interpreter inside the Docker image seems to work, at least
if the Python packages are installed using pip and not conda dependencies.

| Name                                  | Description                                                                                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| CLEARML_AGENT_SKIP_PIP_VENV_INSTALL   | Skips Python virtual env installation on execute and provides a custom venv binary                   |

Example of a Conda environment file that uses pip to install:
* torch
* torchvision
* torch_geometric
* torch-scatter
* torch-sparse

, using CUDA 11.7.

```
name: gnn
channels:
  - conda-forge
dependencies:
  - python=3.10
  - pip
  - pip:
    - --find-links https://download.pytorch.org/whl/cu117/torch-2.0.1%2Bcu117-cp310-cp310-linux_x86_64.whl
    - --find-links https://download.pytorch.org/whl/cu117/torchvision-0.15.2%2Bcu117-cp310-cp310-linux_x86_64.whl
    - --find-links https://pytorch-geometric.com/whl/torch-2.0.1%2Bcu117.html
    - --find-links https://data.pyg.org/whl/torch-2.0.1%2Bcu117.html
    - tensorboard
    - numba
    - torch==2.0.1
    - torchvision==0.15.2
    - torch_geometric==2.0.1
    - torch-scatter
    - torch-sparse
    - clearml
    - clearml-agent
    - cartopy
    - pyproj
```

### 1.1.0 Local Test

Testing environment:
* Ubuntu 20.04
* Driver Version: 525.125.06
* CUDA version: 11.7

We create a Conda environment (you first need to install and activate miniconda), activate the environment and execute the Python code.

```bash
conda env create -f gnn.yml
conda activate gnn
python start_point.py
```

Output is as follows:

```bash
ClearML Task: created new task id=<TASK ID HERE>
ClearML results page: <RESULTS PAGE HERE>
--- BEGIN start_point.py ---
Python executable: /home/jarno/miniconda3/envs/gnn/bin/python
import torch_geometric: OK
import torch_scatter: OK
# A list of environment variables
--- END start_point.py ---
```

### 1.1.1 ClearML Agent with Docker

Testing environment:
* Ubuntu 20.04
* Driver Version: 525.125.06
* CUDA version: 11.7

Before running this part, you need to install docker and Nvidia docker toolkit, and make sure that CUDA works in the docker.

```bash
export CLEARML_AGENT_SKIP_PIP_VENV_INSTALL=/miniconda/envs/gnn/bin/python
docker build -t clearml-runner .
clearml-agent daemon --docker clearml-runner --queue "docker" --foreground --log-level DEBUG
```

, we now have the agent listening to a queue called `docker`. Next we clone the task in the ClearML UI, and launch it. Output is as follows:

```bash
--- BEGIN start_point.py ---
Python executable: /miniconda/envs/gnn/bin/python3.10
import torch_geometric: OK
import torch_scatter: OK
# A list of environment variables
--- END start_point.py ---
```
