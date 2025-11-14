# frozen_string_literal: true

require 'ffi'

module Lich
  module Common
    module GUI
      # Windows Credential Manager integration via FFI
      # REQUIRES: ffi gem (>= 1.15) must be available in Lich environment
      # Provides direct access to Windows Credential Manager API for secure credential storage
      # Supports generic credentials (passwords) and certificate credentials (SSH keys)
      #
      # Uses DPAPI (Data Protection API) via Credential Manager for encryption
      # No PowerShell subprocess calls - direct Win32 API access
      module WindowsCredentialManager
        extend FFI::Library

        # Load advapi32.dll and kernel32.dll for Credential Manager functions (Windows only)
        if OS.windows?
          ffi_lib 'advapi32', 'kernel32'
        end

        # CRED_TYPE values
        CRED_TYPE_GENERIC = 1
        CRED_TYPE_DOMAIN_PASSWORD = 2
        CRED_TYPE_DOMAIN_CERTIFICATE = 3
        CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4
        CRED_TYPE_GENERIC_CERTIFICATE = 5
        CRED_TYPE_DOMAIN_EXTENDED = 6

        # CRED_PERSIST values
        CRED_PERSIST_SESSION = 1
        CRED_PERSIST_LOCAL_MACHINE = 2
        CRED_PERSIST_ENTERPRISE = 3

        # Max credential size (512KB)
        CRED_MAX_CREDENTIAL_BLOB_SIZE = 512 * 1024

        # Credential structure for Win32 API
        class CredentialStruct < FFI::Struct
          layout(
            :flags, :uint32,
            :type, :uint32,
            :target_name, :pointer,
            :comment, :pointer,
            :last_written, :uint64,
            :credential_blob_size, :uint32,
            :credential_blob, :pointer,
            :persist, :uint32,
            :attribute_count, :uint32,
            :attributes, :pointer,
            :target_alias, :pointer,
            :user_name, :pointer
          )
        end

        # FFI function definitions (Windows only)
        if OS.windows?
          attach_function :CredReadW, [:pointer, :uint32, :uint32, :pointer], :bool
          attach_function :CredWriteW, [:pointer, :uint32], :bool
          attach_function :CredDeleteW, [:pointer, :uint32, :uint32], :bool
          attach_function :CredFree, [:pointer], :void
          attach_function :GetLastError, [], :uint32
        end

        class << self
          # Check if Credential Manager is available
          # @return [Boolean] true if Credential Manager is accessible
          def available?
            return false unless OS.windows?

            # Simple test: try to allocate credential structure
            begin
              FFI::MemoryPointer.new(CredentialStruct)
              true
            rescue
              false
            end
          end

          # Store a generic credential (password) in Credential Manager
          # @param target_name [String] Target/service name (e.g., 'lich5.master_password')
          # @param username [String] Username associated with credential
          # @param password [String] Password/secret to store
          # @param comment [String, nil] Optional comment/description
          # @param persist [Integer] Persistence level (1=session, 2=local_machine, 3=enterprise)
          # @return [Boolean] true if credential stored successfully
          def store_credential(target_name, username, password, comment = nil, persist = CRED_PERSIST_LOCAL_MACHINE)
            return false unless available?

            begin
              credential = CredentialStruct.new

              # Convert strings to wide characters (UTF-16LE)
              target_name_wide = string_to_wide(target_name)
              username_wide = string_to_wide(username)
              password_blob = password.bytes.pack('C*')
              comment_wide = comment ? string_to_wide(comment) : FFI::Pointer.new(:pointer, 0)

              # Allocate memory for credential blob (password data)
              blob_ptr = FFI::MemoryPointer.new(:byte, password_blob.size)
              blob_ptr.put_bytes(0, password_blob)

              # Fill credential structure
              credential[:flags] = 0
              credential[:type] = CRED_TYPE_GENERIC
              credential[:target_name] = target_name_wide
              credential[:comment] = comment_wide
              credential[:credential_blob_size] = password_blob.size
              credential[:credential_blob] = blob_ptr
              credential[:persist] = persist
              credential[:attribute_count] = 0
              credential[:attributes] = FFI::Pointer.new(:pointer, 0)
              credential[:user_name] = username_wide

              # Call CredWriteW
              cred_ptr = FFI::MemoryPointer.new(CredentialStruct)
              cred_ptr.put_struct(0, credential)

              result = CredWriteW(cred_ptr, 0)

              if result
                true
              else
                error_code = GetLastError
                Lich.log "error: CredWriteW failed with error code #{error_code}"
                false
              end
            rescue StandardError => e
              Lich.log "error: Failed to store credential: #{e.message}"
              false
            end
          end

          # Retrieve a generic credential from Credential Manager
          # @param target_name [String] Target/service name to retrieve
          # @return [String, nil] Retrieved password/secret, or nil if not found
          def retrieve_credential(target_name)
            return nil unless available?

            begin
              target_name_wide = string_to_wide(target_name)
              cred_ptr = FFI::MemoryPointer.new(:pointer)

              # Call CredReadW
              result = CredReadW(target_name_wide, CRED_TYPE_GENERIC, 0, cred_ptr)

              if result
                cred = cred_ptr.read_pointer
                credential = CredentialStruct.new(cred)

                # Extract password blob
                blob_ptr = credential[:credential_blob]
                blob_size = credential[:credential_blob_size]
                password_blob = blob_ptr.read_bytes(blob_size)
                password = password_blob.force_encoding('UTF-8')

                # Free credential structure
                CredFree(cred)

                password
              else
                error_code = GetLastError
                # ERROR_NOT_FOUND = 1168, so only log unexpected errors
                Lich.log "error: CredReadW failed with error code #{error_code}" unless error_code == 1168
                nil
              end
            rescue StandardError => e
              Lich.log "error: Failed to retrieve credential: #{e.message}"
              nil
            end
          end

          # Delete a credential from Credential Manager
          # @param target_name [String] Target/service name to delete
          # @return [Boolean] true if credential deleted successfully
          def delete_credential(target_name)
            return false unless available?

            begin
              target_name_wide = string_to_wide(target_name)

              # Call CredDeleteW
              result = CredDeleteW(target_name_wide, CRED_TYPE_GENERIC, 0)

              if result
                true
              else
                error_code = GetLastError
                Lich.log "error: CredDeleteW failed with error code #{error_code}"
                false
              end
            rescue StandardError => e
              Lich.log "error: Failed to delete credential: #{e.message}"
              false
            end
          end

          private

          # Convert Ruby string to UTF-16LE wide character string pointer
          # @param str [String] String to convert
          # @return [FFI::MemoryPointer] Pointer to wide character string
          def string_to_wide(str)
            wide_str = str.encode('UTF-16LE') + "\x00\x00"
            ptr = FFI::MemoryPointer.new(:byte, wide_str.bytesize)
            ptr.put_bytes(0, wide_str)
            ptr
          end

          # Convert UTF-16LE wide character pointer to Ruby string
          # @param ptr [FFI::Pointer] Pointer to wide character string
          # @return [String] Decoded Ruby string
          def wide_to_string(ptr)
            return nil if ptr.null?

            # Read until null terminator
            size = 0
            loop do
              byte1 = ptr.get_uint8(size)
              byte2 = ptr.get_uint8(size + 1)
              break if byte1 == 0 && byte2 == 0

              size += 2
            end

            wide_bytes = ptr.read_bytes(size)
            wide_bytes.force_encoding('UTF-16LE').encode('UTF-8')
          end
        end
      end
    end
  end
end
