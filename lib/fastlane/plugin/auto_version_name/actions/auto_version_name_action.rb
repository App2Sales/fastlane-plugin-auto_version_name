require 'fastlane/action'
require_relative '../helper/auto_version_name_helper'

module Fastlane
  module Actions
    class AutoVersionNameAction < Action
      def self.run(params)
        def self.version_string_to_array(version_string)
          return version_string.split('.').map { |value| value.to_i }
        end

        def self.get_greater_version(version1, version2, version3)
          greater_version = ""

          version1 = version1 == nil ? "" : version1
          version2 = version2 == nil ? "" : version2
          version3 = version3 == nil ? "" : version3

          is_v1_greater = Gem::Version.new(version1) >= Gem::Version.new(version2) && Gem::Version.new(version1) >= Gem::Version.new(version3)

          is_v2_greater = Gem::Version.new(version2) >= Gem::Version.new(version1) && Gem::Version.new(version2) >= Gem::Version.new(version3)

          is_v3_greater = Gem::Version.new(version3) >= Gem::Version.new(version1) && Gem::Version.new(version3) >= Gem::Version.new(version2)

          if (is_v1_greater)
            greater_version = version1
          elsif (is_v2_greater)
            greater_version = version2
          elsif (is_v3_greater)
            greater_version = version3
          end

          if (greater_version.empty? || greater_version == nil)
            greater_version = "1.0.0"
          end

          return greater_version
        end

        # Initialize
        branch = Actions.git_branch()
        final_version_array = []
        final_version_string = ""
        minimal_version_string = params[:minimal_version]
        ios_version_string = params[:ios_live_version]
        android_version_string = params[:android_live_version]

        final_version_array = get_greater_version(
          minimal_version_string, ios_version_string, android_version_string
        ).split('.').map { |value| value.to_i }

        # Upgrade final version array and return
        major = final_version_array[0]
        minor = final_version_array[1]
        patch = final_version_array[2]

        # Auto increment.
        # 1.0.1 => 1.0.1(+1) => 1.0.2 || 1.0.1 => 1.0(+1).1 => 1.1.0
        if (branch.include? 'hotfix')
          patch += 1
        else
          minor += 1
          patch = 0
        end

        # Auto replacement if it reaches the limit.
        # 1.999.1000 => 1.999(+1).0 => 1(+1).0.0 => 2.0.0
        if(patch > 999)
          patch = 0
          minor += 1
        end

        if(minor > 999)
          minor = 0
          major += 1
        end

        live_versions_not_setted = (ios_version_string == nil || ios_version_string.empty?) && (android_version_string == nil || android_version_string.empty?)

        unless (live_versions_not_setted)
          final_version_array[0] = major
          final_version_array[1] = minor
          final_version_array[2] = patch
        end

        final_version_string = final_version_array.join('.') # [1, 0, 0] => "1.0.0"
        return final_version_string
      end

      def self.description
        "Generate incremented version names from Apple and Google stores"
      end

      def self.authors
        ["gileadeteixeira"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :minimal_version,
                                  env_name: "MINIMAL_VERSION_STRING",
                               description: "A minimal version to be set",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :android_live_version,
                                  env_name: "ANDROID_LIVE_VERSION",
                               description: "Android's live version name e.g. \"1.0.0\"",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :ios_live_version,
                                  env_name: "IOS_LIVE_VERSION",
                               description: "iOS's live version name e.g. \"1.0.0\"",
                                  optional: true,
                                      type: String),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
