# ClearML

##  ClearML Agent 1.6.1 Environment Variables Bug in Docker

ClearML's [documentation](https://clear.ml/docs/latest/docs/clearml_agent/clearml_agent_env_var/) mentions that creation of a new venv, and
which Python interpreter is used to execute the tests, can be controlled with following environment variables:

| Name                                  | Description                                                                                          |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| CLEARML_AGENT_SKIP_PIP_VENV_INSTALL   | Skips Python virtual env installation on execute and provides a custom venv binary                   |
| CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL | Skips entire Python venv installation and assumes python as well as every dependency is preinstalled |

Expected behaviour is that if we create a Docker image, which has a Conda virtual environment, we can use the above environment variables
to instruct clearml-agent to use the Python interpreter set by `CLEARML_AGENT_SKIP_PIP_VENV_INSTALL`. Currently this does not appear to be working as expected.

### Local Test

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

### ClearML Agent without Docker

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

### ClearML Agent with Docker

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
clearml-agent daemon --docker clearml-runner --queue "docker" --foreground --log-level DEBUG
```

, we now have the agent listening to a queue called `docker`. Next we clone the task in the ClearML UI, and launch it. Following is the error message that we get:

```bash
/miniconda/bin/python3.11: can't open file '/root/.clearml/venvs-builds/task_repository/clearml.git/start_point.py': [Errno 2] No such file or directory
```

As we can see from the error message, clearml-agent is trying to use the Python interpreter `/miniconda/bin/python3.11`, 
instead of the one it was instructed to use which is `/miniconda/envs/gnn/bin/python`.
