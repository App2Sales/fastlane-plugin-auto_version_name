require 'fastlane/action'
require_relative '../helper/auto_version_name_helper'

module Fastlane
  module Actions
    class AutoVersionNameAction < Action
      def self.run(params)
        def self.version_string_to_array(version_string)
          return version_string.split('.').map { |value| value.to_i }
        end

        def self.get_greater_array(array1, array2, array3)
          greater = []

          for i in 0..2
            i1 = array1[i]
            i2 = array2[i]
            i3 = array3[i]

            if (i1 >= i2 && i1 >= i3)
              greater = array1
            elsif (i2 >= i1 && i2 >= i3)
              greater = array2
            elsif (i3 >= i1 && i3 >= i2)
              greater = array3
            end
          end

          if (greater.empty?)
            greater = array1
          end

          return greater
        end

        # Initialize
        branch = Actions.git_branch()
        minimal_version_array = []
        ios_version_array = []
        android_version_array = []
        final_version_array = []
        final_version_string = ""
        is_file_defined = defined?(params[:version_name_file_path]) ? true : false
        is_ios_defined = defined?(params[:ios_api_key]) ? true : false
        is_android_defined = defined?(params[:android_json_key_path]) ? true : false
        
        # Minimal version array
        if (is_file_defined)
          version_name_file_path = params[:version_name_file_path]
          minimal_version_string = File.open(version_name_file_path).read.chomp
          minimal_version_array = version_string_to_array(minimal_version_string)
        end
        
        # iOS version array
        if (is_ios_defined)
          ios_api_key = params[:ios_api_key]
          Actions.app_store_build_number(api_key: ios_api_key, live: true)  
          ios_version_string = lane_context[SharedValues::LATEST_VERSION]
          ios_version_array = version_string_to_array(ios_version_string)
        end
        
        # Android version array
        if (is_android_defined)
          android_json_key = params[:android_json_key_path]
          android_version_string = Actions.google_play_track_release_names(json_key: android_json_key).first
          android_version_array = version_string_to_array(android_version_string)
        end
        
        # Set final version array by comparison
        if (minimal_version_array.any? && android_version_array.any? && ios_version_array.any?)
          final_version_array = get_greater_array(minimal_version_array, android_version_array, ios_version_array)
        end

        # Upgrade final version array and return
        if(final_version_array.any?)
          major = final_version_array[0]
          minor = final_version_array[1]
          patch = final_version_array[2]

          # Auto increment.
          # 1.0.1 => 1.0.1(+1) => 1.0.2 || 1.0.1 => 1.0(+1).1 => 1.1.0
          if (branch.include? 'hotfix')
            patch += 1
          else
            if (major_from_file > major)
              # Immediately returns if local is higher
              # This will happen only once, if the developer increases the version in the file
              final_version_string = "#{major_from_file}.0.0"
            end
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

          final_version_array[0] = major
          final_version_array[1] = minor
          final_version_array[2] = patch

          final_version_string = final_version_array.join('.') # [1, 0, 0] => "1.0.0"
        end

        if(final_version_string.empty?)
          raise "[ERROR] - Final Version String is empty."
        else
          return final_version_string
        end
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
          FastlaneCore::ConfigItem.new(key: :version_name_file_path,
                                  env_name: "VERSION_NAME_FILE_PATH",
                               description: "The destination to version_name file",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :ios_api_key,
                                  env_name: "IOS_API_KEY",
                               description: "The App Store Connect API key information used for authorization requests",
                                  optional: true,
                                      type: Hash),
          FastlaneCore::ConfigItem.new(key: :android_json_key_path,
                                  env_name: "ANDROID_JSON_KEY_PATH",
                               description: "The path to a file containing service account JSON, used to authenticate with Google",
                                  optional: true,
                                      type: String)
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
