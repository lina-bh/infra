{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          kubernetes-helm = pkgs.wrapHelm pkgs.kubernetes-helm {
            plugins = with pkgs.kubernetes-helmPlugins; [
              helm-diff
            ];
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            opentofu
            ansible
            k9s
            kubectl
            self.packages.${system}.kubernetes-helm
            skopeo
          ];
        };
      }
    );
}
