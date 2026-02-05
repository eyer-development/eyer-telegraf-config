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
| `x.y.z`         | Specific release versions (e.g., `1.2.3`). Derived from Git tags like `v1.2.3` (the `v` is stripped). | **Version-specific deployment**, recommended for reproducibility and stability. |

## Deploying a New Version

Docker images are built and pushed by GitHub Actions

1. Merge your changes into `master`
2. Choose the release tag name (example: `v1.2.3`).
3. Create/push the tag via GitHub Actions:
   - GitHub UI: run workflow `Create & Push Tag (release)` (`.github/workflows/push-version-tag.yml`) and provide `tag_name`.
5. Verify published tags on Docker Hub:
   - Always updated: `eyerai/eyerdocker:master`
   - For version tags: `vX.Y.Z` => `eyerai/eyerdocker:X.Y.Z` and `eyerai/eyerdocker:latest`
