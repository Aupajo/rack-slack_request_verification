require 'rack/test'
require 'timecop'

RSpec.describe 'Middleware' do
  it 'ignores unmatched path patterns' do
    expect(post('/unmatched').status).to be 200
  end

  it 'returns a 401 when the request is missing headers' do
    expect { post('/slack/command') }.to output(
      /Slack verification failed: missing X-Slack-Signature, X-Slack-Request-Timestamp$/
    ).to_stdout

    expect(last_response.status).to be 401
  end

  it 'returns a 401 when the request is missing a signature header' do
    header 'X-Slack-Request-Timestamp', Time.now.to_i

    expect { post('/slack/command') }.to output(
      /Slack verification failed: missing X-Slack-Signature$/
    ).to_stdout

    expect(last_response.status).to be 401
  end

  it 'returns a 401 when the request is missing a timestamp header' do
    header 'X-Slack-Signature', 'abc123'

    expect { post('/slack/command') }.to output(
      /Slack verification failed: missing X-Slack-Request-Timestamp$/
    ).to_stdout

    expect(last_response.status).to be 401
  end

  it 'returns a 401 when the request is stale' do
    five_minutes_ago = Time.now.to_i - 5 * 60
    five_minutes_one_second_ago = five_minutes_ago - 1

    header 'X-Slack-Signature', 'abc123'
    header 'X-Slack-Request-Timestamp', five_minutes_one_second_ago

    expect { post('/slack/command') }.to output(
      /Slack verification failed: X-Slack-Request-Timestamp is #{five_minutes_one_second_ago}, only #{five_minutes_ago} or later is allowed$/
    ).to_stdout

    expect(last_response.status).to be 401
  end

  it 'returns a 401 when the signature cannot be verified' do
    header 'X-Slack-Signature', 'invalid'
    header 'X-Slack-Request-Timestamp', Time.now.to_i

    expect { post('/slack/command', 'some-content') }.to output(
      /Slack verification failed: X-Slack-Signature does not match the signature$/
    ).to_stdout
  end

  it 'allows a request to proceed when the signature can be verified' do
    Timecop.freeze("2019-01-01") do
      header 'X-Slack-Signature', 'v0=a41fc6d838afffee773c9ff9756a52611eeb57725fc3cddb5518ceecf8d77b57'
      header 'X-Slack-Request-Timestamp', Time.now.to_i

      post('/slack/command', 'some-content')
      expect(last_response.status).to be 200
      expect(last_response.body).to eq 'Echo: some-content'
    end
  end
end
