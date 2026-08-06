module RecoveryTestHelpers
  def valid_manifest(captured_at: Time.current.iso8601)
    {
      backup_id: "synthetic-backup-001",
      captured_at:,
      database: { included: true, integrity: "verified" },
      storage: { included: true, integrity: "verified" },
      encryption: { at_rest: true, key_owner: "recovery-owner" }
    }
  end

  def isolated_target
    {
      production_writes_disabled: true,
      outbound_mail_disabled: true,
      notifications_disabled: true,
      websocket_target: "isolated",
      credentials_scope: "non-production",
      source_immutable: true
    }
  end

  def valid_database
    {
      foreign_keys_valid: true,
      schema_compatible: true,
      row_counts_verified: true
    }
  end

  def valid_storage
    {
      blob_references_valid: true,
      checksums_verified: true
    }
  end

  def capture_signal(event)
    received = []
    subscription = ActiveSupport::Notifications.subscribe("observability.#{event}") do |*, payload|
      received << payload
    end
    yield
    received.sole
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end
end
