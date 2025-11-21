# frozen_string_literal: true

require_relative 'cli_options_registry'
require_relative 'cli_password_manager'
require_relative 'cli_conversion'
require_relative 'cli_login'

module Lich
  module Common
    module CLI
      # Orchestrates CLI operations: early-exit handlers for password management,
      # data conversion, and login flow. Uses CliOptionsRegistry for declarative
      # option registration and handler execution.
      module CLIOrchestration
        # Execute registered CLI operations
        # Processes ARGV for early-exit CLI operations (password mgmt, conversion)
        # Also handles conversion detection for login attempts
        def self.execute
          ARGV.each do |arg|
            case arg
            when /^--change-account-password$/, /^-cap$/
              handle_change_account_password
            when /^--add-account$/, /^-aa$/
              handle_add_account
            when /^--change-master-password$/, /^-cmp$/
              handle_change_master_password
            when /^--recover-master-password$/, /^-rmp$/
              handle_recover_master_password
            when /^--convert-entries$/
              handle_convert_entries
            end
          end

          # Check for conversion needed before login attempt
          # This is not an early-exit operation - it detects a precondition for login
          if ARGV.include?('--login')
            check_conversion_needed_for_login
          end
        end

        def self.check_conversion_needed_for_login
          # Determine data directory
          data_dir = ENV.fetch('LICH_DATA_DIR', nil) || File.join(Dir.home, '.lich')

          # Check if conversion is required
          if Lich::Common::CLI::CLIConversion.conversion_needed?(data_dir)
            Lich::Common::CLI::CLIConversion.print_conversion_help_message
            exit 1
          end
        end

        def self.handle_change_account_password
          idx = ARGV.index { |a| a =~ /^--change-account-password$|^-cap$/ }
          account = ARGV[idx + 1]
          new_password = ARGV[idx + 2]

          if account.nil? || new_password.nil?
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts 'Usage: ruby lich.rbw --change-account-password ACCOUNT NEWPASSWORD'
            $stdout.puts '   or: ruby lich.rbw -cap ACCOUNT NEWPASSWORD'
            exit 1
          end

          exit Lich::Common::CLI::PasswordManager.change_account_password(account, new_password)
        end

        def self.handle_add_account
          idx = ARGV.index { |a| a =~ /^--add-account$|^-aa$/ }
          account = ARGV[idx + 1]
          password = ARGV[idx + 2]

          if account.nil? || password.nil?
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts 'Usage: ruby lich.rbw --add-account ACCOUNT PASSWORD [--frontend FRONTEND]'
            $stdout.puts '   or: ruby lich.rbw -aa ACCOUNT PASSWORD [--frontend FRONTEND]'
            exit 1
          end

          frontend = ARGV[ARGV.index('--frontend') + 1] if ARGV.include?('--frontend')
          exit Lich::Common::CLI::PasswordManager.add_account(account, password, frontend)
        end

        def self.handle_change_master_password
          idx = ARGV.index { |a| a =~ /^--change-master-password$|^-cmp$/ }
          old_password = ARGV[idx + 1]
          new_password = ARGV[idx + 2]

          if old_password.nil?
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts 'Usage: ruby lich.rbw --change-master-password OLDPASSWORD [NEWPASSWORD]'
            $stdout.puts '   or: ruby lich.rbw -cmp OLDPASSWORD [NEWPASSWORD]'
            $stdout.puts 'Note: If NEWPASSWORD is not provided, you will be prompted for confirmation'
            exit 1
          end

          exit Lich::Common::CLI::PasswordManager.change_master_password(old_password, new_password)
        end

        def self.handle_recover_master_password
          idx = ARGV.index { |a| a =~ /^--recover-master-password$|^-rmp$/ }
          new_password = ARGV[idx + 1]

          # new_password is optional - if not provided, user will be prompted interactively
          exit Lich::Common::CLI::PasswordManager.recover_master_password(new_password)
        end

        def self.handle_convert_entries
          encryption_mode_idx = ARGV.index('--encryption-mode')
          cmp_idx = ARGV.index('--change-master-password') || ARGV.index('-cmp')

          if encryption_mode_idx.nil?
            $stdout.puts 'error: Missing required argument'
            $stdout.puts 'Usage: ruby lich.rbw --convert-entries --encryption-mode [plaintext|standard|enhanced]'
            $stdout.puts '   or: ruby lich.rbw --convert-entries --encryption-mode [plaintext|standard|enhanced] --change-master-password PASSWORD'
            exit 1
          end

          encryption_mode_str = ARGV[encryption_mode_idx + 1]
          master_password = nil

          unless %w[plaintext standard enhanced].include?(encryption_mode_str)
            $stdout.puts "error: Invalid encryption mode: #{encryption_mode_str}"
            $stdout.puts 'Valid modes: plaintext, standard, enhanced'
            exit 1
          end

          # Get master password if provided with -cmp flag
          if !cmp_idx.nil?
            master_password = ARGV[cmp_idx + 1]
            if master_password.nil?
              $stdout.puts 'error: Missing password argument for --change-master-password'
              exit 1
            end
          end

          # Determine data directory
          data_dir = ENV.fetch('LICH_DATA_DIR', nil) || File.join(Dir.home, '.lich')

          # Perform conversion
          success = Lich::Common::CLI::CLIConversion.convert(
            data_dir,
            encryption_mode_str,
            master_password
          )

          if success
            $stdout.puts 'Conversion completed successfully!'
            exit 0
          else
            $stdout.puts 'Conversion failed. Please check the logs for details.'
            exit 1
          end
        end
      end
    end
  end
end
