# Use an official image as a base
FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Install system dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nano wget gcc g++ libarchive-dev python3 python3-pip python3-dev libgeos-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /miniconda && \
    rm miniconda.sh

# Add Miniconda to PATH
ENV PATH="${PATH}:/miniconda/bin"

# Install mamba solver
RUN conda install -n base -c conda-forge mamba -y && \
    conda config --set solver libmamba

# Copy the conda environment definition file
COPY gnn.yml .

# Create the Conda environment
RUN conda env create -f gnn.yml

# Cleanup to reduce image size
RUN conda clean -a -y

# Copy the Python file
COPY start_point.py .

# Let's make sure that these are definitely set in the container
ENV CLEARML_AGENT_SKIP_PIP_VENV_INSTALL="/miniconda/envs/gnn/bin/python"
ENV CLEARML_AGENT_SKIP_PYTHON_ENV_INSTALL="1"

# Activate the gnn environment when starting a container
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "gnn"]
