{ pkgs, ... }: {
  virtualisation.podman.enable = true;
  users.users.jupamohi.extraGroups = [ "kvm" "podman" ];
  environment.sessionVariables.XDG_DATA_DIRS = [ "$HOME/.local/share" ];
  environment.systemPackages = with pkgs; [
    podman-compose
    freerdp
    (python3.withPackages (ps: [ ps.pyside6 ps.python-dotenv ]))
  ];
}
