{ pkgs, ... }: {
  virtualisation.podman.enable = true;
  users.users.jupamohi.extraGroups = [ "kvm" "podman" ];
  environment.systemPackages = with pkgs; [
    podman-compose freerdp python3Packages.pyside6
  ];
}
