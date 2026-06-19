# frozen_string_literal: true

module Oz
  # Base class for every error raised by the SDK.
  class Error < StandardError; end

  # Base class for all errors that originate from interacting with the API.
  #
  # Carries the HTTP status code, the (parsed) response body, a machine readable
  # error +code+ when the API provides one, and the +request_id+ header so that
  # failures can be correlated with server side logs.
  class APIError < Error
    attr_reader :status_code, :body, :code, :request_id, :response

    def initialize(message = nil, status_code: nil, body: nil, code: nil, request_id: nil, response: nil)
      super(message)
      @status_code = status_code
      @body = body
      @code = code
      @request_id = request_id
      @response = response
    end
  end

  # Raised when the request could not reach the API at all (DNS failure,
  # connection refused, TLS error, ...).
  class APIConnectionError < APIError; end

  # Raised when a request exceeds the configured timeout.
  class APITimeoutError < APIConnectionError; end

  # Raised for any non-2xx response that is not mapped to a more specific
  # subclass below.
  class APIStatusError < APIError; end

  # 400
  class BadRequestError < APIStatusError; end
  # 401 (also raised locally when no API key is configured)
  class AuthenticationError < APIStatusError; end
  # 403
  class PermissionDeniedError < APIStatusError; end
  # 404
  class NotFoundError < APIStatusError; end
  # 409
  class ConflictError < APIStatusError; end
  # 422
  class UnprocessableEntityError < APIStatusError; end
  # 429
  class RateLimitError < APIStatusError; end
  # 5xx
  class InternalServerError < APIStatusError; end

  # Maps an HTTP status code to the most specific error class.
  STATUS_ERROR_CLASSES = {
    400 => BadRequestError,
    401 => AuthenticationError,
    403 => PermissionDeniedError,
    404 => NotFoundError,
    409 => ConflictError,
    422 => UnprocessableEntityError,
    429 => RateLimitError
  }.freeze

  # Returns the error class that should be raised for +status+.
  def self.error_class_for(status)
    STATUS_ERROR_CLASSES[status] || (status >= 500 ? InternalServerError : APIStatusError)
  end
end
