# Build Open Source RabbitMQ Packages on Actions

## Disclaimer

This subproject is very new. Things can break, documentation will be lacking,
design decisions will be revisited, and so on. Please do not rely on this repository
unless you plan to regularly contribute to RabbitMQ and have consulted with the RabbitMQ Core Team.

## What is This?

This repository contains Actions workflows that produce open source RabbitMQ releases. The goal of this
automation is to eventually produce alphas (development snapshots), betas (early previews of new feature releases),
release candidates and [signed GA releases](https://github.com/rabbitmq/rabbitmq-server/releases).

It has a sibling project, [`rabbitmq/erlang-packages`](https://github.com/rabbitmq/erlang-packages), which produces
Debian packages of Erlang and Elixir, and, in case of Erlang, RPM packages.


## Preview Releases (Alphas, Betas, RCs)

### Alphas

For every merge or push to `rabbitmq/rabbitmq-server` that involves code changes, a new alpha release build, tag and preview
release is produced and [published as a release](https://github.com/rabbitmq/server-packages/releases) in this repository.

Alpha builds are identified using a shortened commit SHA, for example, `4.1.0-alpha.af0d8206`.
Tags for alphas use a timestamp-based naming scheme. This helps keeps all releases chronologically
ordered on the [releases page](https://github.com/rabbitmq/server-packages/releases).

Only ten alpha releases are retained.

Alpha build artifacts are meant to be used for development, providing feedback on pull requests,
and so on.

### Betas

Beta releases are produced by manually triggering a [`4.1.x` Beta release workflow](https://github.com/rabbitmq/server-packages/actions/workflows/4.1.x-beta-release.yml).

Beta build artifacts are not currently signed but they will eventually be.

### Release Candates

RC releases are produced by manually triggering a [`4.1.x` RC release workflow](https://github.com/rabbitmq/server-packages/actions/workflows/4.1.x-rc-release.yml).

RC build artifacts are not currently signed but they will eventually be.


## License

This repository is released under the Mozilla Public License 2.0,
same as open source RabbitMQ.
