# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, home-manager, agenix, disko, ... }:

let
  sshPubKey = builtins.readFile ./id_rsa.pub;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      home-manager.nixosModules.default
      agenix.nixosModules.default
      disko.nixosModules.default
      ./disk-config.nix
      ./modules/nextcloud-backup-sink.nix
      ./modules/zaphod-backup-sink.nix
    ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "remote-data-store"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.mutableUsers = false;

  users.users.root.openssh.authorizedKeys.keys = [
      sshPubKey
  ];

  users.users.christopher = {
    isNormalUser = true;
#    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      sshPubKey
    ];
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  home-manager.users.christopher = { pkgs, ... }: {
    home = {
      stateVersion = "22.05";
      packages = [ ];
    };

    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };

    programs.bash.enable = false;
  };  

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    nano
    docker-compose
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # Enable auto upgrades from current main branch on remote
  system.autoUpgrade = {
    enable = true;
    flake = "github:glanch/remote-data-store";
    dates = "03:00";
    allowReboot = true;
  };

  # Add Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 5d";
  };


  # Backup configuration 

  # Data disk
  fileSystems."/data" = { 
    device = "/dev/disk/by-uuid/6bc91492-04b8-4f16-b789-69f3415826d0";
    fsType = "ext4";
  };

  # Create container for nextcloud backup user
  services.nextcloud-backup-sink = {
    enable = true;
    user = {
      uid = 13601;
      publicKeys = [ sshPubKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCY9H5oeekHymj2G7mCisdtqWf1aqLwYNqrBO6nF+4U7z/x22KOTsjhu+dTcfGy/O0bCJPKLQNyM1MtqWYStbtex2xLR1TFsVsRcElh8CYk8k0obqNIzBCaywZ9PRY+V8ezhqX9YBd+dYLY2E0AAqXcjPXgni/nN9sYTV+ZgzZxM8vEgACloER0vdoyBY7ob/dZf9IXCJ1mCLlvDQcVVutyyXEISNJO5Hri0Rudf8rzYvqhzFuZlRvVAQ9nqZr31e4KZLABG4+mxV8dDKiyK/jm7kdsh4CRsnIXmm3FOb60dtHV1yQtgrszst28tMP8wKtAv80Ae9JLKVoYEnwMltaqv/zp52l6cUnjXGlP6mKtxShQPOm25kkfe++WQ5sSoHlw2ukNIwoj3VONpERr8idErmL5tMDl/xiD1vxCHCkGB31GzqWEXswmO1DkWEx+X8M6iiCf4ofXuFGTe6O+NR3ONq7ri2Acu5tNN9eSQqcWU33jCoNZ4CLWWVb7RlKjiWM= christopher@t20"];
      username = "nextcloud-backup";
    };

    rootUser.publicKeys = [ sshPubKey ];
    data = {
      hostPath = "/data/storage/Backups/nextcloud-backup";
      localPath = "/data/nextcloud-backup";
    };

    networking = {
      sshd = {
        internalPort = 22;
        externalPort = 14622;
      };

      container = {
        hostAddress = "10.74.5.1";
        localAddress = "10.74.5.2";
      };
    };
  };

  # Create container for zaphod backup user
  services.zaphod-backup-sink = {
    enable = true;
    user = {
      uid = 13602;
      publicKeys = [ sshPubKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkaFCTvTryqqkyCNCCTp5DFTsJsaonl4nRxIOA3NsQgPQACGfSREX9cO5xC1JmRYakI95DaQCXuL0czIAmjqvtQUS2KKA5r7WnW6rvZUJ9RZ7AnxtWYDzJD3HpNpG0+gy9ZLl2CDE7vfur6cbrhsS6KaatH6mizEJrRhVmbZ0qC7GNASWQR54NV+Is8JqD/o6Cp8q70Jz5AieJvhEPIVWzjsiZe6GFYUTVt/RKKKOWxa5KStO0fLYD8IKEs2NtdiUlAp6DbSKtXvJIDxJmooZkA7lCpOaY/SIkuiTMKax0nc6JT/CEbAv5y24jFvQT9OSQ9UYMHIErD0TlL0vCbOIf4cBy85i3H9oDvFID2yDq5VX0Gz0jfXIsvzCyRxJtRatj6koM9p44EzYiq3stfX7H5Yv9ISvnJFSJC6wPkUfxjaFFYZYKYC/VsB017KmBo3bWj2vYNo4WJvNe7RAV3V1fegaB7Q++iWo8u7Kg5HkBbNM7u1Lfv9OHbAyvzaBl8ys= christopher@t20"];
      username = "zaphod-backup";
    };

    rootUser.publicKeys = [ sshPubKey ];
    data = {
      hostPath = "/data/storage/Backups/zaphod-backup";
      localPath = "/data/zaphod-backup";
    };

    networking = {
      sshd = {
        internalPort = 22;
        externalPort = 15622;
      };

      container = {
        hostAddress = "10.74.6.1";
        localAddress = "10.74.6.2";
      };
    };
  };
}


