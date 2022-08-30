# auto_version_name plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-auto_version_name)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-auto_version_name`, add it to your project by running:

```bash
fastlane add_plugin auto_version_name
```

## About auto_version_name

Generate incremented version names from Apple and Google stores.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

**Note to author:** Please set up a sample project to make it easy for users to explore what your plugin does. Provide everything that is necessary to try out the plugin in this project (including a sample Xcode/Android project if necessary)

## Recommended Steps (Android & iOS)

1 - In your `Root Directory`, create a `file` called `version_name`, with a minimal version that must be set as default:


![image](https://user-images.githubusercontent.com/77688036/187472195-0295a9de-6381-4978-83c1-be189c76e676.png)

2 - In your `Fastfiles`, create a `method` that returns, in `String`, the last version name in production (Store):

```ruby
platform :android do
  # [...]
  def get_live_version() # METHOD
    return google_play_track_release_names().first 
    # main method returns an array by default. ["1.0.0"] => "1.0.0"
  end
  # [...]
end
```

```ruby
platform :ios do
  # [...]
  root_directory = `cd ../.. && pwd`.chomp

  api_key = app_store_connect_api_key(
    key_id: "YOURKEYID",
    issuer_id: "YOUR-ISSUER-ID",
    key_filepath: "path/to/your/key.p8",
  )

  app_identifier = "your.app.identifier"

  def get_live_version() # METHOD
    app_store_build_number(api_key: api_key, live: true, app_identifier: app_identifier)  
    return lane_context[SharedValues::LATEST_VERSION] # "1.0.0"
  end
  # [...]
end
```

3 - In your `Fastfiles`, create a `lane` to export the live version name:

```ruby
platform :android do
  # [...]
  desc "Export live version name"
  lane :live_version_name do
    get_live_version()
  end
  # [...]
end
```

```ruby
platform :ios do
  # [...]
  desc "Export live version name"
  lane :live_version_name do
    get_live_version()
  end
  # [...]
end
```

4 - In your `Fastfiles`, inside your main `lane`, call the plugin, passing the minimum version, and the version referring to the current platform. To reference the version of another platform, import the respective Fastfile and invoke its respective version lane:

```ruby
platform :android do
  # [...]
  desc "Export live version name"
  lane :live_version_name do
    get_live_version()
  end
  
  desc "Submit a new build to Internal Test on Google Play"
  lane :deploy do
    # [...]
    root_directory = `cd ../.. && pwd`.chomp

    ios_lane = import("../../ios/fastlane/Fastfile")

    version = auto_version_name(
      minimal_version_string: File.open("#{root_directory}/version_name").read.chomp,
      android_live_version: get_live_version(),
      ios_live_version: ios_lane.runner.execute("live_version_name", "ios"),
      # IMPORTANT: if your version lanes have the same name, you need to especify the platform on execute
    )

    puts version
    # [...]
  end
  # [...]
end
```

```ruby
platform :ios do
  # [...]
  desc "Export live version name"
  lane :live_version_name do
    get_live_version()
  end
  
  desc "Push a new beta build to TestFlight"
  lane :deploy do
    # [...]
    root_directory = `cd ../.. && pwd`.chomp

    android_lane = import("#{root_directory}/android/fastlane/Fastfile")

    version = auto_version_name(
      minimal_version_string: File.open("#{root_directory}/version_name").read.chomp,
      ios_live_version: get_live_version(),
      android_live_version: android_lane.runner.execute("live_version_name", "android"),
      # IMPORTANT: if your version lanes have the same name, you need to especify the platform on execute
    )

    puts version
    # [...]
  end
  # [...]
end
```

**Notes**

- If you don't pass parameters, the version considered will always be "1.0.0".

- Auto increment will only work if some live version is passed as parameter.

- The base version will always be the largest among the options passed as a parameter. Version comparison uses [Gem::Version](https://ruby-doc.org/stdlib-2.5.0/libdoc/rubygems/rdoc/Gem/Version.html#method-i-3C-3D-3E).

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
