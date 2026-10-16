# Every module. A host (hosts/*.nix) imports this and turns parts on with
# the dotfiles.* options; core/ is always on.
{
  imports = [
    ./core
    ./desktop
    ./laptop
  ];
}
