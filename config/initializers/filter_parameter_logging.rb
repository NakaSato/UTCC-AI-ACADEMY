# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# `student_id` is the second list's reason for existing: it is the credential a
# student signs in with, and `Parameters:` is logged at info — the level this app
# runs at in production — so every sign-in and sign-up was writing a real,
# confirmed 13-digit ID into log retention. The rest is the profile PII that
# /profile posts alongside it. The app publishes a PDPA notice at /privacy;
# keeping this out of the logs is part of meaning it.
#
# `:name` matches partially, so it also redacts keys like `section_name`. Nothing
# reads those back out of a log, so the over-reach is free.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :student_id, :name, :faculty, :study_year
]
