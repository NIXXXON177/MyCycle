/// Настройки автообновления через GitHub Releases.
abstract final class UpdateConfig {
  static const githubOwner = 'NIXXXON177';
  static const githubRepo = 'MyCycle';

  static String get releasesApiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static String get manifestUrl =>
      'https://github.com/$githubOwner/$githubRepo/releases/latest/download/manifest.json';

  static bool get isEnabled => githubOwner.isNotEmpty && githubRepo.isNotEmpty;
}
