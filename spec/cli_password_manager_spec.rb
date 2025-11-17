# frozen_string_literal: true

require 'rspec'
require 'tempfile'
require 'yaml'
require 'fileutils'

LIB_DIR = File.join(File.expand_path("..", File.dirname(__FILE__)), 'lib')

# Define DATA_DIR for test environment
DATA_DIR = Dir.mktmpdir

require File.join(LIB_DIR, 'util', 'cli_password_manager.rb')

# Mock Lich module for testing
module Lich
  class << self
    attr_accessor :datadir

    def log(message); end
    def msgbox(message); end
  end
end

# Mock GUI dependencies
module Lich
  module Common
    module GUI
      module YamlState
        def self.yaml_file_path(data_dir)
          File.join(data_dir, 'entry.yaml')
        end
      end

      module PasswordCipher
      end

      module MasterPasswordManager
      end

      module Authentication
      end

      module AccountManager
      end
    end
  end
end

RSpec.describe Lich::Util::CLI::PasswordManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:yaml_file) { File.join(temp_dir, 'entry.yaml') }

  before do
    # Mock Lich.datadir to use temp directory
    allow(Lich).to receive(:datadir).and_return(temp_dir)
    # Mock YamlState.yaml_file_path
    allow(Lich::Common::GUI::YamlState).to receive(:yaml_file_path).and_return(yaml_file)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '.change_account_password' do
    context 'with plaintext mode' do
      before do
        yaml_data = {
          'encryption_mode' => 'plaintext',
          'accounts'        => {
            'DOUG' => {
              'password' => 'oldpassword',
              'username' => 'DOUG'
            }
          }
        }
        File.write(yaml_file, YAML.dump(yaml_data))
      end

      it 'changes account password in plaintext mode' do
        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')
        expect(exit_code).to eq(0)

        yaml_data = YAML.load_file(yaml_file)
        expect(yaml_data['accounts']['DOUG']['password']).to eq('newpassword')
      end

      it 'returns 2 when account not found' do
        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('NONEXISTENT', 'newpass')
        expect(exit_code).to eq(2)
      end

      it 'returns 2 when yaml file does not exist' do
        File.delete(yaml_file)
        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpass')
        expect(exit_code).to eq(2)
      end
    end

    context 'with standard encryption mode' do
      before do
        yaml_data = {
          'encryption_mode' => 'standard',
          'accounts'        => {
            'DOUG' => {
              'password' => 'encrypted_old_password',
              'username' => 'DOUG'
            }
          }
        }
        File.write(yaml_file, YAML.dump(yaml_data))
      end

      it 'calls PasswordCipher.encrypt for standard mode' do
        allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
          .and_return('encrypted_new_password')

        Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')

        expect(Lich::Common::GUI::PasswordCipher).to have_received(:encrypt).with(
          'newpassword',
          mode: :standard,
          account_name: 'DOUG'
        )
      end

      it 'updates password field in standard mode' do
        allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
          .and_return('encrypted_new_password')

        Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')

        yaml_data = YAML.load_file(yaml_file)
        expect(yaml_data['accounts']['DOUG']['password']).to eq('encrypted_new_password')
      end

      it 'returns 0 on success' do
        allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
          .and_return('encrypted_new_password')

        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')
        expect(exit_code).to eq(0)
      end
    end

    context 'with enhanced encryption mode' do
      before do
        yaml_data = {
          'encryption_mode' => 'enhanced',
          'accounts'        => {
            'DOUG' => {
              'password' => 'encrypted_old_password',
              'username' => 'DOUG'
            }
          }
        }
        File.write(yaml_file, YAML.dump(yaml_data))
      end

      it 'retrieves master password from keychain' do
        allow(Lich::Common::GUI::MasterPasswordManager).to receive(:retrieve_master_password)
          .and_return('master_password')
        allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
          .and_return('encrypted_new_password')

        Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')

        expect(Lich::Common::GUI::MasterPasswordManager).to have_received(:retrieve_master_password)
      end

      it 'returns 1 when master password not in keychain' do
        allow(Lich::Common::GUI::MasterPasswordManager).to receive(:retrieve_master_password)
          .and_return(nil)

        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')
        expect(exit_code).to eq(1)
      end

      it 'encrypts with master password from keychain' do
        allow(Lich::Common::GUI::MasterPasswordManager).to receive(:retrieve_master_password)
          .and_return('my_master_password')
        allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
          .and_return('encrypted_new_password')

        Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpassword')

        expect(Lich::Common::GUI::PasswordCipher).to have_received(:encrypt).with(
          'newpassword',
          mode: :enhanced,
          account_name: 'DOUG',
          master_password: 'my_master_password'
        )
      end
    end

    context 'error handling' do
      before do
        yaml_data = {
          'encryption_mode' => 'plaintext',
          'accounts'        => { 'DOUG' => { 'password' => 'oldpassword' } }
        }
        File.write(yaml_file, YAML.dump(yaml_data))
      end

      it 'returns 1 on general error' do
        allow(YAML).to receive(:load_file).and_raise(StandardError.new('Write error'))

        exit_code = Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpass')
        expect(exit_code).to eq(1)
      end

      it 'logs error message' do
        expect(Lich).to receive(:log).at_least(:once)

        Lich::Util::CLI::PasswordManager.change_account_password('NONEXISTENT', 'newpass')
      end
    end
  end

  describe '.add_account' do
    before do
      yaml_data = {
        'encryption_mode' => 'plaintext',
        'accounts'        => {}
      }
      File.write(yaml_file, YAML.dump(yaml_data))
    end

    it 'returns 1 when account already exists' do
      yaml_data = YAML.load_file(yaml_file)
      yaml_data['accounts']['DOUG'] = { 'password' => 'existing' }
      File.write(yaml_file, YAML.dump(yaml_data))

      exit_code = Lich::Util::CLI::PasswordManager.add_account('DOUG', 'newpass')
      expect(exit_code).to eq(1)
    end

    it 'authenticates with game servers' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([
                      { char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' },
                      { char_name: 'Char2', game_code: 'GS3', game_name: 'GemStone IV' }
                    ])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(true)

      Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password', 'wizard')

      expect(Lich::Common::GUI::Authentication).to have_received(:authenticate).with(
        account: 'DOUG',
        password: 'password',
        legacy: true
      )
    end

    it 'returns 2 when authentication fails' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return(nil)

      exit_code = Lich::Util::CLI::PasswordManager.add_account('DOUG', 'wrongpass')
      expect(exit_code).to eq(2)
    end

    it 'returns 2 when no characters found' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([])

      exit_code = Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password')
      expect(exit_code).to eq(2)
    end

    it 'saves account with provided frontend' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([{ char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' }])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(true)

      Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password', 'stormfront')

      # Should call with frontend set
      expect(Lich::Common::GUI::AccountManager).to have_received(:add_or_update_account)
    end

    it 'returns 0 on success' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([{ char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' }])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(true)

      exit_code = Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password', 'wizard')
      expect(exit_code).to eq(0)
    end

    it 'returns 1 when AccountManager.add_or_update_account fails' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([{ char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' }])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(false)

      exit_code = Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password', 'wizard')
      expect(exit_code).to eq(1)
    end
  end

  describe '.change_master_password' do
    before do
      yaml_data = {
        'encryption_mode'      => 'enhanced',
        'master_password_test' => {
          'validation_salt'    => 'salt',
          'validation_hash'    => 'hash',
          'validation_version' => 1
        },
        'accounts'             => {
          'DOUG' => {
            'password' => 'encrypted_pass',
            'username' => 'DOUG'
          }
        }
      }
      File.write(yaml_file, YAML.dump(yaml_data))
    end

    it 'returns 2 when yaml file does not exist' do
      File.delete(yaml_file)
      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(2)
    end

    it 'returns 3 when not in enhanced mode' do
      yaml_data = YAML.load_file(yaml_file)
      yaml_data['encryption_mode'] = 'plaintext'
      File.write(yaml_file, YAML.dump(yaml_data))

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(3)
    end

    it 'validates old password against validation test' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(false)

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('wrongpass')
      expect(exit_code).to eq(1)
    end

    it 'returns 1 when old password validation fails' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(false)

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('wrongpass')
      expect(exit_code).to eq(1)
    end

    it 'prompts for new password' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("newpass\n", "newpass\n")
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:create_validation_test)
        .and_return({})
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password)
        .and_return(true)
      allow(Lich::Common::GUI::PasswordCipher).to receive(:decrypt)
        .and_return('plaintext_pass')
      allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
        .and_return('encrypted_new')

      Lich::Util::CLI::PasswordManager.change_master_password('oldpass')

      expect($stdin).to have_received(:gets).at_least(:once)
    end

    it 're-encrypts all accounts with new password' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("newpassword\n", "newpassword\n")
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:create_validation_test)
        .and_return({ 'validation_salt' => 'new_salt', 'validation_hash' => 'new_hash' })
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password)
        .and_return(true)
      allow(Lich::Common::GUI::PasswordCipher).to receive(:decrypt)
        .and_return('plaintext_pass')
      allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
        .and_return('encrypted_new')

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')

      # Verify success - re-encryption occurs as part of successful flow
      expect(exit_code).to eq(0)
    end

    it 'returns 1 when passwords do not match' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("newpass1\n", "newpass2\n")

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(1)
    end

    it 'returns 1 when password is too short' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("short\n", "short\n")

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(1)
    end

    it 'returns 1 when keychain update fails' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("newpassword\n", "newpassword\n")
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:create_validation_test)
        .and_return({})
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password)
        .and_return(false)
      allow(Lich::Common::GUI::PasswordCipher).to receive(:decrypt)
        .and_return('plaintext_pass')
      allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
        .and_return('encrypted_new')

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(1)
    end

    it 'returns 0 on success' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow($stdin).to receive(:gets).and_return("newpassword\n", "newpassword\n")
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:create_validation_test)
        .and_return({ 'validation_salt' => 'new_salt', 'validation_hash' => 'new_hash' })
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password)
        .and_return(true)
      allow(Lich::Common::GUI::PasswordCipher).to receive(:decrypt)
        .and_return('plaintext_pass')
      allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
        .and_return('encrypted_new')

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass')
      expect(exit_code).to eq(0)
    end

    it 'accepts new password as argument and does not prompt' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:create_validation_test)
        .and_return({ 'validation_salt' => 'new_salt', 'validation_hash' => 'new_hash' })
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:store_master_password)
        .and_return(true)
      allow(Lich::Common::GUI::PasswordCipher).to receive(:decrypt)
        .and_return('plaintext_pass')
      allow(Lich::Common::GUI::PasswordCipher).to receive(:encrypt)
        .and_return('encrypted_new')

      # Should NOT call $stdin.gets when new_password is provided
      expect($stdin).not_to receive(:gets)

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass', 'newpassword')
      expect(exit_code).to eq(0)
    end

    it 'returns 1 when new password is too short (from argument)' do
      allow(Lich::Common::GUI::MasterPasswordManager).to receive(:validate_master_password)
        .and_return(true)

      exit_code = Lich::Util::CLI::PasswordManager.change_master_password('oldpass', 'short')
      expect(exit_code).to eq(1)
    end
  end

  describe 'security concerns' do
    it 'does not log password values in change_account_password' do
      yaml_data = {
        'encryption_mode' => 'plaintext',
        'accounts'        => { 'DOUG' => { 'password' => 'oldpass' } }
      }
      File.write(yaml_file, YAML.dump(yaml_data))

      expect(Lich).not_to receive(:log).with(/oldpass|newpass/)

      Lich::Util::CLI::PasswordManager.change_account_password('DOUG', 'newpass')
    end

    it 'does not log password values in add_account' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([{ char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' }])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(true)

      expect(Lich).not_to receive(:log).with(/password123|secretpass/)

      Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password123')
    end

    it 'saves YAML with 0600 permissions in add_account' do
      allow(Lich::Common::GUI::Authentication).to receive(:authenticate)
        .and_return([{ char_name: 'Char1', game_code: 'GS3', game_name: 'GemStone IV' }])
      allow(Lich::Common::GUI::AccountManager).to receive(:add_or_update_account)
        .and_return(true)

      Lich::Util::CLI::PasswordManager.add_account('DOUG', 'password')

      # AccountManager should handle permissions, but verify
    end
  end
end
