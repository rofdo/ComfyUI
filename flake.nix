{
  description = "Flake for PyTorch development environment with CUDA support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
        p2nix = poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs; };

        spandrel = pkgs.python3Packages.buildPythonPackage rec {
          pname = "spandrel";
          version = "0.4.0";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-9FUmiT+SOhLvN1QsROREsSCJdlk7x8zfpU/QTHw+gMo=";
          };
          format = "pyproject";
          nativeBuildInputs = with pkgs.python3Packages; [
            setuptools
            torchvision
            einops
            wheel
            pip
          ];

          propagatedBuildInputs = with pkgs.python3Packages; [
            torch
            safetensors
          ];
          doCheck = false;
        };
        # spandrel = p2nix.mkPoetryApplication {
        #   projectDir = pkgs.fetchFromGitHub {
        #     owner = "chaiNNer-org";
        #     repo = "spandrel";
        #     rev = "v0.4.0";  # Use the latest version
        #     sha256 = "sha256-BiC4gmRsNkRAUonKHV7U/hvOP00pIPtm40ydmSlNDCI=";
        #   };
        #   preferWheels = true;
        # };

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          (pytorch.override {
            cudaSupport = true;
          })
          torchvision
          torchaudio
          # Add any other packages you need
          torch
          torchsde
          torchvision
          torchaudio
          einops
          transformers
          tokenizers
          sentencepiece
          safetensors
          aiohttp
          pyyaml
          pillow
          scipy
          tqdm
          psutil

          gitpython

          # Optional packages
          kornia
          spandrel
          soundfile
        ]);

      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.cudaPackages.cudatoolkit
          ];

          test = ''
            # Install any additional Python packages you need
            pip install spandrel
          '';

          shellHook = ''
            echo "PyTorch development environment with CUDA support activated"
            echo "Starting ComfyUI..."
            firefox http://localhost:8188
            python main.py
          '';
        };
      }
    );
}

