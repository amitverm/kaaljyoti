# Contributing to Kaal Jyoti

Thank you for your interest in contributing!

## License and copyright of contributions

Kaal Jyoti is released under the GNU AGPL-3.0 (see [LICENSE](LICENSE)).

To keep the project's licensing options open (including the ability to
relicense or to ship builds using the Swiss Ephemeris professional
license in the future), **contributions are accepted only with copyright
assignment**: by submitting a pull request you agree that you assign the
copyright of your contribution to the project owner (Amit Verma), who
will always distribute it as part of this project under the AGPL-3.0 or
a later version.

If you are not comfortable with assignment, please open an issue
describing the change instead — a maintainer may implement it
independently.

### How the assignment is recorded

When you open a pull request, the CLA bot posts a comment asking you to
confirm the assignment by replying with a specific signing sentence.
Your signature (GitHub username + timestamp) is stored on the
`cla-signatures` branch of this repository and the PR's "CLA Assistant"
check turns green — you sign once, and future PRs recognise you
automatically. PRs are not merged before the check passes. For
substantial contributions the maintainer may additionally request a
signed assignment form by email.

## Practical notes

- Run `flutter analyze` and `flutter test` before submitting.
- Keep changes focused; one topic per PR.
- Never commit secrets: `env.json`, `android/key.properties`, and
  keystores are gitignored and must stay that way. Use
  `env.example.json` as the template.
- Astrology correctness matters: cite the classical rule or reference
  implementation when changing calculation code, and add a test vector.
