{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  inputs.home-manager.url = "github:nix-community/home-manager/release-24.05";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.disko.url = "github:nix-community/disko";

  outputs = { self, nixpkgs, home-manager, deploy-rs, agenix, disko, ... }@attrs: {
    nixosConfigurations."remote-data-store" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./configuration.nix];
    };
    deploy.nodes.remote-data-store = {
      hostname = "remote-data-store.fritz.box";
      fastConnection = true;
      profiles = {
        system = {
          sshUser = "root";
          path =
            deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."remote-data-store";
          user = "root";
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

  };
}
