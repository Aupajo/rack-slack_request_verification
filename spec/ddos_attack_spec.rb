RSpec.describe 'DDoS attack' do
  it 'kills large requests' do
    header 'X-Slack-Signature', 'abc123'
    header 'X-Slack-Request-Timestamp', Time.now.to_i

    one_mb_and_one_kb = 1024 ** 2 + 1
    large_request_body = 'A' * one_mb_and_one_kb

    expect { post("/slack/command", large_request_body) }.to output(
      /Slack verification failed: request exceeded limit of 1048576 bytes$/
    ).to_stdout

    expect(last_response.status).to be(413)
  end
end
