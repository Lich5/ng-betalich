# frozen_string_literal: true

require_relative '../gui/yaml_state'

module Lich
  module Common
    module CLI
      # Handles entry.dat to entry.yaml conversion for CLI
      # Provides detection mechanism and orchestration for conversion process
      module CLIConversion
        # Checks if conversion is needed
        # Returns true when entry.dat exists but entry.yaml doesn't exist
        #
        # @param data_dir [String] Directory containing entry data
        # @return [Boolean] True if conversion is needed
        def self.conversion_needed?(data_dir)
          dat_file = File.join(data_dir, 'entry.dat')
          yaml_file = Lich::Common::GUI::YamlState.yaml_file_path(data_dir)

          File.exist?(dat_file) && !File.exist?(yaml_file)
        end

        # Performs conversion from entry.dat to entry.yaml
        # Delegates to YamlState.migrate_from_legacy for actual conversion
        #
        # @param data_dir [String] Directory containing entry data
        # @param encryption_mode [Symbol] Encryption mode (:plaintext, :standard, :enhanced)
        # @param master_password [String, nil] Optional master password for enhanced mode
        # @return [Boolean] True if conversion was successful
        def self.convert(data_dir, encryption_mode, master_password = nil)
          # Normalize encryption_mode to symbol if string is passed
          mode = encryption_mode.to_sym

          # For enhanced mode with provided master password, we need to handle this specially
          # YamlState.migrate_from_legacy will prompt for password if not provided in enhanced mode
          # But we want to pass the provided master password directly
          if mode == :enhanced && !master_password.nil?
            # Call the migration with the provided master password
            # Note: migrate_from_legacy expects the password to be validated separately
            # We'll need to integrate this with the master password manager
            result = Lich::Common::GUI::YamlState.migrate_from_legacy(data_dir, encryption_mode: mode)

            if result && master_password
              # If migration succeeded and we have a master password, store it in keychain
              # This handles the one-shot conversion with master password setup
              require_relative 'cli_password_manager'
              begin
                # The migration created a validation test, now store the password
                Lich::Common::CLI::PasswordManager.store_master_password_to_keychain(master_password, data_dir)
                return true
              rescue StandardError => e
                Lich.log "error: Failed to store master password to keychain: #{e.message}"
                return false
              end
            end

            return result
          else
            # For other modes, just call migrate_from_legacy directly
            Lich::Common::GUI::YamlState.migrate_from_legacy(data_dir, encryption_mode: mode)
          end
        end

        # Prints helpful conversion message showing user how to run conversion
        # Called when conversion is detected and user tries to login without converting
        def self.print_conversion_help_message
          $stdout.puts "\n" + '=' * 80
          $stdout.puts "Saved entries conversion required"
          $stdout.puts '=' * 80
          $stdout.puts "\nYour login entries need to be converted to the new format."
          $stdout.puts "\nRun one of these commands:\n\n"

          $stdout.puts "For no encryption (least secure):"
          $stdout.puts "  ruby lich.rbw --convert-entries --encryption-mode plaintext\n\n"

          $stdout.puts "For account-based encryption (standard):"
          $stdout.puts "  ruby lich.rbw --convert-entries --encryption-mode standard\n\n"

          $stdout.puts "For master-password encryption (recommended):"
          $stdout.puts "  ruby lich.rbw --convert-entries --encryption-mode enhanced --change-master-password YOUR_MASTER_PASSWORD\n\n"

          $stdout.puts '=' * 80 + "\n"
        end
      end
    end
  end
end
