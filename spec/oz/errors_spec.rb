# frozen_string_literal: true

RSpec.describe 'Oz error hierarchy' do
  it 'maps status codes to specific error classes' do
    {
      400 => Oz::BadRequestError,
      401 => Oz::AuthenticationError,
      403 => Oz::PermissionDeniedError,
      404 => Oz::NotFoundError,
      409 => Oz::ConflictError,
      422 => Oz::UnprocessableEntityError,
      429 => Oz::RateLimitError,
      500 => Oz::InternalServerError,
      503 => Oz::InternalServerError
    }.each do |status, klass|
      expect(Oz.error_class_for(status)).to eq(klass)
    end
  end

  it 'falls back to APIStatusError for unmapped 4xx codes' do
    expect(Oz.error_class_for(418)).to eq(Oz::APIStatusError)
  end

  it 'builds APIError subclasses with rich metadata' do
    error = Oz::NotFoundError.new('missing', status_code: 404, body: { 'detail' => 'x' }, code: 'resource_not_found',
                                             request_id: 'req-1')
    expect(error.message).to eq('missing')
    expect(error.status_code).to eq(404)
    expect(error.code).to eq('resource_not_found')
    expect(error.request_id).to eq('req-1')
    expect(error.body).to eq('detail' => 'x')
  end

  it 'has a sensible inheritance chain' do
    expect(Oz::NotFoundError.ancestors).to include(Oz::APIStatusError, Oz::APIError, Oz::Error, StandardError)
    expect(Oz::APITimeoutError.ancestors).to include(Oz::APIConnectionError, Oz::APIError)
  end
end
