# CVAT v2.82.0 (open source)

`scripts/setup.sh` clones https://github.com/cvat-ai/cvat at the tag `v2.82.0` into `docker/cvat`
and starts it with that repository's own `docker-compose.yml`. Nothing here is modified.

- Start: `scripts/setup.sh` (safe to run again)
- Stop, keep data: `scripts/stop.sh`
- Stop and delete all CVAT data: `scripts/stop.sh --delete`

CVAT is MIT licensed. Its install guide: https://docs.cvat.ai/docs/administration/basics/installation/
