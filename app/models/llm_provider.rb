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
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.credentials.secret_key_base[0..31])
    crypt.encrypt_and_sign(value)
  end

  def decrypt_api_key
    return nil if api_key_encrypted.blank?
    crypt = ActiveSupport::MessageEncryptor.new(Rails.application.credentials.secret_key_base[0..31])
    crypt.decrypt_and_verify(api_key_encrypted)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
