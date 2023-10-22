{ lib, pkgs, config, agenix, ... }:
with lib;
let
  cfg = config.services.zaphod-backup-sink;
in
{
  options.services.zaphod-backup-sink = {
    enable = mkEnableOption "Backup sink for zaphod backup";
    
    rootUser.publicKeys = mkOption {
      type = types.listOf types.str;
    };



    data = {
      hostPath = mkOption {
        type = types.str;
        default = "/data/storage/Backups/zaphod-backup";
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
      default = "zaphod-backup";
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
    system.stateVersion = "23.05";

    users.users."${cfg.user.username}" = {
      isNormalUser = true;
      uid = cfg.user.uid;
      openssh.authorizedKeys.keys = cfg.user.publicKeys;
    };

    containers.zaphod-backup =
    {
      privateNetwork = true;
      
      localAddress = cfg.networking.container.localAddress;
      hostAddress = cfg.networking.container.hostAddress;

      autoStart = true;

      config =
        { config, pkgs, ... }:
        {
          services.openssh = {
            enable = true;
            settings.PasswordAuthentication = false;
            settings.KbdInteractiveAuthentication = false;
            settings.PermitRootLogin = "no";
          };
          
          users.mutableUsers = false;
          users.users."${cfg.user.username}" = {
            uid = cfg.user.uid;
            isNormalUser = true;
            openssh.authorizedKeys.keys = cfg.user.publicKeys;
          };

          users.users.root = {
            openssh.authorizedKeys.keys = cfg.rootUser.publicKeys;
          };

          environment.systemPackages = [ pkgs.restic ];
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
