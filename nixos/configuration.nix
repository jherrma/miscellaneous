# V0.1
{config, pkgs, lib, ...}:

let 
user = "user";
hostname = "nixos";
in
{
  imports =
    [
      # include result of hardware scan
      ./hardware-configuration.nix
    ];


  # Auto upgrade
  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
    # see time options here: https://www.freedesktop.org/software/systemd/man/systemd.time.html
    dates = "monthly"
  };

  # Garbage collection
  nix = {
    settings.auto-optimise-store = true;
    gc= {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3months";
    };
  };

  # TODO Encryption
  # https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58

  boot = {
    loader = {
      # grub = {
      #   enable = true;
      #   version = 2;
      #   efiSupport = true;
      #   configurationLimit = 5;
      #   theme = null;
      #   splashMode = "normal";
      #   device = "/dev/sda"
      # };

      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      timeout = 3;
    };
  };

  networking = {
    hostName = hostname;
    iwd = {
      enable = true;
      settings= {
        Network = {
          EnableIPv6 = true;
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "de_DE.UTF-8";
    };
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # Desktop Environment
  # Wayland is the default
  services.xserver = {
    enable = true;
    displayManager = {
      gdm.enable = true;
      defaultSession = "gnome";
    };
    desktopManager.gnome.enable = true;
    layout = "de";
    # touchpad support
    libinput.enable = true;
  };
  # Exclude some gnome applications
  environment.gnome.excludePackages = (with pkgs; [
    
  ]) ++ (with pkgs.gnome; [
    gnome-music
    epiphany
    geary
    totem
    tali
    hitori
    atomix
  ]);

  services = {
    blueman.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        userService = true;
      }
    }
  };

  # Printing
  services.printing.enable = true;

  # Audio
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Swap file
  zramSwap = {
    enable = true;
  };


  # System packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    wget
    git
    firefox
    brave
    obsidian
    tdesktop # telegram
    vscodium
    flatpak
    cmake
    evolution
    gthumb
    onlyoffice-bin
    keepassxc
    vlc
    xournalpp
    docker
    docker-buildx
    docker-compose
  ];

  # Users
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "networkmanager" "lp" "scanner"];
    initialPassword = "password";
    shell = pkgs.zsh;
  };

  system.stateVersion = "22.05";
}
