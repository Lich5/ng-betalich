# frozen_string_literal: true

require 'login_spec_helper'
require_relative '../lib/common/gui/master_password_manager'

RSpec.describe Lich::Common::GUI::MasterPasswordManager do
  let(:master_password) { 'TestMaster@123' }
  let(:wrong_password) { 'WrongPassword' }

  describe '.keychain_available?' do
    it 'returns a boolean' do
      result = described_class.keychain_available?
      expect([true, false]).to include(result)
    end
  end

  describe '.create_validation_test' do
    let(:validation_test) { described_class.create_validation_test(master_password) }

    it 'returns a hash with required fields' do
      expect(validation_test).to be_a(Hash)
      expect(validation_test).to have_key('validation_salt')
      expect(validation_test).to have_key('validation_hash')
      expect(validation_test).to have_key('validation_version')
    end

    it 'has base64-encoded salt and hash' do
      expect(validation_test['validation_salt']).to match(/\A[A-Za-z0-9+\/]+=*\z/)
      expect(validation_test['validation_hash']).to match(/\A[A-Za-z0-9+\/]+=*\z/)
    end

    it 'has version 1' do
      expect(validation_test['validation_version']).to eq(1)
    end

    it 'produces different salts each call' do
      test1 = described_class.create_validation_test(master_password)
      test2 = described_class.create_validation_test(master_password)
      expect(test1['validation_salt']).not_to eq(test2['validation_salt'])
    end
  end

  describe '.validate_master_password' do
    let(:validation_test) { described_class.create_validation_test(master_password) }

    it 'returns true for correct password' do
      result = described_class.validate_master_password(master_password, validation_test)
      expect(result).to be true
    end

    it 'returns false for incorrect password' do
      result = described_class.validate_master_password(wrong_password, validation_test)
      expect(result).to be false
    end

    it 'returns false for empty password' do
      result = described_class.validate_master_password('', validation_test)
      expect(result).to be false
    end

    it 'returns false for nil validation_test' do
      result = described_class.validate_master_password(master_password, nil)
      expect(result).to be false
    end

    it 'returns false for invalid validation_test structure' do
      invalid_test = { 'validation_hash' => 'abc123' }
      result = described_class.validate_master_password(master_password, invalid_test)
      expect(result).to be false
    end

    it 'handles special characters' do
      special_pass = 'P@$$w0rd!#%^&*()'
      test = described_class.create_validation_test(special_pass)
      expect(described_class.validate_master_password(special_pass, test)).to be true
    end

    it 'handles unicode characters' do
      unicode_pass = 'мастер密码🔐'
      test = described_class.create_validation_test(unicode_pass)
      expect(described_class.validate_master_password(unicode_pass, test)).to be true
    end

    it 'handles very long passwords' do
      long_pass = 'a' * 1000
      test = described_class.create_validation_test(long_pass)
      expect(described_class.validate_master_password(long_pass, test)).to be true
    end
  end

  describe '.delete_master_password' do
    it 'returns a boolean' do
      result = described_class.delete_master_password
      expect([true, false]).to include(result)
    end
  end

  describe 'keychain integration' do
    it 'stores and retrieves password when available' do
      skip "Keychain not available" unless described_class.keychain_available?

      described_class.store_master_password(master_password)
      retrieved = described_class.retrieve_master_password
      expect(retrieved).to eq(master_password)

      described_class.delete_master_password
    end

    it 'handles keychain unavailability gracefully' do
      # Just verify methods don't crash
      described_class.store_master_password(master_password)
      described_class.retrieve_master_password
      described_class.delete_master_password
      expect(true).to be true
    end
  end
end
