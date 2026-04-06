# amp-nix

A Nix flake for [Amp](https://ampcode.com).

## Usage

```bash
nix run github:kenany/amp-nix -- --help
```

### Nix profile

Install Amp to your user profile:

```bash
nix profile install github:kenany/amp-nix
```

Then use Amp:

```bash
amp --help
```

### Nix Overlay

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    amp-nix.url = "github:kenany/amp-nix";
  };

  outputs = { self, nixpkgs, amp-nix }:
    let
      system = "x86_64-linux"; # or your system
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ amp-nix.overlays.default ];
      };
    in
    {
      # Now `pkgs.amp` is available.
      devShells.default = pkgs.mkShell {
        buildInputs = [ pkgs.amp ];
      };
    };
}
```

## Remote binary cache

**URL**: `https://ampcode.cachix.org`  
**Public key**: `ampcode.cachix.org-1:H2lL0+8ZjzkCp1a+eOyX2vD0KGBkAiNTuedPqcopb/M=`
