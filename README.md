# Docker Container Versioning

Docker images are hosted at: [eyerai/eyerdocker](https://hub.docker.com/r/eyerai/eyerdocker)

[![Docker Pulls](https://img.shields.io/docker/pulls/eyerai/eyerdocker.svg)](https://hub.docker.com/r/eyerai/eyerdocker/)
[![Docker Image Version (latest)](https://img.shields.io/docker/v/eyerai/eyerdocker/latest)](https://hub.docker.com/r/eyerai/eyerdocker/)
[![Docker Image Size (latest)](https://img.shields.io/docker/image-size/eyerai/eyerdocker/latest)](https://hub.docker.com/r/eyerai/eyerdocker/)

## Available Tags

The following tagging scheme is used for managing container versions:

| Tag             | Description                                                  | Usage Recommendation                   |
|-----------------|--------------------------------------------------------------|----------------------------------------|
| `latest`        | Points to the most recent stable release version.            | **Production-ready**, regularly updated with tested releases. |
| `master`        | Represents the latest build from the master branch.          | **Development/testing**, potentially unstable or experimental changes. |
| `x.x`           | Specific release versions (e.g., `1.1`, `2.0`). Correspond directly to tagged releases on GitHub. | **Version-specific deployment**, recommended for reproducibility and stability. |
