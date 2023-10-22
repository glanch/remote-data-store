{ lib, pkgs, config, agenix, ... }:
with lib;
let
  cfg = config.services.nextcloud-backup-sink;
in
{
  options.services.nextcloud-backup-sink = {
    enable = mkEnableOption "Backup sink for nextcloud backup";
    
    rootUser.publicKeys = mkOption {
      type = types.listOf types.str;
    };



    data = {
      hostPath = mkOption {
        type = types.str;
        default = "/data/storage/Backups/nextcloud-backup";
      };

      localPath = mkOption {
        type = types.str;
      };
    };

    user.uid = mkOption {
      type = types.int;
    };

    user.username = mkOption {
      type = types.str;
      default = "nextcloud-backup";
    };

    user.publicKeys = mkOption {
      type = types.listOf types.str;
    };

    networking = {
      sshd = {
        internalPort = mkOption {
          type = types.int;
        };
        externalPort = mkOption {
          type = types.int;
        };
      };

      container = {
        hostAddress = mkOption {
          type = types.str;
        };

        localAddress = mkOption {
          type = types.str;
        };
      };
    };
    
  };

  config = mkIf cfg.enable {
    system.stateVersion = "23.11";

    users.users."${cfg.user.username}" = {
      isNormalUser = true;
      uid = cfg.user.uid;
      openssh.authorizedKeys.keys = cfg.user.publicKeys;
    };

    containers.nextcloud-backup-container =
    {
      privateNetwork = true;
      
      localAddress = cfg.networking.container.localAddress;
      hostAddress = cfg.networking.container.hostAddress;

      autoStart = true;

      config =
        { config, pkgs, ... }:
        {
          services.openssh.enable = true;
          users.mutableUsers = false;
          users.users."${cfg.user.username}" = {
            uid = cfg.user.uid;
            isNormalUser = true;
            openssh.authorizedKeys.keys = cfg.user.publicKeys;
          };

          users.users.root = {
            openssh.authorizedKeys.keys = cfg.rootUser.publicKeys;
          };
        };

      forwardPorts =
      [
        {
          containerPort = cfg.networking.sshd.internalPort; 
          hostPort = cfg.networking.sshd.externalPort;
        }
      ];

      bindMounts = {
        "${cfg.data.localPath}" = {
          hostPath = "${cfg.data.hostPath}";
          isReadOnly = false;
        };
      };
    };

    networking.nat.enable = true;
  };
}
