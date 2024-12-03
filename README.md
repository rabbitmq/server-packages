# Build Open Source RabbitMQ Packages on Actions

## What is This?

This repository contains Actions workflows that produce open source RabbitMQ releases. The goal of this
automation is to eventually produce alphas (development snapshots), betas (early previews of new feature releases),
release candidates and [signed GA releases](https://github.com/rabbitmq/rabbitmq-server/releases).

Continuously produced development builds (alphas in RabbitMQ parlance) can be found [on the Releases page](https://github.com/rabbitmq/rabbitmq-server/releases).

It has a sibling project, [`rabbitmq/erlang-packages`](https://github.com/rabbitmq/erlang-packages), which produces
Debian packages of Erlang and Elixir, as well as RPM packages of Erlang.


## Preview Releases (Alphas, Betas, RCs)

### Alphas

For every merge or push to `rabbitmq/rabbitmq-server` that involves code changes, a new alpha release build, tag and preview
release is produced and [published as a release](https://github.com/rabbitmq/server-packages/releases) in this repository.

Alpha builds are identified using a shortened commit SHA, for example, `4.1.0-alpha.af0d8206`.
Tags for alphas use a timestamp-based naming scheme. This helps keeps all releases chronologically
ordered on the [releases page](https://github.com/rabbitmq/server-packages/releases).

Alpha build artifacts are meant to be used for development, providing feedback on pull requests,
and so on.

Alpha builds are not published to Debian and RPM package repositories because it is arguably easier to
install a one-off package with `dpkg -i` than set up a repository.

Alpha build artifacts are signed.
Only a certain number alpha releases are retained.

### Betas

Beta releases are produced by manually triggering a [`4.1.x` Beta release workflow](https://github.com/rabbitmq/server-packages/actions/workflows/4.1.x-beta-release.yml).

Beta build artifacts are signed.

### Release Candates

RC releases are produced by manually triggering a [`4.1.x` RC release workflow](https://github.com/rabbitmq/server-packages/actions/workflows/4.1.x-rc-release.yml).

RC build artifacts are signed. They are also published to Debian and RPM repositories, primarily
as a way to test that code path before a final release is produced.


## Final (GA) Releases

GA releases, also called final releases, are meant for end user consumption.

They are signed, distributed via `rabbitmq/rabbitmq-server` releases and use the standard (for RabbitMQ)
tag structure.


## Build Environment Images

These workflows rely on a number of [OCI images built by the RabbitMQ Core Team](https://github.com/rabbitmq/build-env-images).

Currently all 4.1.x and 4.0.x workflows use an Erlang 26 image for most artifacts
and Erlang 27 for the "latest toolchain" variation of the generic binary build.


## Version Naming

Version naming is generally consistent and follows a long-established RabbitMQ tag
naming pattern. The only exception with this iteration of our release infrastructure
is alpha releases: instead of monotonically incrementing integers used for betas, RCs,
alphas use a short commit SHA, for example, `4.1.0-alpha.3e509c9f`.

The commit SHA refers to a commit in the main RabbitMQ server repository.

If an alpha build is triggered manually and there's no commit SHA to use, a different preview
identifier (such as a UNIX timestamp) can be used.


## Tag Naming

| Release type | Tag name pattern                 | Example              |
|--------------|----------------------------------|----------------------|
| alphas       | alphas.{timestamp}               | alphas.1731626175221 |
| betas        | {base}-beta.{preview_identifier} | 4.1.0-beta.1         |
| RCs          | {base}-rc.{preview_identifier}   | 4.1.0-rc.1           |
| final        | {base}                           | 4.0.4                |


## Workflow Structure

Team RabbitMQ maintains two release series. Currently they are 4.1.0 in `main` and 4.0.x on the `v4.0.x` branch.

With some exceptions covered below, for every series, there are workflow for producing alphas, betas, RCs and final releases.
They follow a naming convention, for example

 * `4.0.x-alpha-release`
 * `4.1.x-beta-release`
 * `4.1.x-rc-release`
 * `4.0.x-ga-release`

and so on.

These workflow have certain differences but most of their jobs and steps are very similar or identical.
Therefore, they use a reusable release workflow with different inputs.

Some workflows may be intentionally omitted, for example, betas are usually only produced for the release series
in development (`4.1.0` at the moment of writing) and not the current generally available release.

### Inputs

#### Series Branch

Defines the branch of source repositories (`rabbitmq/rabbitmq-server`, `rabbitmq/rabbitmq-packaging`) that will be
used during the build.

#### Base Version

Such as `4.1.0` or `4.0.4`. Usually this value will come from
a [repository-specific variable](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#creating-configuration-variables-for-a-repository).

This variable is meant to be updated as releases come out.

#### Prerelease

A boolean that tells the workflow that the release is a preview (an alpha, a beta or an RC)
and not a final release.

Produced GitHub releases will be marked accordingly.

#### Prerelease Kind

`alpha`, `beta` or `rc`

#### Prerelease Identifier

This is `1` in `4.1.0-beta.1` or `d46e83277` in `4.1.0-alpha.d46e83277`.

This value can be any string but for `alpha` builds, it usually will be a short commit SHA
in the RabbitMQ server repository, and for `beta` and `rc` builds, it will be a user-provided
monotonically increasing number.

#### Release Repository

A GitHub repository where a release will be created. For beta, RC and final releases, this typically
will be `rabbitmq/rabbitmq-server`.

For alphas, `rabbitmq/server-packages` (this repository) will be used instead to not pollute the
release history of a repository with thousands of visitors a month.

#### Release Title

What should the resulting GitHub release be entitled?

#### Release Description

Resulting GitHub release description.

For alphas, this will include a timestamp and a link to the commit message in the
RabbitMQ server repository.

For beta, RC and final releases, it makes more sense to use a release notes file.

#### Release Tag

What the Git tag should be used for this release?

For alpha builds, a timestamp-based tag such as `alphas.41x.{timestamp}` will be generated to preserve
more or less chronological ordering of releases even when they are built for multiple series.

#### GPG Signing of Releases

Should the produced release artifacts be GPG-signed?

Currently this is set to `true` for all release types.

#### Publish to Debian and RPM Repositories?

Should Debian and RPM packages be published to package repositories?

This primarily makes sense for RC and final releases but not betas and certainly not alphas.

#### Debian and RPM Repository Name

Allows you to override the repository and publish RCs separately from final releases.


### Primary Workflow Stages

A release build involves a few key operations:

1. Given a set of inputs, compute the version that should be used
2. Produce a source tarball
3. Build a generic binary package for Linux, macOS, BSD, and so on
4. In parallel, build Debian, RPM and two Windows packages (binary Windows build and a NSIS-based Windows installer and uninstaller)
5. Collect all artifacts and sign them
6. If necessary, publish Debian and RPM packages to external package repositories
7. Create a Git tag and a GitHub release with the produced artifacts and signatures


## Signing

Artifact signing keys are used at different steps:

1. When building a Debian package, by [`dpkg-buildpackage(1)`](https://man7.org/linux/man-pages/man1/dpkg-buildpackage.1.html). Given that
   on Debian-based systems, the `apt` toolchain works with repository signatures and not package signatures, this is of limited use
   for production deployments (where `dpkg -i` is virtually never used)
2. When building an RPM package. Practical usefulness is generally comparable to that of Debian packages
3. When building a Windows installer (and uninstaller), the signature is embedded using [`osslsigncode(1)`](https://github.com/mtrojnar/osslsigncode)
4. All artifacts collected for the release are signed with `gpg` and the resulting signatures (`.asc` files) are
   uploaded to the resulting GitHub release together with the actual packages

For steps 1 and 2, the key is loaded into a temporary GPG keychain. Then Debian and RPM tooling
fetches a key by ID from that keychain.

For steps 3 and 4, the signing key used comes from GitHub secrets and is stored on disk for only for
the relevant parts of the build.


## Package Testing

### Testing with Jepsen

A successfully built alpha release triggers a Jepsen workflow run
in a separate repository, [`rabbitmq/jepsen`](https://github.com/rabbitmq/jepsen).

### Package Tests

Team RabbitMQ's package tests (that is, they test Debian, RPM, Windows packages specifically
and not RabbitMQ per se) are not yet moved to this repository.


## License

This repository is released under the Mozilla Public License 2.0,
same as open source RabbitMQ.

SPDX-License-Identifier: MPL-2.0
