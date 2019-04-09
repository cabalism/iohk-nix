# IOHK Common Nix Code

This repo contains build code and tools shared between IOHK projects.

1. Pinned versions of [input-output-hk/nixpkgs](https://github.com/input-output-hk/nixpkgs).
2. [Haskell.nix](https://github.com/input-output-hk/haskell.nix) and
   `nix-tools`, plus package overlays and patches for cross-compiling to
   Windows.
3. Scripts for regenerating code with `nix-tools`.
4. Util functions such as source filtering.
5. Nix builds of development tools such as HLint, ShellCheck, Stylish Haskell, SHC, cache-s3.
6. Nix packages and overlay for the [rust-cardano](https://github.com/input-output-hk/rust-cardano)
   projects.

## How to use in your project

Use `iohk-nix` by "pinning" its git revision and source hash in a JSON
file. Then use iohk-nix to get nixpkgs. This is usually done with the
default arguments to `default.nix`. For example:

```nix
# default.nix
{ config ? {}
, system ? builtins.currentSystem
, iohkLib ? import ./nix/iohk-common.nix { inherit config system; }
, pkgs ? iohkLib.pkgs
}:

{
  # your builds go here
}
```

The `config` and `system` arguments above are needed when building for
other systems. They have default values, and should be passed through
to `iohk-nix`.

Now set up `./nix/iohk-common.nix`, which is pure boilerplate:

```nix
let
  spec = builtins.fromJSON (builtins.readFile ./iohk-nix.json);
in import (builtins.fetchTarball {
  url = "${spec.url}/archive/${spec.rev}.tar.gz";
  inherit (spec) sha256;
})
```

And create `iohk-nix.json`. You will need `nix-prefetch-git` (get it
with `nix-env -iA` or `nix-shell -p`). The `--rev` option defaults to
the HEAD of the `master` branch.

```
$ nix-prefetch-git https://github.com/input-output-hk/iohk-nix [ --rev master ] | tee ./nix/iohk-nix.json
```

## How to update the `iohk-nix` revision.

To get the latest version of `iohk-nix`, update the `iohk-nix.json` file:

```
$ nix-prefetch-git https://github.com/input-output-hk/iohk-nix | tee ./nix/iohk-nix.json
```

Some things may have changed which could break your build, so refer to
the [ChangeLog](./changelog.md).

## How to use Haskell.nix and `stack-to-nix`

The [documentation](./docs/nix-toolification.org) needs to be updated.

## After updating your Stackage LTS

If you have updated your project's [Stackage
LTS](https://www.stackage.org/lts) version, then the compiler version
may also have been increased.

It's possible that the `nixpkgs` used in iohk-nix may not have have
that version of GHC, and you will get an error such as:

    error: attribute 'ghc864' missing

In this case, update the `iohk-nix` revision to the latest
available. The nixpkgs version may also need to be bumped in
`iohk-nix`.


## When making changes to `iohk-nix`

Please document any change that might affect project builds in the
[ChangeLog](./changelog.md). For example:

 - Bumping `nixpkgs` to a different branch.
 - Changing API (renaming attributes, changing function parameters, etc).
 - Bumping the `haskell.nix` version.
