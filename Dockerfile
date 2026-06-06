# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Philipp Schlemmer, einfach-online.dev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
FROM python:3.12-slim

LABEL org.opencontainers.image.title="Hermes Agent"
LABEL org.opencontainers.image.description="Autonomous AI agent by Nous Research"
LABEL org.opencontainers.image.url="https://github.com/nousresearch/hermes-agent"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Install Hermes Agent from PyPI
RUN pip install --no-cache-dir hermes-agent

# Create working directory
WORKDIR /data

# Expose Hermes API port and dashboard port
EXPOSE 8642 8641 9119

ENTRYPOINT ["hermes"]
CMD ["--help"]
