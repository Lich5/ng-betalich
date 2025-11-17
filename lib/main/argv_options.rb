# frozen_string_literal: true

# CLI argument processing and orchestration (Layer 2)
# Three-layer architecture:
#   - Layer 1 (Opts): Pure parsing of ARGV → frozen OpenStruct
#   - Layer 2 (this file): Validation, routing to handlers, side effects
#   - Layer 3 (CliPasswordManager): Domain-specific handlers

require File.join(LIB_DIR, 'util', 'opts.rb')
require File.join(LIB_DIR, 'util', 'cli_options_registry.rb')
require File.join(LIB_DIR, 'util', 'cli_password_manager.rb')

module Lich
  module Main
    # Orchestrates ARGV processing: parsing → validation → handler execution → side effects
    module ArgvOptions
      # Handle early-exit CLI operations (password mgmt, SGE/SAL linking)
      # These must run before normal argv_options processing
      module CliOperations
        def self.execute
          ARGV.each do |arg|
            case arg
            when /^--change-account-password$/, /^-cap$/
              handle_change_account_password
            when /^--add-account$/, /^-aa$/
              handle_add_account
            when /^--change-master-password$/, /^-cmp$/
              handle_change_master_password
            end
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

          exit Lich::Util::CLI::PasswordManager.change_account_password(account, new_password)
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
          exit Lich::Util::CLI::PasswordManager.add_account(account, password, frontend)
        end

        def self.handle_change_master_password
          idx = ARGV.index { |a| a =~ /^--change-master-password$|^-cmp$/ }
          old_password = ARGV[idx + 1]

          if old_password.nil?
            $stdout.puts 'error: Missing required arguments'
            $stdout.puts 'Usage: ruby lich.rbw --change-master-password OLDPASSWORD'
            $stdout.puts '   or: ruby lich.rbw -cmp OLDPASSWORD'
            $stdout.puts 'Note: New password will be prompted for confirmation'
            exit 1
          end

          exit Lich::Util::CLI::PasswordManager.change_master_password(old_password)
          new_password = ARGV[idx + 2]

            $stdout.puts 'Usage: ruby lich.rbw --change-master-password OLDPASSWORD [NEWPASSWORD]'
            $stdout.puts '   or: ruby lich.rbw -cmp OLDPASSWORD [NEWPASSWORD]'
            $stdout.puts 'Note: If NEWPASSWORD is not provided, you will be prompted for confirmation'

          exit Lich::Util::CLI::PasswordManager.change_master_password(old_password, new_password)
        end
      end

      # Parse ARGV and build @argv_options hash for backward compatibility
      module OptionParser
        def self.execute
          @argv_options = {}
          bad_args = []

          ARGV.each do |arg|
            case arg
            when '-h', '--help'
              print_help
              exit
            when '-v', '--version'
              print_version
              exit
            when '--link-to-sge'
              result = Lich.link_to_sge
              $stdout.puts(result ? 'Successfully linked to SGE.' : 'Failed to link to SGE.') if $stdout.isatty
              exit
            when '--unlink-from-sge'
              result = Lich.unlink_from_sge
              $stdout.puts(result ? 'Successfully unlinked from SGE.' : 'Failed to unlink from SGE.') if $stdout.isatty
              exit
            when '--link-to-sal'
              result = Lich.link_to_sal
              $stdout.puts(result ? 'Successfully linked to SAL files.' : 'Failed to link to SAL files.') if $stdout.isatty
              exit
            when '--unlink-from-sal'
              result = Lich.unlink_from_sal
              $stdout.puts(result ? 'Successfully unlinked from SAL files.' : 'Failed to unlink from SAL files.') if $stdout.isatty
              exit
            when '--install'
              if Lich.link_to_sge && Lich.link_to_sal
                $stdout.puts 'Install was successful.'
                Lich.log 'Install was successful.'
              else
                $stdout.puts 'Install failed.'
                Lich.log 'Install failed.'
              end
              exit
            when '--uninstall'
              if Lich.unlink_from_sge && Lich.unlink_from_sal
                $stdout.puts 'Uninstall was successful.'
                Lich.log 'Uninstall was successful.'
              else
                $stdout.puts 'Uninstall failed.'
                Lich.log 'Uninstall failed.'
              end
              exit
            when /^--start-scripts=(.+)$/i
              @argv_options[:start_scripts] = $1
            when /^--reconnect$/i
              @argv_options[:reconnect] = true
            when /^--reconnect-delay=(.+)$/i
              @argv_options[:reconnect_delay] = $1
            when /^--host=(.+):(.+)$/
              @argv_options[:host] = { domain: $1, port: $2.to_i }
            when /^--hosts-file=(.+)$/i
              @argv_options[:hosts_file] = $1
            when /^--no-gui$/i
              @argv_options[:gui] = false
            when /^--gui$/i
              @argv_options[:gui] = true
            when /^--game=(.+)$/i
              @argv_options[:game] = $1
            when /^--account=(.+)$/i
              @argv_options[:account] = $1
            when /^--password=(.+)$/i
              @argv_options[:password] = $1
            when /^--character=(.+)$/i
              @argv_options[:character] = $1
            when /^--frontend=(.+)$/i
              @argv_options[:frontend] = $1
            when /^--frontend-command=(.+)$/i
              @argv_options[:frontend_command] = $1
            when /^--save$/i
              @argv_options[:save] = true
            when /^--wine(?:\-prefix)?=.+$/i
              nil # already used when defining the Wine module
            when /\.sal$|Gse\.~xt$/i
              handle_sal_file(arg)
              bad_args.clear
            when /^--dark-mode=(true|false|on|off)$/i
              handle_dark_mode($1)
            else
              bad_args.push(arg)
            end
          end

          @argv_options
        end

        def self.handle_sal_file(arg)
          @argv_options[:sal] = arg
          unless File.exist?(@argv_options[:sal])
            @argv_options[:sal] = $1 if ARGV.join(' ') =~ /([A-Z]:\\.+?\.(?:sal|~xt))/i
          end
          unless File.exist?(@argv_options[:sal])
            @argv_options[:sal] = "#{Wine::PREFIX}/drive_c/#{@argv_options[:sal][3..-1].split('\\').join('/')}" if defined?(Wine)
          end
        end

        def self.handle_dark_mode(value)
          @argv_options[:dark_mode] = value =~ /^(true|on)$/i
          if defined?(Gtk)
            @theme_state = Lich.track_dark_mode = @argv_options[:dark_mode]
            Gtk::Settings.default.gtk_application_prefer_dark_theme = true if @theme_state == true
          end
        end

        def self.print_help
          puts 'Usage:  lich [OPTION]'
          puts ''
          puts 'Options are:'
          puts '  -h, --help            Display this list.'
          puts '  -V, --version         Display the program version number and credits.'
          puts ''
          puts '  -d, --directory       Set the main Lich program directory.'
          puts '      --script-dir      Set the directoy where Lich looks for scripts.'
          puts '      --data-dir        Set the directory where Lich will store script data.'
          puts '      --temp-dir        Set the directory where Lich will store temporary files.'
          puts ''
          puts '  -w, --wizard          Run in Wizard mode (default)'
          puts '  -s, --stormfront      Run in StormFront mode.'
          puts '      --avalon          Run in Avalon mode.'
          puts '      --frostbite       Run in Frostbite mode.'
          puts ''
          puts '      --dark-mode       Enable/disable darkmode without GUI. See example below.'
          puts ''
          puts '      --gemstone        Connect to the Gemstone IV Prime server (default).'
          puts '      --dragonrealms    Connect to the DragonRealms server.'
          puts '      --platinum        Connect to the Gemstone IV/DragonRealms Platinum server.'
          puts '      --test            Connect to the test instance of the selected game server.'
          puts '  -g, --game            Set the IP address and port of the game.  See example below.'
          puts ''
          puts '      --install         Edits the Windows/WINE registry so that Lich is started when logging in using the website or SGE.'
          puts '      --uninstall       Removes Lich from the registry.'
          puts ''
          puts 'The majority of Lich\'s built-in functionality was designed and implemented with Simutronics MUDs in mind (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a Simutronics game should be aware that if the description of a feature/option does not sound applicable and/or compatible with the current game, it should be assumed that the feature/option is not.  This particularly applies to in-script methods (commands) that depend heavily on the data received from the game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much "health" your character has left in a non-Simutronics game, and so the "health" script command will most likely return a value of 0).'
          puts ''
          puts 'The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare argument) depends on the data stream received from a given game, but on average results in a moderate improvement and it\'s recommended that Lich be run this way for any game that does not send "status information" in a format consistent with Simutronics\' GSL or XML encoding schemas.'
          puts ''
          puts ''
          puts 'Examples:'
          puts '  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)'
          puts '  lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')'
          puts '  lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)'
          puts '  lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')'
          puts '  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')'
          puts '  lich --login YourCharName --detachable-client=8000 --without-frontend --dark-mode=true'
          puts '       ... (run Lich and login without the GUI in a headless state while enabling dark mode for Lich spawned windows)'
          puts ''
        end

        def self.print_version
          puts "The Lich, version #{LICH_VERSION}"
          puts ' (an implementation of the Ruby interpreter by Yukihiro Matsumoto designed to be a \'script engine\' for text-based MUDs)'
          puts ''
          puts '- The Lich program and all material collectively referred to as "The Lich project" is copyright (C) 2005-2006 Murray Miron.'
          puts '- The Gemstone IV and DragonRealms games are copyright (C) Simutronics Corporation.'
          puts '- The Wizard front-end and the StormFront front-end are also copyrighted by the Simutronics Corporation.'
          puts '- Ruby is (C) Yukihiro \'Matz\' Matsumoto.'
          puts ''
          puts 'Thanks to all those who\'ve reported bugs and helped me track down problems on both Windows and Linux.'
        end
      end

      # Apply side effects: dark mode, hosts-dir, detachable-client
      module SideEffects
        def self.execute(argv_options)
          handle_hosts_dir(argv_options)
          handle_detachable_client
          handle_sal_launch(argv_options)
        end

        def self.handle_hosts_dir(argv_options)
          if (arg = ARGV.find { |a| a == '--hosts-dir' })
            i = ARGV.index(arg)
            ARGV.delete_at(i)
            hosts_dir = ARGV[i]
            ARGV.delete_at(i)
            if hosts_dir && File.exist?(hosts_dir)
              hosts_dir = hosts_dir.tr('\\', '/')
              hosts_dir += '/' unless hosts_dir[-1..-1] == '/'
              argv_options[:hosts_dir] = hosts_dir
            else
              $stdout.puts "warning: given hosts directory does not exist: #{hosts_dir}"
            end
          end
        end

        def self.handle_detachable_client
          @detachable_client_host = '127.0.0.1'
          @detachable_client_port = nil
          if (arg = ARGV.find { |a| a =~ /^\-\-detachable\-client=[0-9]+$/ })
            @detachable_client_port = /^\-\-detachable\-client=([0-9]+)$/.match(arg).captures.first
          elsif (arg = ARGV.find { |a| a =~ /^\-\-detachable\-client=((?:\d{1,3}\.){3}\d{1,3}):([0-9]{1,5})$/ })
            @detachable_client_host, @detachable_client_port = /^\-\-detachable\-client=((?:\d{1,3}\.){3}\d{1,3}):([0-9]{1,5})$/.match(arg).captures
          end
        end

        def self.handle_sal_launch(argv_options)
          return unless argv_options[:sal]

          unless File.exist?(argv_options[:sal])
            Lich.log "error: launch file does not exist: #{argv_options[:sal]}"
            Lich.msgbox "error: launch file does not exist: #{argv_options[:sal]}"
            exit
          end
          Lich.log "info: launch file: #{argv_options[:sal]}"

          if argv_options[:sal] =~ /SGE\.sal/i
            unless (launcher_cmd = Lich.get_simu_launcher)
              $stdout.puts 'error: failed to find the Simutronics launcher'
              Lich.log 'error: failed to find the Simutronics launcher'
              exit
            end
            launcher_cmd.sub!('%1', argv_options[:sal])
            Lich.log "info: launcher_cmd: #{launcher_cmd}"
            if defined?(Win32) && launcher_cmd =~ /^"(.*?)"\s*(.*)$/
              dir_file = $1
              param = $2
              dir = dir_file.slice(/^.*[\\\/]/)
              file = dir_file.sub(/^.*[\\\/]/, '')
              operation = (Win32.isXP? ? 'open' : 'runas')
              Win32.ShellExecute(lpOperation: operation, lpFile: file, lpDirectory: dir, lpParameters: param)
              Lich.log "error: Win32.ShellExecute returned #{r}; Win32.GetLastError: #{Win32.GetLastError}" if r < 33
            elsif defined?(Wine)
              system("#{Wine::BIN} #{launcher_cmd}")
            else
              system(launcher_cmd)
            end
            exit
          end
        end
      end

      # Handle game connection configuration
      module GameConnection
        def self.execute
          if (arg = ARGV.find { |a| a == '-g' || a == '--game' })
            handle_explicit_game_connection(arg)
          elsif ARGV.include?('--gemstone')
            handle_gemstone_connection
          elsif ARGV.include?('--shattered')
            handle_shattered_connection
          elsif ARGV.include?('--fallen')
            handle_fallen_connection
          elsif ARGV.include?('--dragonrealms')
            handle_dragonrealms_connection
          else
            @game_host = nil
            @game_port = nil
            Lich.log 'info: no force-mode info given'
          end
        end

        def self.handle_explicit_game_connection(arg)
          @game_host, @game_port = ARGV[ARGV.index(arg) + 1].split(':')
          @game_port = @game_port.to_i
          $frontend = determine_frontend
        end

        def self.handle_gemstone_connection
          if ARGV.include?('--platinum')
            $platinum = true
            if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
              @game_host = 'storm.gs4.game.play.net'
              @game_port = 10124
              $frontend = 'stormfront'
            else
              @game_host = 'gs-plat.simutronics.net'
              @game_port = 10121
              $frontend = ARGV.any? { |a| a == '--avalon' } ? 'avalon' : 'wizard'
            end
          else
            $platinum = false
            if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
              @game_host = 'storm.gs4.game.play.net'
              @game_port = 10024
              $frontend = 'stormfront'
            else
              @game_host = 'gs3.simutronics.net'
              @game_port = 4900
              $frontend = ARGV.any? { |a| a == '--avalon' } ? 'avalon' : 'wizard'
            end
          end
        end

        def self.handle_shattered_connection
          $platinum = false
          if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
            @game_host = 'storm.gs4.game.play.net'
            @game_port = 10324
            $frontend = 'stormfront'
          else
            @game_host = 'gs4.simutronics.net'
            @game_port = 10321
            $frontend = ARGV.any? { |a| a == '--avalon' } ? 'avalon' : 'wizard'
          end
        end

        def self.handle_fallen_connection
          $platinum = false
          if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
            $frontend = 'stormfront'
            $stdout.puts 'fixme'
            Lich.log 'fixme'
            exit
          elsif ARGV.grep(/--genie/).any?
            @game_host = 'dr.simutronics.net'
            @game_port = 11324
            $frontend = 'genie'
          else
            $stdout.puts 'fixme'
            Lich.log 'fixme'
            exit
          end
        end

        def self.handle_dragonrealms_connection
          if ARGV.include?('--platinum')
            $platinum = true
            if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
              $frontend = 'stormfront'
              $stdout.puts 'fixme'
              Lich.log 'fixme'
              exit
            elsif ARGV.grep(/--genie/).any?
              @game_host = 'dr.simutronics.net'
              @game_port = 11124
              $frontend = 'genie'
            elsif ARGV.grep(/--frostbite/).any?
              @game_host = 'dr.simutronics.net'
              @game_port = 11124
              $frontend = 'frostbite'
            else
              $frontend = 'wizard'
              $stdout.puts 'fixme'
              Lich.log 'fixme'
              exit
            end
          else
            $platinum = false
            if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
              $frontend = 'stormfront'
              $stdout.puts 'fixme'
              Lich.log 'fixme'
              exit
            elsif ARGV.grep(/--genie/).any?
              @game_host = 'dr.simutronics.net'
              @game_port = ARGV.include?('--test') ? 11624 : 11024
              $frontend = 'genie'
            else
              @game_host = 'dr.simutronics.net'
              @game_port = ARGV.include?('--test') ? 11624 : 11024
              $frontend = ARGV.any? { |a| a == '--avalon' } ? 'avalon' : ARGV.any? { |a| a == '--frostbite' } ? 'frostbite' : 'wizard'
            end
          end
        end

        def self.determine_frontend
          if ARGV.any? { |a| a == '-s' || a == '--stormfront' }
            'stormfront'
          elsif ARGV.any? { |a| a == '-w' || a == '--wizard' }
            'wizard'
          elsif ARGV.any? { |a| a == '--avalon' }
            'avalon'
          elsif ARGV.any? { |a| a == '--frostbite' }
            'frostbite'
          else
            'unknown'
          end
        end
      end

      # Main orchestrator: Step 1-4 of ARGV processing
      def self.process_argv
        # Step 1: Clean launcher.exe
        ARGV.delete_if { |arg| arg =~ /launcher\.exe/i }

        # Step 2: Handle early-exit CLI operations
        ArgvOptions::CliOperations.execute

        # Step 3: Parse normal options and build @argv_options
        @argv_options = ArgvOptions::OptionParser.execute

        # Step 4: Apply side effects and handle special cases
        ArgvOptions::SideEffects.execute(@argv_options)

        # Step 5: Handle game connection configuration
        ArgvOptions::GameConnection.execute

        @argv_options
      end
    end
  end
end

# Execute ARGV processing
Lich::Main::ArgvOptions.process_argv
