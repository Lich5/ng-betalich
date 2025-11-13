# frozen_string_literal: true

require 'rspec'
require_relative 'login_spec_helper'
require_relative '../lib/common/gui/master_password_manager'

RSpec.describe Lich::Common::GUI::MasterPasswordManager do
  describe '.windows_keychain_available?' do
    context 'when cmdkey is available on Windows' do
      it 'returns true' do
        allow_any_instance_of(Object).to receive(:system).with('where cmdkey >nul 2>&1').and_return(true)
        result = described_class.send(:windows_keychain_available?)
        expect(result).to be true
      end
    end

    context 'when cmdkey is not available' do
      it 'returns false' do
        allow_any_instance_of(Object).to receive(:system).with('where cmdkey >nul 2>&1').and_return(false)
        result = described_class.send(:windows_keychain_available?)
        expect(result).to be false
      end
    end

    context 'on non-Windows systems' do
      it 'returns false' do
        allow_any_instance_of(Object).to receive(:system).with('where cmdkey >nul 2>&1').and_return(nil)
        result = described_class.send(:windows_keychain_available?)
        expect(result).to be_falsy
      end
    end
  end

  describe '.store_windows_keychain' do
    context 'when storing password' do
      it 'returns false - Windows credential manager not fully implemented' do
        allow(Lich).to receive(:log)
        result = described_class.send(:store_windows_keychain, 'test_password')
        expect(result).to be false
      end
    end

    context 'when logging warning' do
      it 'logs warning message' do
        expect(Lich).to receive(:log).with('warning: Master password storage not fully implemented for Windows')
        described_class.send(:store_windows_keychain, 'test_password')
      end
    end

    context 'with various password formats' do
      it 'handles simple passwords' do
        allow(Lich).to receive(:log)
        result = described_class.send(:store_windows_keychain, 'simple_password')
        expect(result).to be false
      end

      it 'handles complex passwords with special characters' do
        allow(Lich).to receive(:log)
        result = described_class.send(:store_windows_keychain, 'P@ssw0rd!#$%')
        expect(result).to be false
      end

      it 'handles unicode passwords' do
        allow(Lich).to receive(:log)
        result = described_class.send(:store_windows_keychain, 'Пароль123!')
        expect(result).to be false
      end
    end
  end

  describe '.retrieve_windows_keychain' do
    context 'when retrieving password' do
      it 'returns nil - not implemented' do
        result = described_class.send(:retrieve_windows_keychain)
        expect(result).to be_nil
      end
    end

    context 'when keychain is unavailable' do
      it 'returns nil' do
        result = described_class.send(:retrieve_windows_keychain)
        expect(result).to be_nil
      end
    end

    context 'when password not found' do
      it 'returns nil' do
        result = described_class.send(:retrieve_windows_keychain)
        expect(result).to be_nil
      end
    end
  end

  describe '.delete_windows_keychain' do
    context 'when deleting stored password' do
      it 'calls system command to delete credential' do
        service_name = described_class::KEYCHAIN_SERVICE
        expect_any_instance_of(Object).to receive(:system).with("cmdkey /delete:#{service_name} >nul 2>&1")
        described_class.send(:delete_windows_keychain)
      end
    end

    context 'when credential does not exist' do
      it 'handles gracefully' do
        allow_any_instance_of(Object).to receive(:system).and_return(nil)
        expect { described_class.send(:delete_windows_keychain) }.not_to raise_error
      end
    end

    context 'when permission denied' do
      it 'handles system error gracefully' do
        allow_any_instance_of(Object).to receive(:system).and_return(false)
        result = described_class.send(:delete_windows_keychain)
        expect(result).to be_falsy
      end
    end

    context 'when vault is locked' do
      it 'handles locked vault gracefully' do
        # System call returns false when vault is locked
        allow_any_instance_of(Object).to receive(:system).and_return(false)
        result = described_class.send(:delete_windows_keychain)
        expect(result).to be_falsy
      end
    end
  end

  describe 'Windows-specific integration' do
    context 'full lifecycle' do
      it 'checks availability, stores, and deletes' do
        allow_any_instance_of(Object).to receive(:system).and_return(true)
        allow(Lich).to receive(:log)

        # Check availability
        availability = described_class.send(:windows_keychain_available?)
        expect(availability).to be true

        # Try to store
        store_result = described_class.send(:store_windows_keychain, 'test_password')
        expect(store_result).to be false

        # Delete credential
        expect { described_class.send(:delete_windows_keychain) }.not_to raise_error
      end
    end
  end

  describe 'Fallback behavior' do
    context 'when Windows keychain unavailable on Windows system' do
      it 'gracefully falls back' do
        allow_any_instance_of(Object).to receive(:system).and_return(false)
        result = described_class.send(:windows_keychain_available?)
        expect(result).to be false
      end
    end

    context 'on non-Windows platforms' do
      it 'correctly identifies unavailability' do
        allow_any_instance_of(Object).to receive(:system).and_return(nil)
        result = described_class.send(:windows_keychain_available?)
        expect(result).to be_falsy
      end
    end
  end
end
