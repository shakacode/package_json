# PackageJson

The missing gem for managing `package.json` files, without having to know about
package managers (mostly).

It provides an interface for easily modifying the properties of `package.json`
files, along with a "middle-level" abstraction over JavaScript package mangers
to make it easy to manage dependencies without needing to know the specifics of
the underlying package manager (and potentially without even knowing the manager
itself!).

This is _not_ meant to provide the exact same functionality and behaviour
regardless of what package manager is being used, but rather make it easier to
perform common general tasks that are supported by all package managers like
adding new dependencies, installing existing ones, and running scripts without
having to know the actual command a specific package manager requires for that
action (and other such nuances).

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with
your gem name right after releasing it to RubyGems.org. Please do not do it
earlier due to security reasons. Alternatively, replace this section with
instructions to install your gem from git if you don't plan to release to
RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by
executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

```ruby
# represents $PWD/package.json, creating it if it does not exist
package_json = PackageJson.new

# adds eslint, eslint-plugin-prettier, and prettier as development dependencies
package_json.manager.add(%w[eslint prettier], :dev)

# adds the "lint" and "format" scripts, preserving any existing scripts
package_json.merge! do |pj|
  {
    "scripts" => pj.fetch("scripts", {}).merge({
      "lint" => "eslint . --ext js",
      "format" => "prettier --check ."
    })
  }
end

# deletes the "babel" property, if it exists
package_json.delete!("babel")

# runs the "lint" script with the "--fix" argument
package_json.manager.run("lint", ["--fix"])
```

The `PackageJson` class represents a `package.json` on disk within a directory;
because it is expected that the `package.json` might be changed by external
sources such as package managers, `PackageJson` reads and writes to and from the
`package.json` as needed rather than representing it in memory.

You can initialize a `PackageJson` with either `new` or `read` depending on if
you want to ensure the `package.json` exists or throw if it doesn't:

```ruby
# this will create the `package.json` if it does not exist
PackageJson.new(:npm, "path/to/directory")

# this will error if the `package.json` does not exist
PackageJson.read("path/to/directory", :npm)
```

A `PackageJson` also comes with a `manager` that can be used to manage
dependencies and run scripts. The manager will be inferred by the
[`packageManager`](https://nodejs.org/api/packages.html#packagemanager) property
in the `package.json`.

> **Note**
>
> Only the name of the package manager is used; the version (if present) is
> _not_ checked, nor is [`codepack`](https://nodejs.org/api/corepack.html) used
> to ensure that the package manager is installed.
>
> The manager will be invoked by its name in the directory of the
> `package.json`, and it is up to the developer to ensure that results in the
> desired package manager actually running.

You can specify a fallback package manager to use in-case the `package.json`
does not exist or does not have the `packageManager` property:

```ruby
PackageJson.new(:yarn_classic)
```

The default fallback is `:npm`; supported package managers are `:npm`,
`:yarn_classic`, and `:pnpm`.

If the `package.json` does not exist, then the `packageManager` property will be
included based on this value, but it will _not_ be updated if the file already
exists without the property.

> TODO: providing a class

Managers are provided a reference to the `PackageJson` when they're initialized,
are run in the same directory as that `PackageJson`, and lets you do the
following:

> **Note**
>
> Unless otherwise noted, options are safe to use regardless of what underlying
> package manager is being used; if an option is not supported by a particular
> package manager, it will be ignored

### Installing dependencies

```ruby
# install all dependencies
package_json.manager.install

# install all dependencies, erroring if the lockfile is outdated
package_json.manager.install(frozen: true)
```

| Option               | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `frozen`             | Fail if the lockfile needs to be updated                                                                 |
| `ignore_scripts`     | Don't run scripts specified in `package.json` files                                                      |
| `legacy_peer_deps`   | Have `npm` completely ignore `peerDependencies` when installing; does nothing for other package managers |
| `omit_optional_deps` | Omit optional dependencies when installing                                                               |

### Generating the `install` command for embedding in native scripts

```ruby
native_install_command = package_json.manager.native_install_command

append_to_file "bin/ci-run" do
  <<~CMD
    echo "* ******************************************************"
    echo "* Installing JS dependencies"
    echo "* ******************************************************"
    #{native_install_command}
  CMD
end
```

| Option               | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `frozen`             | Fail if the lockfile needs to be updated                                                                 |
| `ignore_scripts`     | Don't run scripts specified in `package.json` files                                                      |
| `legacy_peer_deps`   | Have `npm` completely ignore `peerDependencies` when installing; does nothing for other package managers |
| `omit_optional_deps` | Omit optional dependencies when installing                                                               |

### Adding dependencies

```ruby
# adds axios as a production dependency
package_json.manager.add(["axios"])

# adds eslint and prettier as dev dependencies
package_json.manager.add(["eslint", "prettier"], type: :dev)

# adds dotenv-webpack v6 as a production dependency
package_json.manager.add(["dotenv-webpack@^6"])
```

| Option               | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `type`               | The type to add the dependencies as; either `:production` (default), `:dev`, `:optional`, or `:peer`     |
| `ignore_scripts`     | Don't run scripts specified in `package.json` files                                                      |
| `legacy_peer_deps`   | Have `npm` completely ignore `peerDependencies` when installing; does nothing for other package managers |
| `omit_optional_deps` | Omit optional dependencies when installing                                                               |

### Removing dependencies

```ruby
# removes the axios package
package_json.manager.remove(["axios"])
```

| Option               | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `ignore_scripts`     | Don't run scripts specified in `package.json` files                                                      |
| `legacy_peer_deps`   | Have `npm` completely ignore `peerDependencies` when installing; does nothing for other package managers |
| `omit_optional_deps` | Omit optional dependencies when installing                                                               |

### Run a script

```ruby
# runs the "test" script
package_json.manager.run("test")

# runs the "test" script, passing it "--coverage path/to/my/test.js" as the argument
package_json.manager.run("test", ["--coverage", "path/to/my/test.js"])

# runs the "lint" script, passing it "--fix" as the argument and telling the package manager to be silent
package_json.manager.run("lint", ["--fix"], silent: true)
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `silent` | Suppress output from the package manager |

### Generating a run command for embedding in native scripts

```ruby
native_run_command = package_json.manager.native_run_command("test", ["--coverage"])

append_to_file "bin/ci-run" do
  <<~CMD
    echo "* ******************************************************"
    echo "* Running JS tests"
    echo "* ******************************************************"
    #{native_run_command}
  CMD
end
```

| Option   | Description                              |
| -------- | ---------------------------------------- |
| `silent` | Suppress output from the package manager |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/package_json. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the
[code of conduct](https://github.com/[USERNAME]/package_json/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PackageJson project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/[USERNAME]/package_json/blob/main/CODE_OF_CONDUCT.md).
