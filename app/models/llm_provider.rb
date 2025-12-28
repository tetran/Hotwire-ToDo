class LlmProvider < ApplicationRecord
  has_many :llm_models, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :api_key_encrypted, presence: true

  scope :active, -> { where(active: true) }

  def api_key
    decrypt_api_key
  end

  def api_key=(value)
    self.api_key_encrypted = value.present? ? encrypt_api_key(value) : nil
  end

  private

    def encrypt_api_key(value)
      crypt = ActiveSupport::MessageEncryptor.new(secret_key_base[0..31])
      crypt.encrypt_and_sign(value)
    end

    def decrypt_api_key
      return nil if api_key_encrypted.blank?

      crypt = ActiveSupport::MessageEncryptor.new(secret_key_base[0..31])
      crypt.decrypt_and_verify(api_key_encrypted)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def secret_key_base
      # In production, require proper credentials configuration
      if Rails.env.production?
        key = Rails.application.credentials.secret_key_base
        raise "Production requires credentials.secret_key_base to be configured" if key.nil?
        raise "secret_key_base must be at least 32 characters" if key.length < 32
        return key
      end

      # Non-production: try credentials first, then fallback
      key = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
      raise "secret_key_base is not configured" if key.nil?
      raise "secret_key_base must be at least 32 characters" if key.length < 32

      key
    end
end
