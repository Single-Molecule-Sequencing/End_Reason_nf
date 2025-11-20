FROM mambaorg/micromamba:1.5.8

# Set working directory
WORKDIR /app

# Copy conda environment file
COPY envs/tagger.yaml /tmp/env.yaml

# Install dependencies using micromamba
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes

# Activate conda environment
ENV PATH="/opt/conda/bin:${PATH}"

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV CONDA_DEFAULT_ENV=base

# Verify installations
RUN python --version && \
    samtools --version && \
    python -c "import pysam; import pod5; import pandas; print('All packages installed successfully')"

# Set entrypoint
CMD ["/bin/bash"]
