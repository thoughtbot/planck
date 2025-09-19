# Planck

Atomic file writes for Ruby.

## Why?

A naive file write:

```ruby
File.write("secrets.json", json)
```

is **not atomic**. If your process crashes midway, or if another process reads the file while it’s being written, you can end up with truncated or corrupted data.

`Planck.atomic_write` solves this. It

1. Writes the data to a hidden tempfile in the same directory.
2. Flushes (`fsync`) to ensure the contents are on disk.
3. Renames the tempfile into place (`rename` is atomic on POSIX).
4. Flushes the parent directory entry (`fsync` again) to make the rename durable even in the event of a power loss.

As a result, readers always see either the old file or the fully written new one — never an in-between state.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add planck
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install planck
```

## Usage

```ruby
require "planck"

# Safely replace or create a file with 0600 permissions by default
Planck.atomic_write("secrets.json", '{"token":"abc123"}')

# Preserve existing file permissions (mode) when overwriting
Planck.atomic_write("config.yml", "new settings", preserve_mode: true)

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thoughtbot/planck.

## License

Open source templates are Copyright (c) thoughtbot, inc. It contains free
software that may be redistributed under the terms specified in the
[LICENSE](https://github.com/thoughtbot/planck/blob/main/LICENSE.txt)
file.

## Code of Conduct

Everyone interacting in the DataCustoms project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/thoughtbot/planck/blob/main/CODE_OF_CONDUCT.md).

<!-- START /templates/footer.md -->

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc. The names and logos for
thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community]. We are
[available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github&utm_medium=readme&utm_campaign=planck
[hire]: https://thoughtbot.com/hire-us?utm_source=github&utm_medium=readme&utm_campaign=planck
