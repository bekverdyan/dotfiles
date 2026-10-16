{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Aram Bekverdyan";
      email = "aram.bekverdyan@gmail.com";
    };
  };

  # Run `gh auth login` once; git then gets GitHub credentials from gh
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
}
