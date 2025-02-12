# Development

This document outlines development workflows for CTL itself. You may also wish to read our documentation on CTL's [runtime dependencies](./runtime.md), which are a prerequisite for most development.

**Table of Contents**

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Nix environment](#nix-environment)
- [Launching services for development](#launching-services-for-development)
- [Building, testing, and running the PS project](#building-testing-and-running-the-ps-project)
- [Generating PS documentation](#generating-ps-documentation)
- [Adding PS/JS dependencies](#adding-psjs-dependencies)
  - [Purescript](#purescript)
  - [JS](#js)
- [Switching development networks](#switching-development-networks)
- [Maintaining the template](#maintaining-the-template)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Nix environment

This project uses Nix flakes. In order to use flakes, you will need Nix version 2.4 or greater. You also need to enable additional experimental features. Make sure you have the following enabled in your `nix.conf` (typically located in `/etc/nix/` or `~/.config/nix/`) or in `nix.extraOptions` in your NixOS configuration:

```
experimental-features = nix-command flakes
```

You may also choose to enable these every time you use `nix` commands (and without modifying your `nix.conf`) by passing the following command-line options:

```
nix <COMMAND> --extra-experimental-features nix-command --extra-experimental-features flakes
```

Running `nix develop` in the root of the repository will place you in a development environment with all of the necessary executables, tools, config, etc... to:

- build the project or use the repl with `spago`
- use `npm` and related commands; all of the project's JS dependencies are symlinked from the Nix store into `node_modules` in the repository root
- use Ogmios and other tools with the correct configurations, socket path, etc... These are also set in the `devShell`'s `shellHook`

**NOTE**: As the Nix `devShell` currently symlinks the project's `node_modules`, **do not** use `npm install` in order to develop with `npm`. Use `nix develop` as noted above

## Launching services for development

To develop locally, you can use one the CTL flake to launch all required services (using default configuration values):

- The easiest way: `nix run -L .#ctl-runtime` will both build and run the services
- The same, but indirectly in your shell:
  ```
  $ nix build -L .#ctl-runtime
  $ arion --prebuilt-file ./result up
  ```

## Building, testing, and running the PS project

- To build the project **without bundling and for a NodeJS environment**:
  - `nix build` _or_
  - `spago build`
- To test the project, currently only supported when running in a NodeJS environment:
  - Use `npm run test`, or, if you need to test some specific functionality:
    - `npm run unit-test` for unit tests
    - `npm run integration-test` for integration tests (requires ctl-runtime running)
    - `npm run plutip-test` for Plutip integration tests (does not require ctl-runtime)
  - `nix build .#checks.<SYSTEM>.ctl-unit-test` will build and run the unit tests (useful for CI)
- To run or build/bundle the project for the browser:
  - `make run-dev` _or_ `npm run dev` will start a Webpack development server at `localhost:4008`
  - `make run-build` _or_ `npm run build` will output a Webpack-bundled example module to `dist`
  - `nix build -L .#ctl-example-bundle-web` will build an example module using Nix and Webpack

By default, Webpack will build a [small Purescript example](../examples/Pkh2Pkh.purs). Make sure to follow the [instructions for setting up Nami](./runtime.md#other-requirements) before running the examples. You can point Webpack to another Purescript entrypoint by changing the `ps-bundle` variable in the Makefile or in the `main` argument in the flake's `packages.ctl-examples-bundle-web`.

**Note**: The `BROWSER_RUNTIME` environment variable must be set to `1` in order to build/bundle the project properly for the browser (e.g. `BROWSER_RUNTIME=1 webpack ...`). For Node environments, leave this variable unset or set it to `0`.

**Note**: The `KUPO_HOST` environment variable must be set the base URL of the Kupo service in order to successfully run the project for the browser (e.g. `KUPO_HOST=http://localhost:1442`), otherwise all requests to Kupo will fail.

## Generating PS documentation

CTL PureScript docs are publicly deployed [here](https://plutonomicon.github.io/cardano-transaction-lib/).

- To build the documentation as HTML:
  - `spago docs`
- To build and open the documentation in your browser:
  - `spago docs --open`
- To build the documentation as Markdown:
  - `spago docs --format markdown`

The documentation will be generated in the `./generated_docs/html` directory, which contains an `index.html` which lists all modules by default. At this index is a checkbox to toggle viewing by package, and all the modules defined in our package will be available under `cardano-transaction-lib`.

Alternatively, you can view the documentation with `nix run -L .#docs` and opening `localhost:8080` in your browser. `nix build -L .#docs` will produce a `result` folder containing the documentation.

## Adding PS/JS dependencies

### Purescript

Unfortunately, we rely on `spago2nix`, which requires autogenerated Nix code (`spago-packages.nix`). This means that it is possible for our declared Purescript dependencies to drift from the autogen Nix code we import in to build Purescript derivations. If you add either a Purescript dependency, make sure to run `spago2nix generate` from within the Nix shell to update the autogen code from `spago2nix`. Do **not** edit `spago-packages.nix` by hand, or the build will likely break.

Don't forget to update the [template `packages.dhall`](../templates/ctl-scaffold/packages.dhall) to use the exact same versions.

### JS

If you add a dependency to `package.json`, make sure to update the lockfile with `npm i --package-lock-only` _before_ entering a new dev shell, otherwise the `shellHook` will fail. You'll need to remove the existing symlinked `node_modules` to do this (for some reason `npm` will _still_ try to write to the `node_modules`, but will fail because they're symlinked to the Nix store).

Don't forget to update the [template `package.json`](../templates/ctl-scaffold/package.json) to use the exact same versions, and then make sure the [`package-lock.json` file](../templates/ctl-scaffold/package-lock.json) is updates as well.

## Switching development networks

Set new `network.name` and `network.magic` in `runtime.nix`. Point `datumCache.blockFetcher.firstBlock` to a correct block/slot. Also see [Changing network configurations](./runtime.md#changing-network-configurations)

## Maintaining the template

[The template](../templates/ctl-scaffold/) must be kept up-to-date with the repo. Although there are some checks for common problems in CI, it's still possible to forget to update the `package-lock.json` file.

[This helper script](../scripts/template-check.sh) can be used to make sure the template can be initialized properly from a given revision.
