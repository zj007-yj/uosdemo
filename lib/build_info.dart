/// CI 注入：`flutter build ... --dart-define=GIT_SHA=xxx`
const String kGitSha = String.fromEnvironment('GIT_SHA', defaultValue: 'local-dev');
