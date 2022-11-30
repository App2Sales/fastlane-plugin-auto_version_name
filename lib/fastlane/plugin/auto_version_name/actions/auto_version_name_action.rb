require 'fastlane/action'
require_relative '../helper/auto_version_name_helper'

module Fastlane
  module Actions
    class AutoVersionNameAction < Action
      def self.run(params)
        # INITIALIZE
        branch = Actions.git_branch()
        last_commit_message = Actions.last_git_commit_message()
        final_version_array = []
        final_version_string = ""
        minimal_version_string = params[:minimal_version]
        has_any_live_version = false

        # FUNCTIONS
        def self.version_string_to_array(version_string)
          return version_string.split('.').map { |value| value.to_i }
        end

        def self.get_greater_version(minimal, ios, android)
          greater_version = ""

          minimal = minimal == nil ? "" : minimal
          ios = ios == nil ? "" : ios
          android = android == nil ? "" : android

          is_minimal_greater = Gem::Version.new(minimal) >= Gem::Version.new(ios) && Gem::Version.new(minimal) >= Gem::Version.new(android)

          is_ios_greater = Gem::Version.new(ios) >= Gem::Version.new(minimal) && Gem::Version.new(ios) >= Gem::Version.new(android)

          is_android_greater = Gem::Version.new(android) >= Gem::Version.new(minimal) && Gem::Version.new(android) >= Gem::Version.new(ios)

          if (is_minimal_greater)
            greater_version = minimal
          elsif (is_ios_greater)
            greater_version = ios
          elsif (is_android_greater)
            greater_version = android
          end

          if (greater_version.empty? || greater_version == nil)
            greater_version = minimal_version_string
          end

          return greater_version
        end        
        
        # iOS
        begin
          AppStoreBuildNumberAction.run(
            api_key: params[:ios_api_key],
            app_identifier: params[:ios_app_identifier],
            username: params[:ios_username],
            team_id: params[:ios_team_id],
            platform: "ios",
            live: true,
          )
          ios_version_string = lane_context[SharedValues::LATEST_VERSION];
          has_any_live_version = true

        rescue => exception
          puts exception
          ios_version_string = minimal_version_string
        end

        # ANDROID
        begin
          android_version_string = GooglePlayTrackReleaseNamesAction.run(
            json_key: params[:android_json_key_path],
            package_name: params[:android_package_name],
            track: "production",
          ).first
          has_any_live_version = true

        rescue => exception
          puts exception
          android_version_string = minimal_version_string
        end
        
        greater_version_string = get_greater_version(
          minimal_version_string, ios_version_string, android_version_string
        )

        are_all_equal = [minimal_version_string, ios_version_string, android_version_string].uniq.size <= 1
        
        if (!has_any_live_version || (!are_all_equal && greater_version_string == minimal_version_string))
          return minimal_version_string
        end

        final_version_array = greater_version_string.split('.').map { |value| value.to_i }

        # Upgrade final version array and return
        major = final_version_array[0]
        minor = final_version_array[1]
        patch = final_version_array[2]

        # Auto increment.
        # 1.0.1 => 1.0.1(+1) => 1.0.2 || 1.0.1 => 1.0(+1).1 => 1.1.0
        if ((branch.include? 'hotfix') || (last_commit_message.include? 'hotfix'))
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

        final_version_array[0] = major
        final_version_array[1] = minor
        final_version_array[2] = patch

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
          FastlaneCore::ConfigItem.new(
            key: :android_package_name,
            env_name: "ANDROID_PACKAGE_NAME",
            description: "The package_name of your android app",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :ios_app_identifier,
            env_name: "IOS_PACKAGE_NAME",
            description: "The bundle_identifier of your iOS app",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :minimal_version,
            env_name: "MINIMAL_VERSION_STRING", 
            description: "A minimal version to be set",
            optional: true,
            default_value: "1.0.0",
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :android_json_key_path,
            env_name: "ANDROID_JSON_KEY_PATH",
            description: "The path to a file containing service account JSON, used to authenticate with Google",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :ios_api_key,
            env_names: ["APPSTORE_BUILD_NUMBER_API_KEY", "APP_STORE_CONNECT_API_KEY"],
            description: "Your App Store Connect API Key information (https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)",
            type: Hash,
            default_value: Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APP_STORE_CONNECT_API_KEY],
            default_value_dynamic: true,
            optional: true,
            sensitive: true,
            conflicting_options: [:api_key_path]
          ),
          FastlaneCore::ConfigItem.new(
            key: :ios_username,
            short_option: "-u",
            env_name: "ITUNESCONNECT_USER",
            description: "Your Apple ID Username",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :ios_team_id,
            short_option: "-k",
            env_name: "APPSTORE_BUILD_NUMBER_LIVE_TEAM_ID",
            description: "The ID of your App Store Connect team if you're in multiple teams",
            optional: true,
            skip_type_validation: true, # as we also allow integers, which we convert to strings anyway
            code_gen_sensitive: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:itc_team_id),
            default_value_dynamic: true,
            verify_block: proc do |value|
              ENV["FASTLANE_ITC_TEAM_ID"] = value.to_s
            end
          ),
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
